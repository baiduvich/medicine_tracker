import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For pill icon

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  // Initialize the notification plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  // Initialize timezones
  tz.initializeTimeZones();
  print('Timezones initialized');

  runApp(const MedicineReminderApp());
}

// Handle notification responses (when user taps on a notification)
void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) {
  print("Notification tapped with payload: ${notificationResponse.payload}");
  if (notificationResponse.payload != null) {
    // Define behavior when user taps on the notification
    print(
        'User tapped on notification with payload: ${notificationResponse.payload}');
  }
}

// iOS-specific local notification handler
Future onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  print('iOS notification received: $title - $body - $payload');
  // Define behavior when a notification is received in iOS (optional)
}

class MedicineReminderApp extends StatelessWidget {
  const MedicineReminderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Reminder',
      theme: ThemeData(
        primaryColor: Colors.white, // Set primary color to white for text
        scaffoldBackgroundColor: Colors.red[900], // Dark red background
        brightness: Brightness.dark, // Ensure everything follows dark theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[900], // Dark red app bar
          foregroundColor: Colors.white, // White text in the app bar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.red[900], // Text color on buttons
            backgroundColor: Colors.white, // Button background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded buttons
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white), // White body text
          bodyMedium: TextStyle(color: Colors.white), // White body text
        ),
      ),
      home: const StartPage(),
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Reminder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              // Pill icon from FontAwesome
              FontAwesomeIcons.pills,
              size: 80, // Icon size
              color: Colors.white, // Icon color
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Medicine Reminder!',
              style: TextStyle(
                fontSize: 24, // A little larger text size
                color: Colors.white,
                fontWeight: FontWeight.bold, // Bold text
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: const Text(
                'Start',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Make text bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
