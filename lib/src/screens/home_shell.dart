import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../core/alert_monitor.dart';
import '../core/app_controller.dart';
import '../models/alert_models.dart';
import '../models/pack_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_surface.dart';
import '../widgets/brand_logo.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'packs_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final ListQueue<AlertItem> _pendingForegroundAlerts = ListQueue<AlertItem>();
  final Set<String> _seenForegroundAlertKeys = <String>{};
  List<VisiblePack> _packLookup = const [];
  late final AlertMonitor _alertMonitor;
  StreamSubscription<AlertItem>? _foregroundAlertSubscription;
  StreamSubscription<void>? _openAlertsSubscription;
  bool _alertDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPackLookup();
    _alertMonitor = AlertMonitor(api: widget.controller.api);
    _alertMonitor.addListener(_onAlertMonitorChanged);
    _alertMonitor.start();
    _foregroundAlertSubscription = widget
        .controller.notifications.foregroundAlerts
        .listen(_queueForegroundAlert);
    _openAlertsSubscription = widget.controller.notifications.alertOpenRequests
        .listen((_) => _openAlertsTab());

    if (widget.controller.notifications.consumePendingAlertOpen()) {
      _selectedIndex = 2;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alertMonitor.removeListener(_onAlertMonitorChanged);
    _alertMonitor.dispose();
    _foregroundAlertSubscription?.cancel();
    _openAlertsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _alertMonitor.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _alertMonitor.stop();
        break;
    }
  }

  void _onAlertMonitorChanged() {
    while (_alertMonitor.hasPendingEvents) {
      final event = _alertMonitor.popNextEvent();
      if (event == null) {
        return;
      }
      _queueForegroundAlert(event.alert);
    }
  }

  Future<void> _loadPackLookup() async {
    try {
      final packs = await widget.controller.api.getVisiblePacks();
      if (!mounted) {
        return;
      }
      setState(() => _packLookup = packs);
    } catch (_) {
      return;
    }
  }

  void _queueForegroundAlert(AlertItem alert) {
    final alertKey = _alertKey(alert);
    if (_seenForegroundAlertKeys.contains(alertKey)) {
      return;
    }

    _seenForegroundAlertKeys.add(alertKey);
    _pendingForegroundAlerts.add(alert);
    _showNextForegroundAlert();
  }

  String _alertKey(AlertItem alert) {
    if (alert.id > 0) {
      return 'id:${alert.id}';
    }

    return [
      alert.alertCode,
      alert.bmsId ?? '-',
      alert.createdAt?.toIso8601String() ?? '-',
      alert.severity,
    ].join('|');
  }

  VisiblePack? _findPackForAlert(AlertItem alert) {
    for (final pack in _packLookup) {
      if (pack.lfpBmsId == alert.bmsId || pack.supercapBmsId == alert.bmsId) {
        return pack;
      }
    }

    return null;
  }

  void _openAlertsTab() {
    if (!mounted) {
      return;
    }

    setState(() => _selectedIndex = 2);
  }

  void _showNextForegroundAlert() {
    if (!mounted || _alertDialogOpen || _pendingForegroundAlerts.isEmpty) {
      return;
    }

    final alert = _pendingForegroundAlerts.removeFirst();
    final pack = _findPackForAlert(alert);
    _alertDialogOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Live alert detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AlertContextBadge(
                    label: alert.severity,
                    color: _severityColor(alert.severity),
                  ),
                  _AlertContextBadge(
                    label: alert.packType,
                    color: AppColors.ocean,
                  ),
                  _AlertContextBadge(
                    label: alert.alertCode,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                alert.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text('BMS: ${alert.bmsId ?? '-'}'),
              if (pack != null) ...[
                const SizedBox(height: 8),
                Text('Package: ${pack.displayName}'),
                const SizedBox(height: 6),
                Text('Assigned to: ${pack.ownerFullName}'),
              ],
              if (alert.message?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                Text(alert.message!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openAlertsTab();
              },
              child: const Text('Open alerts'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }

      _alertDialogOpen = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New alert: ${alert.title}'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (_pendingForegroundAlerts.isNotEmpty) {
        _showNextForegroundAlert();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(controller: widget.controller),
      PacksScreen(controller: widget.controller),
      AlertsScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];

    final titles = ['Overview', 'Packs', 'Alerts', 'Profile'];

    return Scaffold(
      body: AppSurface(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Row(
                children: [
                  const BrandLogo(
                    width: 62,
                    height: 48,
                    padding: EdgeInsets.all(6),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[_selectedIndex],
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          widget.controller.user?.fullName ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.battery_5_bar_outlined),
            selectedIcon: Icon(Icons.battery_full_rounded),
            label: 'Packs',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _AlertContextBadge extends StatelessWidget {
  const _AlertContextBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

Color _severityColor(String severity) {
  switch (severity.toUpperCase()) {
    case 'CRITICAL':
      return AppColors.danger;
    case 'WARNING':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}
