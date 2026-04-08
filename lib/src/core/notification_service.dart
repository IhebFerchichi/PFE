import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alert_models.dart';
import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }

  await Firebase.initializeApp();
  await _ensureLocalNotificationsInitialized();
  await _showLocalNotificationFromMessage(message);
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(
  NotificationResponse response,
) {
  // The main isolate consumes the launch/open intent on startup or resume.
}

final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
    FlutterLocalNotificationsPlugin();
bool _backgroundLocalNotificationsInitialized = false;

class NotificationService {
  static const String androidChannelId = 'alerts_high_importance';
  static const String androidChannelName = 'Battery Pack Alerts';
  static const String androidChannelDescription =
      'High-priority battery pack alert notifications.';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<AlertItem> _foregroundAlertsController =
      StreamController<AlertItem>.broadcast();
  final StreamController<void> _alertOpenRequestsController =
      StreamController<void>.broadcast();

  ApiClient? _api;
  bool Function()? _isAuthenticated;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _notificationOpenSubscription;
  bool _initialized = false;
  bool _supported = false;
  bool _pendingAlertOpen = false;
  bool _syncInFlight = false;
  String? _registeredToken;

  Stream<AlertItem> get foregroundAlerts => _foregroundAlertsController.stream;

  Stream<void> get alertOpenRequests => _alertOpenRequestsController.stream;

  bool get isSupported => _supported;

  void bindApi({
    required ApiClient api,
    required bool Function() isAuthenticated,
  }) {
    _api = api;
    _isAuthenticated = isAuthenticated;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    try {
      await Firebase.initializeApp();
      await _initializeLocalNotifications();
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _notificationOpenSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        unawaited(_syncToken(token));
      });

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpen(initialMessage);
      }

      _supported = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase messaging initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _supported = false;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    await _ensureLocalNotificationsInitialized(
      plugin: _localNotifications,
      onTapForeground: _handleLocalNotificationResponse,
      onTapBackground: onDidReceiveBackgroundNotificationResponse,
    );

    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _pendingAlertOpen = true;
    }
  }

  Future<void> registerCurrentDevice({
    String? authToken,
  }) async {
    if (!_supported || !_isAuthenticatedNow()) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }

      await _syncToken(
        token.trim(),
        authToken: authToken,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to register FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> unregisterCurrentDevice({
    String? authToken,
  }) async {
    if (!_supported || _api == null) {
      _registeredToken = null;
      return;
    }

    try {
      final token =
          _registeredToken ?? await FirebaseMessaging.instance.getToken();
      _registeredToken = null;

      if (token == null || token.trim().isEmpty) {
        return;
      }

      await _api!.unregisterDeviceToken(
        token: token.trim(),
        authToken: authToken,
      );
    } on ApiException catch (error) {
      debugPrint('Failed to unregister FCM token: ${error.message}');
    } catch (error, stackTrace) {
      debugPrint('Failed to unregister FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool consumePendingAlertOpen() {
    final pending = _pendingAlertOpen;
    _pendingAlertOpen = false;
    return pending;
  }

  Future<void> _syncToken(
    String token, {
    String? authToken,
  }) async {
    if (_syncInFlight || !_isAuthenticatedNow() || _api == null) {
      return;
    }

    if (_registeredToken == token) {
      return;
    }

    _syncInFlight = true;

    try {
      await _api!.registerDeviceToken(
        token: token,
        platform: 'android',
        authToken: authToken,
      );
      _registeredToken = token;
    } on ApiException catch (error) {
      debugPrint('Failed to sync FCM token: ${error.message}');
    } catch (error, stackTrace) {
      debugPrint('Failed to sync FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _syncInFlight = false;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final alert = _alertFromMessage(message);
    if (alert == null) {
      return;
    }

    _foregroundAlertsController.add(alert);
  }

  void _handleNotificationOpen(RemoteMessage message) {
    _pendingAlertOpen = true;
    _alertOpenRequestsController.add(null);
  }

  void _handleLocalNotificationResponse(NotificationResponse response) {
    _pendingAlertOpen = true;
    _alertOpenRequestsController.add(null);
  }

  AlertItem? _alertFromMessage(RemoteMessage message) {
    final payload = <String, dynamic>{
      ...message.data,
    };

    final notification = message.notification;
    if (notification != null) {
      payload.putIfAbsent('title', () => notification.title ?? 'Battery alert');
      payload.putIfAbsent('message', () => notification.body ?? '');
    }

    if (payload.isEmpty) {
      return null;
    }

    payload.putIfAbsent('id', () => '0');
    payload.putIfAbsent('packType', () => 'LFP');
    payload.putIfAbsent('source', () => 'FCM');
    payload.putIfAbsent('alertCode', () => 'ALERT');
    payload.putIfAbsent('severity', () => 'INFO');
    payload.putIfAbsent('active', () => 'true');
    payload.putIfAbsent('acknowledged', () => 'false');

    return AlertItem.fromJson(payload);
  }

  bool _isAuthenticatedNow() => _isAuthenticated?.call() ?? false;

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _notificationOpenSubscription?.cancel();
    _foregroundAlertsController.close();
    _alertOpenRequestsController.close();
  }
}

Future<void> _ensureLocalNotificationsInitialized({
  FlutterLocalNotificationsPlugin? plugin,
  DidReceiveNotificationResponseCallback? onTapForeground,
  DidReceiveBackgroundNotificationResponseCallback? onTapBackground,
}) async {
  final target = plugin ?? _backgroundLocalNotifications;
  if (identical(target, _backgroundLocalNotifications) &&
      _backgroundLocalNotificationsInitialized) {
    return;
  }

  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await target.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: onTapForeground,
    onDidReceiveBackgroundNotificationResponse: onTapBackground,
  );

  final androidPlugin = target.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.requestNotificationsPermission();
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      NotificationService.androidChannelId,
      NotificationService.androidChannelName,
      description: NotificationService.androidChannelDescription,
      importance: Importance.max,
      playSound: true,
    ),
  );

  if (identical(target, _backgroundLocalNotifications)) {
    _backgroundLocalNotificationsInitialized = true;
  }
}

