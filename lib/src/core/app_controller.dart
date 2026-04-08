import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import 'api_client.dart';
import 'app_config.dart';
import 'notification_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    AppConfig? config,
    required this.notifications,
  }) : _config = config ?? AppConfig() {
    api = ApiClient(
      baseUrl: _config.baseUrl,
      getToken: () => _token,
    );
    notifications.bindApi(
      api: api,
      isAuthenticated: () => isAuthenticated,
    );
  }

  final AppConfig _config;
  final NotificationService notifications;
  late final ApiClient api;

  AuthUser? _user;
  String? _token;
  bool _authBusy = false;
  String? _authError;

  AuthUser? get user => _user;
  String get baseUrl => _config.baseUrl;
  bool get isAuthenticated => _user != null && _token != null;
  bool get authBusy => _authBusy;
  String? get authError => _authError;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _authBusy = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await api.login(email: email, password: password);
      _token = response.token;
      _user = response.user;
      await notifications.registerCurrentDevice(authToken: _token);
    } on ApiException catch (error) {
      _authError = error.message;
      _token = null;
      _user = null;
    } catch (_) {
      _authError =
          'Could not reach the backend. Make sure the API is running and reachable.';
      _token = null;
      _user = null;
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<AuthMessageResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _authBusy = true;
    _authError = null;
    notifyListeners();

    try {
      return await api.register(
        fullName: fullName,
        email: email,
        password: password,
      );
    } on ApiException catch (error) {
      _authError = error.message;
      rethrow;
    } catch (_) {
      _authError =
          'Could not reach the backend. Make sure the API is running and reachable.';
      throw const ApiException(
        'Could not reach the backend. Make sure the API is running and reachable.',
        0,
      );
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<AuthMessageResponse> requestPasswordReset({
    required String email,
  }) async {
    _authBusy = true;
    _authError = null;
    notifyListeners();

    try {
      return await api.requestPasswordReset(email: email);
    } on ApiException catch (error) {
      _authError = error.message;
      rethrow;
    } catch (_) {
      _authError =
          'Could not reach the backend. Make sure the API is running and reachable.';
      throw const ApiException(
        'Could not reach the backend. Make sure the API is running and reachable.',
        0,
      );
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_token == null) {
      return;
    }

    try {
      _user = await api.getMe();
      await notifications.registerCurrentDevice(authToken: _token);
      notifyListeners();
    } on ApiException catch (_) {
      logout();
    } catch (_) {
      logout();
    }
  }

  void logout() {
    final authToken = _token;
    unawaited(notifications.unregisterCurrentDevice(authToken: authToken));
    _user = null;
    _token = null;
    _authBusy = false;
    _authError = null;
    notifyListeners();
  }

  void clearAuthError() {
    if (_authError == null) {
      return;
    }

    _authError = null;
    notifyListeners();
  }
}
