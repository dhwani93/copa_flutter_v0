import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/notification_handler.dart';
import 'screens/landing_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COPA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LandingPage(),
      navigatorKey: NotificationHandler.navigatorKey,
    );
  }
}
