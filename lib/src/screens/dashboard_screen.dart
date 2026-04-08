import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_controller.dart';
import '../models/alert_models.dart';
import '../models/pack_models.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_tiles.dart';
import '../widgets/pack_cards.dart';
import '../widgets/section_card.dart';
import '../widgets/telemetry_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  List<VisiblePack> _packs = const [];
  List<PackTelemetry> _lfpLatest = const [];
  List<PackTelemetry> _supercapLatest = const [];
  List<AlertItem> _activeAlerts = const [];
  List<PackHistoryPoint> _lfpHistory = const [];
  List<PackHistoryPoint> _supercapHistory = const [];
  String? _selectedPackCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  VisiblePack? get _selectedPack {
    final target = _selectedPackCode;
    if (target == null && _packs.isNotEmpty) {
      return _packs.first;
    }

    for (final pack in _packs) {
      if (pack.packageCode == target) {
        return pack;
      }
    }

    return null;
  }

  PackTelemetry? _latestFor(String? bmsId, List<PackTelemetry> source) {
    if (bmsId == null) {
      return null;
    }

    for (final row in source) {
      if (row.bmsId == bmsId) {
        return row;
      }
    }

    return null;
  }

  List<double> _historySeries(
    List<PackHistoryPoint> history,
    String? bmsId,
    double? Function(PackHistoryPoint row) selector,
  ) {
    if (bmsId == null) {
      return const [];
    }

    return history
        .where((row) => row.bmsId == bmsId)
        .map(selector)
        .whereType<double>()
        .toList(growable: false);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        widget.controller.api.getVisiblePacks(),
        widget.controller.api.getLfpLatest(limit: 200),
        widget.controller.api.getSupercapLatest(limit: 200),
        widget.controller.api.getActiveAlerts(),
      ]);

      final packs = results[0] as List<VisiblePack>;
      final selectedPackCode = packs.any(
        (pack) => pack.packageCode == _selectedPackCode,
      )
          ? _selectedPackCode
          : packs.isNotEmpty
              ? packs.first.packageCode
              : null;

      setState(() {
        _packs = packs;
        _selectedPackCode = selectedPackCode;
        _lfpLatest = results[1] as List<PackTelemetry>;
        _supercapLatest = results[2] as List<PackTelemetry>;
        _activeAlerts = results[3] as List<AlertItem>;
      });

      await _loadSelectedHistory();
    } on ApiException catch (error) {
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not load dashboard data right now.';
        _loading = false;
      });
    }
  }

  Future<void> _loadSelectedHistory() async {
    final selectedPack = _selectedPack;
    if (selectedPack == null) {
      setState(() {
        _lfpHistory = const [];
        _supercapHistory = const [];
        _loading = false;
      });
      return;
    }

    final to = DateTime.now();
    final from = to.subtract(const Duration(minutes: 90));

    try {
      final results = await Future.wait<dynamic>([
        widget.controller.api.getLfpHistory(
          bmsId: selectedPack.lfpBmsId,
          from: from,
          to: to,
        ),
        widget.controller.api.getSupercapHistory(
          bmsId: selectedPack.supercapBmsId,
          from: from,
          to: to,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _lfpHistory = results[0] as List<PackHistoryPoint>;
        _supercapHistory = results[1] as List<PackHistoryPoint>;
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
        _error = 'Could not load trend history for the selected pack.';
        _loading = false;
      });
    }
  }

  void _selectPack(String packageCode) {
    if (_selectedPackCode == packageCode) {
      return;
    }

    setState(() {
      _selectedPackCode = packageCode;
      _loading = true;
    });
    _loadSelectedHistory();
  }

  int _selectedAlertCount() {
    final selectedPack = _selectedPack;
    if (selectedPack == null) {
      return 0;
    }

    final bmsIds = {
      if (selectedPack.lfpBmsId != null) selectedPack.lfpBmsId!,
      if (selectedPack.supercapBmsId != null) selectedPack.supercapBmsId!,
    };

    return _activeAlerts.where((alert) => bmsIds.contains(alert.bmsId)).length;
  }

  @override
  Widget build(BuildContext context) {
    final selectedPack = _selectedPack;
    final lfpTelemetry = _latestFor(selectedPack?.lfpBmsId, _lfpLatest);
    final supercapTelemetry =
        _latestFor(selectedPack?.supercapBmsId, _supercapLatest);
    final hasData = !_loading && _error == null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SectionCard(
            title: 'Field Snapshot',
            subtitle:
                'A mobile-first summary of the same backend telemetry that the web console is reading.',
            action: IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 540 ? 3 : 2;
                const spacing = 12.0;
                final itemWidth =
                    (constraints.maxWidth - ((columns - 1) * spacing)) /
                        columns;

                final tiles = [
                  StatTile(
                    label: 'Approved packs',
                    value: '${_packs.length}',
                    caption: 'Visible in your catalog',
                    accent: AppColors.ocean,
                    icon: Icons.inventory_2_rounded,
                  ),
                  StatTile(
                    label: 'Active alerts',
                    value: '${_activeAlerts.length}',
                    caption: 'Across accessible packs',
                    accent: AppColors.coral,
                    icon: Icons.warning_amber_rounded,
                  ),
                  StatTile(
                    label: 'Selected pack alerts',
                    value: '${_selectedAlertCount()}',
                    caption: selectedPack?.displayName ?? 'Choose a pack',
                    accent: AppColors.warning,
                    icon: Icons.bolt_rounded,
                  ),
                ];

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var index = 0; index < tiles.length; index++)
                      SizedBox(
                        width: columns == 2 && index == tiles.length - 1
                            ? constraints.maxWidth
                            : itemWidth,
                        child: tiles[index],
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            SectionCard(
              title: 'Connection issue',
              subtitle: _error,
              child: FilledButton.tonalIcon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            )
          else if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            if (selectedPack != null) ...[
              _OverviewSpotlight(
                pack: selectedPack,
                alertCount: _selectedAlertCount(),
                lfpTelemetry: lfpTelemetry,
                supercapTelemetry: supercapTelemetry,
              ),
              const SizedBox(height: 16),
            ],
            SectionCard(
              title: 'Package context',
              subtitle: _packs.isEmpty
                  ? 'No approved package is available for this account yet.'
                  : 'Choose which logical pack the overview should represent.',
              child: _packs.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 248,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _packs.length,
                        itemBuilder: (context, index) {
                          final pack = _packs[index];
                          return PackSelectorCard(
                            pack: pack,
                            selected:
                                selectedPack?.packageCode == pack.packageCode,
                            onTap: () => _selectPack(pack.packageCode),
                            showOwner: widget.controller.user?.isAdmin ?? false,
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            if (selectedPack != null) ...[
              TelemetrySummaryCard(
                title: '${selectedPack.displayName} - LFP',
                bmsId: selectedPack.lfpBmsId,
                telemetry: lfpTelemetry,
                chartValues: _historySeries(
                  _lfpHistory,
                  selectedPack.lfpBmsId,
                  (row) => row.packVoltage,
                ),
                color: AppColors.ocean,
              ),
              const SizedBox(height: 16),
              TelemetrySummaryCard(
                title: '${selectedPack.displayName} - Supercap',
                bmsId: selectedPack.supercapBmsId,
                telemetry: supercapTelemetry,
                chartValues: _historySeries(
                  _supercapHistory,
                  selectedPack.supercapBmsId,
                  (row) => row.packVoltage,
                ),
                color: AppColors.coral,
              ),
            ],
            if (hasData && selectedPack == null)
              const SectionCard(
                title: 'Nothing selected yet',
                subtitle:
                    'Once a package is approved in the backend, it will show up here automatically.',
                child: SizedBox.shrink(),
              ),
          ],
        ],
      ),
    );
  }
}

class _OverviewSpotlight extends StatelessWidget {
  const _OverviewSpotlight({
    required this.pack,
    required this.alertCount,
    required this.lfpTelemetry,
    required this.supercapTelemetry,
  });

  final VisiblePack pack;
  final int alertCount;
  final PackTelemetry? lfpTelemetry;
  final PackTelemetry? supercapTelemetry;

  @override
  Widget build(BuildContext context) {
    final accentText = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.oceanDeep, AppColors.ocean, Color(0xFF6D84CB)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ocean.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
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
                      'Selected Package',
                      style: accentText,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pack.displayName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${pack.ownerFullName}  ${pack.packageCode}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerts',
                      style: accentText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$alertCount',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
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
                child: _SpotlightMetric(
                  label: 'LFP',
                  value: formatNumber(lfpTelemetry?.packVoltage, 'V'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SpotlightMetric(
                  label: 'Supercap',
                  value: formatNumber(supercapTelemetry?.packVoltage, 'V'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SpotlightMetric(
                  label: 'Status',
                  value: pack.status,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightMetric extends StatelessWidget {
  const _SpotlightMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
