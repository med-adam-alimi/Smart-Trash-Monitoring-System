# Smart Trash Management System

## Description

This project develops an intelligent mobile waste management application integrated with a smart trash can system based on ESP32, ultrasonic sensors, and MQTT communication. The goal is to promote recycling by providing real-time notifications when bins are full and to track the filling history.

The mobile application (developed with Flutter) allows users to:
* Receive notifications about the bin status.
* View filling and recycling history.
* Visualize the current fill level.

The smart trash can system (based on ESP32):
* Uses ultrasonic sensors to detect the fill level of trash can compartments.
* Sends level data via MQTT to a central broker.
* Triggers notifications to the mobile application via Firebase Cloud Messaging (FCM).

## Features

* **Fill Level Monitoring:** Real-time display of the fill level for each trash bin compartment (e.g., for plastic, paper, glass, etc.).
* **Smart Notifications:** Receive push alerts on your phone when the trash bin reaches a certain fill threshold, prompting you to recycle.
* **Fill History:** Access a detailed history of fill levels and recycling events over time.
* **User Authentication:** Secure user login via Firebase Authentication.
* **Real-time Data Management:** Synchronization of data between the ESP32 device, MQTT broker, Firebase Firestore, and the mobile application.

## Technologies Used

### Mobile Application (Flutter)
* **Flutter SDK:** Cross-platform application development framework.
* **Firebase:**
    * **Firebase Authentication:** For user management (signup, login).
    * **Firebase Firestore:** Real-time NoSQL database to store history and bin status.
    * **Firebase Cloud Messaging (FCM):** For sending push notifications to users.
* **`mqtt_client`:** Flutter library for communication with the MQTT broker (if the app directly listens to MQTT topics).

### Embedded System (ESP32)
* **ESP32:** Wi-Fi and Bluetooth microcontroller for connectivity and sensor processing.
* **Arduino IDE / PlatformIO:** Development environment for ESP32 code.
* **Ultrasonic Sensors (HC-SR04 or similar):** For measuring distance and determining the fill level.
* **PubSubClient (MQTT Client Library):** For MQTT communication on ESP32.

### Backend / Cloud
* **MQTT Broker:** An operational MQTT server (e.g., Mosquitto, HiveMQ, or a hosted broker) to route messages between the ESP32 and the application/Firebase.
* **Firebase Functions (Optional but Recommended):** To listen for Firestore changes or MQTT messages (via a gateway) and trigger FCM notifications.

## Project Architecture

The system consists of several layers that communicate with each other:

1.  **ESP32 (Device Layer):**
    * Collects data from ultrasonic sensors.
    * Publishes fill level (and compartment identification) to a specific MQTT topic (e.g., `/smarttrash/binX/level`).

2.  **MQTT Broker (Messaging Layer):**
    * Receives messages from the ESP32.
    * Relays messages to subscribed clients.

3.  **Firebase (Cloud Layer):**
    * **Firebase Functions:** Subscribes to MQTT topics (via an MQTT-Firebase bridge or a function that listens to a webhook from an MQTT service). When a new level is received, the function updates Firestore and/or sends an FCM notification.
    * **Firestore:** Stores fill level data and history.
    * **FCM:** Sends push notifications to the mobile application.

4.  **Flutter Mobile Application (Presentation Layer):**
    * Authenticates with Firebase.
    * Subscribes to data changes in Firestore for real-time display.
    * Receives and displays FCM notifications.
    * Interacts with the user interface.


+----------------+      +----------------+      +------------------+      +-----------------------+
|  ESP32 Device  |----->|  MQTT Broker   |----->|  Firebase Cloud  |----->|  Flutter Mobile App   |
| (Ultrasonic    |      | (e.g., Mosquitto)|      | (Functions, Firestore, |      | (Real-time data,      |
|  Sensors)      |      |                |      |  FCM)            |      |  Notifications, History)|
+----------------+      +----------------+      +------------------+      +-----------------------+
|   ^
|   | (Data via MQTT)
v   |
(Updates)


## Setup and Installation

Follow the steps below to set up and run the project locally.

### 1. Prerequisites

* **For Mobile Application:**
    * Flutter SDK installed ([Flutter Installation](https://flutter.dev/docs/get-started/install)).
    * A code editor (VS Code recommended with Flutter extension).
    * An Android/iOS emulator or physical device.
* **For ESP32:**
    * Arduino IDE or PlatformIO installed.
    * ESP32 board libraries (boards manager).
    * `PubSubClient` library for Arduino.
* **For Firebase:**
    * A Firebase account.
    * A Firebase project configured for your application.
    * `firebase_cli` installed and configured.
* **For MQTT:**
    * An operational MQTT broker (local or cloud).

### 2. Firebase Configuration

1.  Create a new Firebase project on the [Firebase console](https://console.firebase.google.com/).
2.  Add an Android and/or iOS app to your Firebase project and follow the instructions to download the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files. Place them in the `android/app` and `ios/Runner` directories respectively.
3.  Enable **Authentication** (email/password at minimum) and **Firestore Database** in your Firebase project.
4.  Configure Firestore security rules to allow read/write (for development, you can start with open rules, then restrict them).
5.  If you are using Firebase Functions, set up your environment and deploy your functions.

### 3. ESP32 Code Configuration

1.  Open the `esp32_code` (or similar name) folder in your IDE (Arduino IDE/PlatformIO).
2.  Update the Wi-Fi credentials and MQTT broker details in the code:
    ```cpp
    // Example in your .ino or .cpp code
    const char* ssid = "YOUR_WIFI_SSID";
    const char* password = "YOUR_WIFI_PASSWORD";
    const char* mqtt_server = "MQTT_BROKER_IP_ADDRESS_OR_DOMAIN_NAME";
    const int mqtt_port = 1883; // Or SSL port if used
    const char* mqtt_topic_publish = "/smarttrash/bin1/level";
    const char* mqtt_client_id = "ESP32_SmartBin1";
    ```
3.  Upload the code to your ESP32 board.

### 4. Flutter Application Configuration

1.  Clone this repository:
    ```bash
    git clone [https://github.com/your_username/smart-trash-app.git](https://github.com/your_username/smart-trash-app.git)
    cd smart-trash-app
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the application:
    ```bash
    flutter run
    ```

## Usage

1.  **Sign Up/Login:** Launch the app and create an account or log in with your Firebase credentials.
2.  **Bin Configuration:** (If applicable) The app should automatically fetch bin data via Firestore once the ESP32 starts publishing data.
3.  **Receive Notifications:** Ensure notifications are enabled on your device to receive fill alerts.
4.  **View History:** Navigate to the History section in the app to see fill trends.

## Contributing

Contributions are welcome! If you'd like to improve this project, please:

1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/new-feature`).
3.  Commit your changes (`git commit -m 'Add new feature'`).
4.  Push to the branch (`git push origin feature/new-feature`).
5.  Open a Pull Request.

## Contact

For any questions or suggestions, feel free to reach out to me:

* **Your Name/Handle:** Alimi Mohamed Adam
* **Email:** mohamed.adam.alimi@gmail.com
* **LinkedIn :** (https://www.linkedin.com/in/mohamed-adam-alimi-99ba02284/)
* **GitHub:** (https://github.com/med-adam-alimi)

