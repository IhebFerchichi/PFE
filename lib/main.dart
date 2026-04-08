import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'src/app.dart';
import 'src/core/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(BatteryPackApp(notificationService: notificationService));
}
