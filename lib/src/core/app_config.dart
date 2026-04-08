import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig({String? baseUrl}) : baseUrl = _resolveBaseUrl(baseUrl);

  final String baseUrl;

  static String _resolveBaseUrl(String? explicit) {
    final envValue = explicit?.trim().isNotEmpty == true
        ? explicit!.trim()
        : _envBaseUrl();

    if (envValue.isNotEmpty) {
      return envValue;
    }

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.30.14:8080';
      // return 'http://192.168.33.10:8080';

      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:8080';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8080';
    }
  }

  static String _envBaseUrl() {
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    ).trim();
  }
}
