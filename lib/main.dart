import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/notification_handler.dart';
import 'screens/landing_page.dart';
import 'screens/qr_scanner_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize Firebase and notifications in background
    await Firebase.initializeApp();
    await NotificationHandler.requestPermissions();
    await NotificationHandler.setupLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationHandler.showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationHandler.showNotificationModal(
        message.notification?.body ?? 'You tapped a notification.',
      );
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        NotificationHandler.showNotificationModal(
            message.notification?.body ?? 'Notification tapped');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COPA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LandingPage(),
      navigatorKey: NotificationHandler.navigatorKey,
      routes: {
        '/scan': (context) => const QRScannerScreen(),
      },
    );
  }
}
