import 'package:flutter/material.dart';
import 'home_page.dart';
import 'onboardingone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For pill icon
import 'package:adapty_flutter/adapty_flutter.dart'; // Adapty for paywall

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
    print(
        'User tapped on notification with payload: ${notificationResponse.payload}');
  }
}

// iOS-specific local notification handler
Future onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  print('iOS notification received: $title - $body - $payload');
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

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final adapty = Adapty();
  bool? hasLifetimeAccess;

  @override
  void initState() {
    super.initState();
    _checkUserAccess();
  }

  Future<void> _checkUserAccess() async {
    try {
      print("Fetching Adapty profile...");
      final profile = await adapty.getProfile();
      print("Profile fetched: $profile");

      setState(() {
        hasLifetimeAccess = profile?.accessLevels['premium']?.isActive ?? false;
      });
    } catch (e) {
      print("An error occurred while fetching user access: $e");
      setState(() {
        hasLifetimeAccess = false; // Assume no access on error
      });
    }
  }

  void _navigateBasedOnAccess() {
    if (hasLifetimeAccess == null) {
      return; // Still checking access, don't navigate yet
    }

    if (hasLifetimeAccess!) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage()), // HomePage for premium access
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => OnboardingOne()), // Onboarding for paywall
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Reminder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.pills,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Medicine Reminder!',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _navigateBasedOnAccess,
              child: const Text(
                'Start',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
