import 'dart:convert';
import 'dart:io';

import '../models/alert_models.dart';
import '../models/ai_prediction_models.dart';
import '../models/auth_models.dart';
import '../models/pack_models.dart';
import '../models/request_models.dart';
import 'json_utils.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.getToken,
  });

  final String baseUrl;
  final String? Function() getToken;

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12);

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    return _send(
      'POST',
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      parser: (json) => LoginResponse.fromJson(asJsonMap(json)),
    );
  }

  Future<AuthUser> getMe() async {
    return _send(
      'GET',
      '/auth/me',
      parser: (json) => AuthUser.fromJson(asJsonMap(json)),
    );
  }

  Future<AuthMessageResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _send(
      'POST',
      '/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
      },
      parser: (json) => AuthMessageResponse.fromJson(asJsonMap(json)),
    );
  }

  Future<AuthMessageResponse> requestPasswordReset({
    required String email,
  }) async {
    return _send(
      'POST',
      '/auth/forgot-password',
      body: {
        'email': email,
      },
      parser: (json) => AuthMessageResponse.fromJson(asJsonMap(json)),
    );
  }

  Future<List<VisiblePack>> getVisiblePacks() async {
    return _send(
      'GET',
      '/packs/catalog',
      parser: (json) =>
          asJsonList(json).map(VisiblePack.fromJson).toList(growable: false),
    );
  }

  Future<List<PackTelemetry>> getLfpLatest({int limit = 200}) async {
    return _getTelemetry('/packs/lfp/latest', limit: limit);
  }

  Future<List<PackTelemetry>> getSupercapLatest({int limit = 200}) async {
    return _getTelemetry('/packs/supercap/latest', limit: limit);
  }

  Future<List<CellTelemetry>> getLfpCellsLatest({int limit = 500}) async {
    return _send(
      'GET',
      '/packs/lfp/cells/latest',
      query: {'limit': '$limit'},
      parser: (json) =>
          asJsonList(json).map(CellTelemetry.fromJson).toList(growable: false),
    );
  }

  Future<List<CellTelemetry>> getSupercapCellsLatest({int limit = 500}) async {
    return _send(
      'GET',
      '/packs/supercap/cells/latest',
      query: {'limit': '$limit'},
      parser: (json) =>
          asJsonList(json).map(CellTelemetry.fromJson).toList(growable: false),
    );
  }

  Future<List<PackHistoryPoint>> getLfpHistory({
    String? bmsId,
    required DateTime from,
    required DateTime to,
  }) async {
    return _getHistory('/packs/lfp/history', bmsId: bmsId, from: from, to: to);
  }

  Future<List<PackHistoryPoint>> getSupercapHistory({
    String? bmsId,
    required DateTime from,
    required DateTime to,
  }) async {
    return _getHistory(
      '/packs/supercap/history',
      bmsId: bmsId,
      from: from,
      to: to,
    );
  }

  Future<List<CellHistoryPoint>> getLfpCellHistory({
    required int cellIndex,
    String? bmsId,
    required DateTime from,
    required DateTime to,
  }) async {
    return _getCellHistory(
      '/packs/lfp/cells/$cellIndex/history',
      bmsId: bmsId,
      from: from,
      to: to,
    );
  }

  Future<List<CellHistoryPoint>> getSupercapCellHistory({
    required int cellIndex,
    String? bmsId,
    required DateTime from,
    required DateTime to,
  }) async {
    return _getCellHistory(
      '/packs/supercap/cells/$cellIndex/history',
      bmsId: bmsId,
      from: from,
      to: to,
    );
  }

  Future<List<AlertItem>> getActiveAlerts() async {
    return _send(
      'GET',
      '/alerts/active',
      parser: (json) =>
          asJsonList(json).map(AlertItem.fromJson).toList(growable: false),
    );
  }

  Future<List<AlertItem>> getRecentAlerts({int limit = 50}) async {
    return _send(
      'GET',
      '/alerts/recent',
      query: {'limit': '$limit'},
      parser: (json) =>
          asJsonList(json).map(AlertItem.fromJson).toList(growable: false),
    );
  }

  Future<List<AiPrediction>> getAiPredictionsLatest() async {
    return _send(
      'GET',
      '/ai/predictions/latest',
      parser: (json) => asJsonList(json)
          .map(AiPrediction.fromJson)
          .toList(growable: false),
    );
  }

  Future<AiPrediction> getAiPredictionLatest(String bmsId) async {
    return _send(
      'GET',
      '/ai/predictions/$bmsId/latest',
      parser: (json) => AiPrediction.fromJson(asJsonMap(json)),
    );
  }

  Future<List<AiPrediction>> getAiPredictionHistory(String bmsId) async {
    return _send(
      'GET',
      '/ai/predictions/$bmsId/history',
      parser: (json) => asJsonList(json)
          .map(AiPrediction.fromJson)
          .toList(growable: false),
    );
  }

  Future<AiPredictionRefreshResponse> refreshAiPrediction(String bmsId) async {
    return _send(
      'POST',
      '/ai/predictions/$bmsId/refresh',
      body: const <String, Object?>{},
      parser: (json) =>
          AiPredictionRefreshResponse.fromJson(asJsonMap(json)),
    );
  }

  Future<void> acknowledgeAlert(int alertId) async {
    await _send<void>(
      'POST',
      '/alerts/$alertId/acknowledge',
      body: const <String, Object?>{},
      parser: (_) {},
    );
  }

  Future<void> resolveAlert(int alertId) async {
    await _send<void>(
      'POST',
      '/alerts/$alertId/resolve',
      body: const <String, Object?>{},
      parser: (_) {},
    );
  }

  Future<PackageRequestItem> createPackageRequest({
    required String requestedLabel,
    required String reason,
  }) async {
    return _send(
      'POST',
      '/user/package-requests',
      body: {
        'requestedLabel': requestedLabel,
        'reason': reason,
      },
      parser: (json) => PackageRequestItem.fromJson(asJsonMap(json)),
    );
  }

  Future<List<PackageRequestItem>> getMyPackageRequests() async {
    return _send(
      'GET',
      '/user/package-requests',
      parser: (json) => asJsonList(json)
          .map(PackageRequestItem.fromJson)
          .toList(growable: false),
    );
  }

  Future<List<PackageRequestItem>> getPendingPackageRequests() async {
    return _send(
      'GET',
      '/admin/package-requests/pending',
      parser: (json) => asJsonList(json)
          .map(PackageRequestItem.fromJson)
          .toList(growable: false),
    );
  }

  Future<PackageRequestItem> approvePackageRequest({
    required int requestId,
    required String lfpBmsId,
    required String supercapBmsId,
    String? adminComment,
  }) async {
    return _send(
      'POST',
      '/admin/package-requests/$requestId/approve',
      body: {
        'adminComment': adminComment,
        'lfpBmsId': lfpBmsId,
        'supercapBmsId': supercapBmsId,
      },
      parser: (json) => PackageRequestItem.fromJson(asJsonMap(json)),
    );
  }

  Future<PackageRequestItem> rejectPackageRequest({
    required int requestId,
    String? adminComment,
  }) async {
    return _send(
      'POST',
      '/admin/package-requests/$requestId/reject',
      body: {
        'adminComment': adminComment,
      },
      parser: (json) => PackageRequestItem.fromJson(asJsonMap(json)),
    );
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? authToken,
  }) async {
    await _send<void>(
      'POST',
      '/notifications/device-token',
      body: {
        'token': token,
        'platform': platform,
      },
      authToken: authToken,
      parser: (_) {},
    );
  }

  Future<void> unregisterDeviceToken({
    required String token,
    String? authToken,
  }) async {
    await _send<void>(
      'POST',
      '/notifications/device-token/unregister',
      body: {
        'token': token,
      },
      authToken: authToken,
      parser: (_) {},
    );
  }

  Future<List<PackTelemetry>> _getTelemetry(String path, {required int limit}) {
    return _send(
      'GET',
      path,
      query: {'limit': '$limit'},
      parser: (json) =>
          asJsonList(json).map(PackTelemetry.fromJson).toList(growable: false),
    );
  }

  Future<List<PackHistoryPoint>> _getHistory(
    String path, {
    String? bmsId,
    required DateTime from,
    required DateTime to,
  }) {
    return _send(
      'GET',
      path,
      query: {
        'bmsId': bmsId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      parser: (json) => asJsonList(json)
          .map(PackHistoryPoint.fromJson)
          .toList(growable: false),
    );
  }

  Future<List<CellHistoryPoint>> _getCellHistory(
    String path, {
    String? bmsId,
    required DateTime from,
    required DateTime to,
  }) {
    return _send(
      'GET',
      path,
      query: {
        'bmsId': bmsId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      parser: (json) => asJsonList(json)
          .map(CellHistoryPoint.fromJson)
          .toList(growable: false),
    );
  }

  Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, String?> query = const {},
    String? authToken,
    required T Function(dynamic json) parser,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null && entry.value!.trim().isNotEmpty)
            entry.key: entry.value!,
      },
    );

    final request = await _httpClient.openUrl(method, uri);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final token = authToken ?? getToken();
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final payload = await utf8.decoder.bind(response).join();
    final decoded =
        payload.trim().isEmpty ? null : jsonDecode(payload) as Object?;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(decoded) ??
            'Request failed with status ${response.statusCode}.',
        response.statusCode,
      );
    }

    return parser(decoded);
  }

  String? _errorMessage(dynamic decoded) {
    if (decoded is Map) {
      final json = asJsonMap(decoded);
      return readString(json, 'message') ??
          readString(json, 'error') ??
          readString(json, 'detail');
    }

    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded.trim();
    }

    return null;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
