import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/alert_models.dart';
import 'api_client.dart';

class AlertEvent {
  const AlertEvent({
    required this.alert,
    required this.detectedAt,
  });

  final AlertItem alert;
  final DateTime detectedAt;
}

class AlertMonitor extends ChangeNotifier {
  AlertMonitor({required this.api});

  final ApiClient api;
  final ListQueue<AlertEvent> _pendingEvents = ListQueue<AlertEvent>();
  final Set<int> _seenActiveAlertIds = <int>{};

  Timer? _timer;
  bool _primed = false;
  bool _pollInFlight = false;

  bool get hasPendingEvents => _pendingEvents.isNotEmpty;

  AlertEvent? popNextEvent() {
    if (_pendingEvents.isEmpty) {
      return null;
    }

    return _pendingEvents.removeFirst();
  }

  void start() {
    if (_timer != null) {
      return;
    }

    _poll();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    stop();
    _primed = false;
    _pendingEvents.clear();
    _seenActiveAlertIds.clear();
  }

  Future<void> _poll() async {
    if (_pollInFlight) {
      return;
    }

    _pollInFlight = true;

    try {
      final activeAlerts = await api.getActiveAlerts();

      if (!_primed) {
        _seenActiveAlertIds
          ..clear()
          ..addAll(activeAlerts.map((alert) => alert.id));
        _primed = true;
        return;
      }

      final newAlerts = activeAlerts
          .where((alert) => !_seenActiveAlertIds.contains(alert.id))
          .toList(growable: false);

      for (final alert in activeAlerts) {
        _seenActiveAlertIds.add(alert.id);
      }

      if (newAlerts.isEmpty) {
        return;
      }

      newAlerts.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return left.compareTo(right);
      });

      for (final alert in newAlerts) {
        _pendingEvents.add(
          AlertEvent(
            alert: alert,
            detectedAt: DateTime.now(),
          ),
        );
      }

      notifyListeners();
    } on ApiException {
      return;
    } catch (_) {
      return;
    } finally {
      _pollInFlight = false;
    }
  }
}