Future<void> _showLocalNotificationFromMessage(RemoteMessage message) async {
  final payload = _payloadFromMessage(message);
  if (payload.isEmpty) {
    return;
  }

  final title = payload['title']?.toString().trim();
  final body = payload['message']?.toString().trim();
  final alertId = int.tryParse(payload['id']?.toString() ?? '') ??
      payload.hashCode.abs() % 2147483647;

  await _backgroundLocalNotifications.show(
    id: alertId,
    title: title?.isNotEmpty == true ? title : 'Battery alert',
    body: body?.isNotEmpty == true
        ? body
        : _fallbackNotificationBodySafe(payload),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationService.androidChannelId,
        NotificationService.androidChannelName,
        channelDescription: NotificationService.androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    ),
    payload: jsonEncode(payload),
  );
}

Map<String, dynamic> _payloadFromMessage(RemoteMessage message) {
  final payload = <String, dynamic>{
    ...message.data,
  };

  final notification = message.notification;
  if (notification != null) {
    payload.putIfAbsent('title', () => notification.title ?? 'Battery alert');
    payload.putIfAbsent('message', () => notification.body ?? '');
  }

  return payload;
}

String _fallbackNotificationBodySafe(Map<String, dynamic> payload) {
  final severity = payload['severity']?.toString().trim();
  final bmsId = payload['bmsId']?.toString().trim();
  final alertCode = payload['alertCode']?.toString().trim();

  final parts = <String>[];
  if (severity != null && severity.isNotEmpty) {
    parts.add(severity);
  }
  if (alertCode != null && alertCode.isNotEmpty) {
    parts.add(alertCode);
  }
  if (bmsId != null && bmsId.isNotEmpty) {
    parts.add('BMS $bmsId');
  }

  return parts.isEmpty ? 'New battery pack alert detected.' : parts.join(' - ');
}

String _fallbackNotificationBody(Map<String, dynamic> payload) {
  final severity = payload['severity']?.toString().trim();
  final bmsId = payload['bmsId']?.toString().trim();
  final alertCode = payload['alertCode']?.toString().trim();

  final parts = <String>[];
  if (severity != null && severity.isNotEmpty) {
    parts.add(severity);
  }
  if (alertCode != null && alertCode.isNotEmpty) {
    parts.add(alertCode);
  }
  if (bmsId != null && bmsId.isNotEmpty) {
    parts.add('BMS $bmsId');
  }

  return parts.isEmpty ? 'New battery pack alert detected.' : parts.join(' • ');
}
