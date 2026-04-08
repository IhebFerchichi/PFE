import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_controller.dart';
import '../models/alert_models.dart';
import '../models/pack_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_choice_chip.dart';
import '../widgets/metric_tiles.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badges.dart';
import '../widgets/telemetry_widgets.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _loading = true;
  String? _error;
  String _search = '';
  String _severity = 'ALL';
  final Set<int> _busyAlertIds = <int>{};

  List<VisiblePack> _packs = const [];
  List<AlertItem> _active = const [];
  List<AlertItem> _recent = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        widget.controller.api.getVisiblePacks(),
        widget.controller.api.getActiveAlerts(),
        widget.controller.api.getRecentAlerts(limit: 50),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _packs = results[0] as List<VisiblePack>;
        _active = results[1] as List<AlertItem>;
        _recent = results[2] as List<AlertItem>;
        _busyAlertIds.clear();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Could not load alerts right now.';
        _loading = false;
      });
    }
  }

  List<AlertItem> get _filteredActive =>
      _active.where(_matchesFilters).toList();

  List<AlertItem> get _filteredRecent =>
      _recent.where(_matchesFilters).toList();

  bool _matchesFilters(AlertItem alert) {
    if (_severity != 'ALL' && alert.severity.toUpperCase() != _severity) {
      return false;
    }

    final query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final pack = _findPack(alert);
    final haystack = [
      alert.alertCode,
      alert.title,
      alert.source,
      alert.packType,
      alert.bmsId ?? '',
      pack?.displayName ?? '',
      pack?.packageCode ?? '',
      pack?.ownerFullName ?? '',
      pack?.ownerEmail ?? '',
    ].join(' ').toLowerCase();

    return haystack.contains(query);
  }

  VisiblePack? _findPack(AlertItem alert) {
    for (final pack in _packs) {
      final matchesLfp =
          alert.packType.toUpperCase() == 'LFP' && pack.lfpBmsId == alert.bmsId;
      final matchesSupercap = alert.packType.toUpperCase() == 'SUPERCAP' &&
          pack.supercapBmsId == alert.bmsId;
      if (matchesLfp || matchesSupercap) {
        return pack;
      }
    }

    return null;
  }

  Future<void> _actOnAlert(
    AlertItem alert,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _busyAlertIds.add(alert.id);
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() {
        _busyAlertIds.remove(alert.id);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The backend request failed.')),
      );
      setState(() {
        _busyAlertIds.remove(alert.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          if (!_loading && _error == null) ...[
            _AlertsHero(
              activeCount: _active.length,
              recentCount: _recent.length,
              criticalCount: _active
                  .where((alert) => alert.severity.toUpperCase() == 'CRITICAL')
                  .length,
              activeFilter: _severity,
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            title: 'Filter alerts',
            subtitle: 'Search by code, pack, owner, BMS, or severity.',
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search',
                    hintText: 'OV, Pack A, owner, BMS...',
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final severity in const [
                      'ALL',
                      'INFO',
                      'WARNING',
                      'CRITICAL',
                    ])
                      AppChoiceChip(
                        label: severity,
                        selected: _severity == severity,
                        onTap: () => setState(() => _severity = severity),
                        icon: severity == 'ALL'
                            ? Icons.tune_rounded
                            : severity == 'CRITICAL'
                                ? Icons.warning_rounded
                                : severity == 'WARNING'
                                    ? Icons.report_problem_rounded
                                    : Icons.info_outline_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            SectionCard(
              title: 'Connection issue',
              subtitle: _error,
              child: FilledButton.tonal(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SectionCard(
              title: 'Active alerts',
              subtitle:
                  '${_filteredActive.length} currently match your filters.',
              child: _filteredActive.isEmpty
                  ? const Text('No active alerts match the current filters.')
                  : Column(
                      children: [
                        for (final alert in _filteredActive) ...[
                          _AlertCard(
                            alert: alert,
                            pack: _findPack(alert),
                            busy: _busyAlertIds.contains(alert.id),
                            isAdmin: widget.controller.user?.isAdmin ?? false,
                            onAcknowledge: alert.acknowledged
                                ? null
                                : () => _actOnAlert(
                                      alert,
                                      () => widget.controller.api
                                          .acknowledgeAlert(alert.id),
                                      'Alert acknowledged.',
                                    ),
                            onResolve: () => _actOnAlert(
                              alert,
                              () =>
                                  widget.controller.api.resolveAlert(alert.id),
                              'Alert resolved.',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Recent alerts',
              subtitle:
                  '${_filteredRecent.length} recent items match your filters.',
              child: _filteredRecent.isEmpty
                  ? const Text('No recent alerts match the current filters.')
                  : Column(
                      children: [
                        for (final alert in _filteredRecent.take(12)) ...[
                          _AlertCard(
                            alert: alert,
                            pack: _findPack(alert),
                            busy: false,
                            isAdmin: widget.controller.user?.isAdmin ?? false,
                            onAcknowledge: null,
                            onResolve: null,
                            compactActions: true,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertsHero extends StatelessWidget {
  const _AlertsHero({
    required this.activeCount,
    required this.recentCount,
    required this.criticalCount,
    required this.activeFilter,
  });

  final int activeCount;
  final int recentCount;
  final int criticalCount;
  final String activeFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4F1), Colors.white, Color(0xFFF6F8FE)],
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alert Control',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeFilter == 'ALL'
                          ? 'Watching every live alert across your accessible packs.'
                          : 'Focused on $activeFilter alerts right now.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.coral,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$criticalCount critical',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Active',
                  value: '$activeCount',
                  color: AppColors.coral,
                  icon: Icons.warning_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Recent',
                  value: '$recentCount',
                  color: AppColors.ocean,
                  icon: Icons.history_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Critical',
                  value: '$criticalCount',
                  color: AppColors.warning,
                  icon: Icons.priority_high_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.pack,
    required this.busy,
    required this.isAdmin,
    required this.onAcknowledge,
    required this.onResolve,
    this.compactActions = false,
  });

  final AlertItem alert;
  final VisiblePack? pack;
  final bool busy;
  final bool isAdmin;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onResolve;
  final bool compactActions;

  @override
  Widget build(BuildContext context) {
    final badgeColor = severityColor(alert.severity);
    final packLabel = pack?.displayName ?? 'Unassigned pack';
    final ownerLabel = isAdmin
        ? (pack == null
            ? 'Unknown owner'
            : '${pack!.ownerFullName} (${pack!.ownerEmail})')
        : (pack?.ownerFullName ?? 'My pack');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: badgeColor.withValues(alpha: 0.28)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFCFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _alertIcon(alert.severity),
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(label: alert.severity, color: badgeColor),
                    _TagBadge(
                      label: alert.packType,
                      color: AppColors.ocean,
                    ),
                    _TagBadge(
                      label: alert.alertCode,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert.alertCode} • ${alert.source} • ${alert.packType}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                formatDateTime(alert.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                MetricRow(label: 'Pack', value: packLabel),
                MetricRow(label: 'BMS', value: alert.bmsId ?? '-'),
                MetricRow(label: 'Owner', value: ownerLabel),
              ],
            ),
          ),
          if (alert.message?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(alert.message!),
            ),
          ],
          if (!compactActions && (onAcknowledge != null || onResolve != null))
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (onAcknowledge != null)
                    FilledButton.tonalIcon(
                      onPressed: busy ? null : onAcknowledge,
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        alert.acknowledged ? 'Acknowledged' : 'Acknowledge',
                      ),
                    ),
                  if (onResolve != null)
                    FilledButton.icon(
                      onPressed: busy ? null : onResolve,
                      icon: const Icon(Icons.task_alt_rounded),
                      label: const Text('Resolve'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({
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
        color: color.withValues(alpha: 0.10),
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

IconData _alertIcon(String severity) {
  switch (severity.toUpperCase()) {
    case 'CRITICAL':
      return Icons.crisis_alert_rounded;
    case 'WARNING':
      return Icons.warning_amber_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}
