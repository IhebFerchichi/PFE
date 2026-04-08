import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_controller.dart';
import '../models/pack_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_choice_chip.dart';
import '../widgets/metric_tiles.dart';
import '../widgets/pack_cards.dart';
import '../widgets/section_card.dart';
import '../widgets/telemetry_widgets.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  bool _loading = true;
  String? _error;
  PackType _selectedType = PackType.lfp;
  String? _selectedPackCode;
  int? _selectedCellIndex;

  List<VisiblePack> _packs = const [];
  List<PackTelemetry> _lfpLatest = const [];
  List<PackTelemetry> _supercapLatest = const [];
  List<CellTelemetry> _lfpCells = const [];
  List<CellTelemetry> _supercapCells = const [];
  List<PackHistoryPoint> _lfpHistory = const [];
  List<PackHistoryPoint> _supercapHistory = const [];
  List<CellHistoryPoint> _selectedCellHistory = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  VisiblePack? get _selectedPack {
    if (_selectedPackCode == null && _packs.isNotEmpty) {
      return _packs.first;
    }

    for (final pack in _packs) {
      if (pack.packageCode == _selectedPackCode) {
        return pack;
      }
    }

    return null;
  }

  String? get _selectedBmsId {
    final pack = _selectedPack;
    if (pack == null) {
      return null;
    }

    return _selectedType == PackType.lfp ? pack.lfpBmsId : pack.supercapBmsId;
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
        widget.controller.api.getLfpCellsLatest(limit: 500),
        widget.controller.api.getSupercapCellsLatest(limit: 500),
      ]);

      final packs = results[0] as List<VisiblePack>;
      setState(() {
        _packs = packs;
        _selectedPackCode = packs.any(
          (pack) => pack.packageCode == _selectedPackCode,
        )
            ? _selectedPackCode
            : packs.isNotEmpty
                ? packs.first.packageCode
                : null;
        _lfpLatest = results[1] as List<PackTelemetry>;
        _supercapLatest = results[2] as List<PackTelemetry>;
        _lfpCells = results[3] as List<CellTelemetry>;
        _supercapCells = results[4] as List<CellTelemetry>;
      });

      await _loadHistoryAndCell();
    } on ApiException catch (error) {
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not load pack detail right now.';
        _loading = false;
      });
    }
  }

  Future<void> _loadHistoryAndCell() async {
    final pack = _selectedPack;
    if (pack == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final to = DateTime.now();
    final from = to.subtract(const Duration(minutes: 90));

    try {
      final results = await Future.wait<dynamic>([
        widget.controller.api.getLfpHistory(
          bmsId: pack.lfpBmsId,
          from: from,
          to: to,
        ),
        widget.controller.api.getSupercapHistory(
          bmsId: pack.supercapBmsId,
          from: from,
          to: to,
        ),
      ]);

      List<CellHistoryPoint> selectedCellHistory = const [];
      if (_selectedCellIndex != null && _selectedBmsId != null) {
        selectedCellHistory = await _fetchCellHistory(
          cellIndex: _selectedCellIndex!,
          type: _selectedType,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _lfpHistory = results[0] as List<PackHistoryPoint>;
        _supercapHistory = results[1] as List<PackHistoryPoint>;
        _selectedCellHistory = selectedCellHistory;
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
        _error = 'Could not load pack telemetry history.';
        _loading = false;
      });
    }
  }

  Future<List<CellHistoryPoint>> _fetchCellHistory({
    required int cellIndex,
    required PackType type,
  }) async {
    final bmsId = _selectedBmsId;
    if (bmsId == null) {
      return const [];
    }

    final to = DateTime.now();
    final from = to.subtract(const Duration(minutes: 60));

    if (type == PackType.lfp) {
      return widget.controller.api.getLfpCellHistory(
        cellIndex: cellIndex,
        bmsId: bmsId,
        from: from,
        to: to,
      );
    }

    return widget.controller.api.getSupercapCellHistory(
      cellIndex: cellIndex,
      bmsId: bmsId,
      from: from,
      to: to,
    );
  }

  void _selectPack(String packageCode) {
    setState(() {
      _selectedPackCode = packageCode;
      _selectedCellIndex = null;
      _selectedCellHistory = const [];
      _loading = true;
    });
    _loadHistoryAndCell();
  }

  void _switchPackType(PackType type) {
    if (_selectedType == type) {
      return;
    }

    setState(() {
      _selectedType = type;
      _selectedCellIndex = null;
      _selectedCellHistory = const [];
      _loading = true;
    });
    _loadHistoryAndCell();
  }

  Future<void> _selectCell(int cellIndex) async {
    setState(() {
      _selectedCellIndex = cellIndex;
      _loading = true;
    });

    try {
      final history = await _fetchCellHistory(
        cellIndex: cellIndex,
        type: _selectedType,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCellHistory = history;
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
        _error = 'Could not load that cell history.';
        _loading = false;
      });
    }
  }

  PackTelemetry? get _selectedTelemetry {
    final bmsId = _selectedBmsId;
    if (bmsId == null) {
      return null;
    }

    final source = _selectedType == PackType.lfp ? _lfpLatest : _supercapLatest;
    for (final row in source) {
      if (row.bmsId == bmsId) {
        return row;
      }
    }

    return null;
  }

  List<PackHistoryPoint> get _selectedHistoryRows {
    final bmsId = _selectedBmsId;
    final source =
        _selectedType == PackType.lfp ? _lfpHistory : _supercapHistory;

    if (bmsId == null) {
      return const [];
    }

    return source.where((row) => row.bmsId == bmsId).toList(growable: false);
  }

  List<CellTelemetry> get _selectedCells {
    final bmsId = _selectedBmsId;
    final source = _selectedType == PackType.lfp ? _lfpCells : _supercapCells;
    if (bmsId == null) {
      return const [];
    }

    final seen = <int>{};
    final result = <CellTelemetry>[];

    for (final row in source) {
      if (row.packBmsId != bmsId || seen.contains(row.cellIndex)) {
        continue;
      }

      seen.add(row.cellIndex);
      result.add(row);
    }

    result.sort((a, b) => a.cellIndex.compareTo(b.cellIndex));
    return result;
  }

  List<double> _historyValues(double? Function(PackHistoryPoint row) selector) {
    return _selectedHistoryRows
        .map(selector)
        .whereType<double>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPack = _selectedPack;
    final selectedTelemetry = _selectedTelemetry;
    final chartColor =
        _selectedType == PackType.lfp ? AppColors.ocean : AppColors.coral;
    final cellChartValues = _selectedCellHistory
        .map((point) => point.cellVoltage)
        .whereType<double>()
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          if (_error != null)
            SectionCard(
              title: 'Could not load pack detail',
              subtitle: _error,
              child: FilledButton.tonal(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            )
          else if (_loading && _packs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SectionCard(
              title: 'Select pack',
              subtitle: _packs.isEmpty
                  ? 'Nothing is approved for this user yet.'
                  : 'Switch between approved battery packages and inspect mobile telemetry.',
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
              _LaneHero(
                pack: selectedPack,
                selectedType: _selectedType,
                telemetry: selectedTelemetry,
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Telemetry lane',
                subtitle:
                    'Switch between the LFP and Supercap sides of the selected package.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppChoiceChip(
                      label: 'LFP',
                      selected: _selectedType == PackType.lfp,
                      onTap: () => _switchPackType(PackType.lfp),
                      icon: Icons.battery_5_bar_rounded,
                    ),
                    AppChoiceChip(
                      label: 'Supercap',
                      selected: _selectedType == PackType.supercap,
                      onTap: () => _switchPackType(PackType.supercap),
                      icon: Icons.bolt_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: '${selectedPack.displayName} - ${_selectedType.label}',
                subtitle: _selectedBmsId == null
                    ? 'This side of the package has not been assigned yet.'
                    : 'BMS ${_selectedBmsId!}',
                child: Column(
                  children: [
                    MetricRow(
                      label: 'Voltage',
                      value: formatNumber(selectedTelemetry?.packVoltage, 'V'),
                      emphasis: true,
                    ),
                    MetricRow(
                      label: 'Current',
                      value: formatNumber(selectedTelemetry?.packCurrent, 'A'),
                    ),
                    MetricRow(
                      label: 'Temperature',
                      value:
                          formatNumber(selectedTelemetry?.temperature, 'deg C'),
                    ),
                    MetricRow(
                      label: 'Last update',
                      value: formatDateTime(selectedTelemetry?.timestamp),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Trends',
                subtitle:
                    'Recent mobile-friendly history for the selected lane.',
                child: Column(
                  children: [
                    MetricChartCard(
                      title: 'Voltage',
                      unit: 'V',
                      values: _historyValues((row) => row.packVoltage),
                      color: chartColor,
                    ),
                    const SizedBox(height: 14),
                    MetricChartCard(
                      title: 'Current',
                      unit: 'A',
                      values: _historyValues((row) => row.packCurrent),
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 14),
                    MetricChartCard(
                      title: 'Temperature',
                      unit: 'deg C',
                      values: _historyValues((row) => row.temperature),
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Cells',
                subtitle: _selectedCells.isEmpty
                    ? 'No cell telemetry is available for this lane.'
                    : 'Tap a cell to view its last hour of voltage history.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final cell in _selectedCells)
                      Builder(
                        builder: (context) {
                          final isSelected =
                              _selectedCellIndex == cell.cellIndex;
                          final isBalancing = cell.balancingOn;
                          final borderColor = isBalancing
                              ? AppColors.danger
                              : isSelected
                                  ? chartColor
                                  : AppColors.line;
                          final backgroundColor = isBalancing
                              ? AppColors.danger.withValues(alpha: 0.12)
                              : isSelected
                                  ? chartColor.withValues(alpha: 0.08)
                                  : Colors.white;
                          final titleColor =
                              isBalancing ? AppColors.danger : null;
                          final valueColor = isBalancing
                              ? AppColors.danger
                              : Theme.of(context).textTheme.bodyMedium?.color;
                          final statusColor = isBalancing
                              ? AppColors.danger
                              : AppColors.success;

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _selectCell(cell.cellIndex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 94,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: borderColor, width: 1.2),
                                color: backgroundColor,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${cell.cellIndex}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontSize: 16,
                                          color: titleColor,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatNumber(cell.cellVoltage, 'V'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: valueColor,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isBalancing ? 'Balancing on' : 'Stable',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: statusColor,
                                          fontWeight: isBalancing
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (_selectedCellIndex != null) ...[
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Cell $_selectedCellIndex history',
                  subtitle:
                      'Last hour of cell voltage from the backend history endpoints.',
                  child: MetricChartCard(
                    title: 'Cell voltage',
                    unit: 'V',
                    values: cellChartValues,
                    color: chartColor,
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _LaneHero extends StatelessWidget {
  const _LaneHero({
    required this.pack,
    required this.selectedType,
    required this.telemetry,
  });

  final VisiblePack pack;
  final PackType selectedType;
  final PackTelemetry? telemetry;

  @override
  Widget build(BuildContext context) {
    final laneColor =
        selectedType == PackType.lfp ? AppColors.ocean : AppColors.coral;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            laneColor.withValues(alpha: 0.18),
            Colors.white,
          ],
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: laneColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selectedType.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: laneColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pack.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Voltage',
                  value: formatNumber(telemetry?.packVoltage, 'V'),
                  color: AppColors.ocean,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Current',
                  value: formatNumber(telemetry?.packCurrent, 'A'),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Temp',
                  value: formatNumber(telemetry?.temperature, 'deg C'),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

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
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
