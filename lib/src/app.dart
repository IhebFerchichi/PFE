import 'package:flutter/material.dart';

import 'core/app_controller.dart';
import 'core/notification_service.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

class BatteryPackApp extends StatefulWidget {
  BatteryPackApp({
    super.key,
    NotificationService? notificationService,
  }) : notificationService = notificationService ?? NotificationService();

  final NotificationService notificationService;

  @override
  State<BatteryPackApp> createState() => _BatteryPackAppState();
}

class _BatteryPackAppState extends State<BatteryPackApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(
      notifications: widget.notificationService,
    );
  }

  @override
  void dispose() {
    widget.notificationService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Battery Pack',
          theme: buildAppTheme(),
          home: _controller.isAuthenticated
              ? HomeShell(controller: _controller)
              : LoginScreen(controller: _controller),
        );
      },
    );
  }
}
