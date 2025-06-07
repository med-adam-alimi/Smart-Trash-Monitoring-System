import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TrashMonitorApp());
}

class TrashMonitorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trash Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return DashboardScreen();
          }
          return LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signIn,
              child: Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  MqttClient? client;
  double currentDistance = 0.0;
  double maxTrashHeight = 50.0; // Adjust based on your trash bin height

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _initMqtt();
    _listenToFirestore();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'trash_channel',
      'Trash Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _initMqtt() async {
    client = MqttClient('mqtt.eclipse.org', 'flutter_client');
    client?.port = 1883;
    client?.keepAlivePeriod = 30;
    client?.onDisconnected = _onDisconnected;
    client?.onConnected = _onConnected;
    client?.onSubscribed = _onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean();
    client?.connectionMessage = connMess;

    try {
      await client?.connect();
    } catch (e) {
      print('Exception: $e');
      client?.disconnect();
    }

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT connected');
      client?.subscribe('trashmonitor/distance', MqttQos.atMostOnce);
      client?.updates?.listen(_onMessage);
    } else {
      print('ERROR: MQTT connection failed');
    }
  }

  void _onConnected() {
    print('Connected to MQTT');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void _onDisconnected() {
    print('Disconnected from MQTT');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    print('MQTT message received: $pt');

    setState(() {
      currentDistance = double.tryParse(pt) ?? 0.0;
    });

    // Check if trash is full (adjust threshold as needed)
    if (currentDistance < maxTrashHeight * 0.2) { // 20% space left
      _showNotification('Trash Alert', 'Your trash bin is almost full!');
      
      // Also update Firestore
      FirebaseFirestore.instance.collection('trash_status').doc('current').set({
        'distance': currentDistance,
        'isFull': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _listenToFirestore() {
    FirebaseFirestore.instance
        .collection('trash_status')
        .doc('current')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          currentDistance = snapshot.data()?['distance'] ?? 0.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fillPercentage = ((maxTrashHeight - currentDistance) / maxTrashHeight * 100).clamp(0.0, 100.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Trash Monitor'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Trash Level',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: (100 - fillPercentage).toInt(),
                        child: Container(color: Colors.transparent),
                      ),
                      Expanded(
                        flex: fillPercentage.toInt(),
                        child: Container(
                          color: fillPercentage > 80 
                              ? Colors.red 
                              : fillPercentage > 50 
                                  ? Colors.orange 
                                  : Colors.green,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${fillPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Distance: ${currentDistance.toStringAsFixed(1)} cm',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
  }
}
