import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_controller.dart';
import '../models/ai_prediction_models.dart';
import '../models/pack_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_choice_chip.dart';
import '../widgets/metric_tiles.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badges.dart';

class AiPredictionsScreen extends StatefulWidget {
  const AiPredictionsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AiPredictionsScreen> createState() => _AiPredictionsScreenState();
}

class _AiPredictionsScreenState extends State<AiPredictionsScreen> {
  bool _loading = true;
  bool _historyLoading = false;
  String? _error;
  String _search = '';
  String _riskLevel = 'ALL';
  String _packType = 'ALL';
  String? _refreshingBmsId;

  List<VisiblePack> _packs = const [];
  List<AiPrediction> _latest = const [];
  List<AiPrediction> _history = const [];
  String? _selectedPackCode;
  _PredictionSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? preferredBmsId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        widget.controller.api.getVisiblePacks(),
        widget.controller.api.getAiPredictionsLatest(),
      ]);

      if (!mounted) {
        return;
      }

      final packs = results[0] as List<VisiblePack>;
      final latest = results[1] as List<AiPrediction>;
      setState(() {
        _packs = packs;
        _latest = latest;
        _selectedPackCode = _resolveSelectedPackCode(packs);
        _loading = false;
      });

      await _syncSelection(preferredBmsId: preferredBmsId);
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
        _error = 'Could not load AI predictions right now.';
        _loading = false;
      });
    }
  }

  Future<void> _loadHistory(String bmsId) async {
    setState(() => _historyLoading = true);

    try {
      final history = await widget.controller.api.getAiPredictionHistory(bmsId);
      if (!mounted) {
        return;
      }
      setState(() {
        _history = history;
        _historyLoading = false;
      });
    } on ApiException catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _history = const [];
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _history = const [];
        _historyLoading = false;
      });
    }
  }

  Future<void> _refreshPrediction(_PredictionSlot slot) async {
    setState(() => _refreshingBmsId = slot.bmsId);

    try {
      final response = await widget.controller.api.refreshAiPrediction(
        slot.bmsId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _load(preferredBmsId: response.prediction.bmsId);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      setState(() => _refreshingBmsId = null);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh AI prediction.')),
      );
      setState(() => _refreshingBmsId = null);
    }
  }

  VisiblePack? get _selectedPack {
    final code = _selectedPackCode;
    if (code == null) {
      return null;
    }

    for (final pack in _packs) {
      if (pack.packageCode == code) {
        return pack;
      }
    }

    return null;
  }

  List<_PredictionSlot> get _filteredSlots {
    return _buildSlots()
        .where((slot) {
          if (_riskLevel != 'ALL' &&
              (slot.prediction?.riskLevel.toUpperCase() ?? '') != _riskLevel) {
            return false;
          }

          if (_packType != 'ALL' && slot.packType != _packType) {
            return false;
          }

          final query = _search.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }

          final prediction = slot.prediction;
          final pack = _selectedPack;
          final haystack = [
            slot.bmsId,
            slot.packType,
            prediction?.riskLevel ?? '',
            prediction?.predictedIssue ?? '',
            prediction?.recommendedAction ?? '',
            pack?.displayName ?? '',
            pack?.packageCode ?? '',
            pack?.ownerFullName ?? '',
            pack?.ownerEmail ?? '',
          ].join(' ').toLowerCase();

          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  String _packTitle(_PredictionSlot slot) =>
      _selectedPack?.displayName ?? 'BMS ${slot.bmsId}';

  String _packMeta(_PredictionSlot slot) {
    final pack = _selectedPack;
    if (pack == null) {
      return '${slot.packType} | BMS ${slot.bmsId}';
    }

    return '${pack.packageCode} | ${slot.packType} | BMS ${slot.bmsId}';
  }

  String _ownerMeta() {
    final pack = _selectedPack;
    if (pack == null) {
      return widget.controller.user?.isAdmin ?? false
          ? 'Unknown owner'
          : 'My pack';
    }

    return widget.controller.user?.isAdmin ?? false
        ? '${pack.ownerFullName} (${pack.ownerEmail})'
        : pack.ownerFullName;
  }

  String _scoreText(double? value) =>
      value == null ? '-' : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          if (!_loading && _error == null) ...[
            _AiHero(
              totalPredictions: _filteredSlots.length,
              highRiskCount: _latest
                  .where(
                    (prediction) =>
                        prediction.riskLevel.toUpperCase() == 'HIGH',
                  )
                  .length,
              selectedPackLabel: _selectedPack == null
                  ? 'No pack selected'
                  : _selectedPack!.displayName,
            ),
            const SizedBox(height: 16),
          ],
          if (_packs.isNotEmpty)
            SectionCard(
              title: 'Select pack',
              subtitle:
                  'Choose the package, then inspect its LFP and Supercap AI prediction state.',
              child: SizedBox(
                height: 194,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _packs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final pack = _packs[index];
                    return SizedBox(
                      width: 300,
                      child: _PackChooserCard(
                        pack: pack,
                        selected: _selectedPackCode == pack.packageCode,
                        isAdmin: widget.controller.user?.isAdmin ?? false,
                        onTap: () async {
                          setState(() => _selectedPackCode = pack.packageCode);
                          await _syncSelection();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          if (_packs.isNotEmpty) const SizedBox(height: 16),
          SectionCard(
            title: 'Filter predictions',
            subtitle: 'Search by pack, BMS, Issue, Owner, or Risk level.',
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search',
                    hintText: 'Pack, BMS, issue...',
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final risk in const ['ALL', 'LOW', 'MEDIUM', 'HIGH'])
                      AppChoiceChip(
                        label: risk,
                        selected: _riskLevel == risk,
                        onTap: () => setState(() => _riskLevel = risk),
                        icon: risk == 'ALL'
                            ? Icons.tune_rounded
                            : risk == 'HIGH'
                            ? Icons.warning_rounded
                            : risk == 'MEDIUM'
                            ? Icons.report_problem_rounded
                            : Icons.verified_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final packType in const ['ALL', 'LFP', 'SUPERCAP'])
                      AppChoiceChip(
                        label: packType,
                        selected: _packType == packType,
                        onTap: () => setState(() => _packType = packType),
                        icon: packType == 'ALL'
                            ? Icons.battery_unknown_rounded
                            : packType == 'LFP'
                            ? Icons.battery_full_rounded
                            : Icons.electric_bolt_rounded,
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
              title: 'Latest predictions',
              subtitle:
                  '${_filteredSlots.length} pack sides currently match your filters.',
              child: _filteredSlots.isEmpty
                  ? Text(
                      _selectedPack == null
                          ? 'Select a pack first to inspect AI predictions.'
                          : 'No AI predictions match the current filters for this pack.',
                    )
                  : Column(
                      children: [
                        for (final slot in _filteredSlots) ...[
                          _PredictionCard(
                            slot: slot,
                            packTitle: _packTitle(slot),
                            packMeta: _packMeta(slot),
                            ownerMeta: _ownerMeta(),
                            selected: _selectedSlot?.bmsId == slot.bmsId,
                            busy: _refreshingBmsId == slot.bmsId,
                            scoreText: _scoreText(slot.prediction?.riskScore),
                            anomalyText: _scoreText(
                              slot.prediction?.anomalyScore,
                            ),
                            onTap: () async {
                              setState(() => _selectedSlot = slot);
                              await _loadHistory(slot.bmsId);
                            },
                            onRefresh: () => _refreshPrediction(slot),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
            if (_selectedSlot != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Prediction details',
                subtitle: _packMeta(_selectedSlot!),
                action: FilledButton.tonalIcon(
                  onPressed: _refreshingBmsId == _selectedSlot!.bmsId
                      ? null
                      : () => _refreshPrediction(_selectedSlot!),
                  icon: _refreshingBmsId == _selectedSlot!.bmsId
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    _refreshingBmsId == _selectedSlot!.bmsId
                        ? 'Refreshing'
                        : 'Refresh',
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          MetricRow(
                            label: 'Risk level',
                            value:
                                _selectedSlot!.prediction?.riskLevel ??
                                'PENDING',
                          ),
                          MetricRow(
                            label: 'Risk score',
                            value: _scoreText(
                              _selectedSlot!.prediction?.riskScore,
                            ),
                          ),
                          MetricRow(
                            label: 'Anomaly score',
                            value: _scoreText(
                              _selectedSlot!.prediction?.anomalyScore,
                            ),
                          ),
                          MetricRow(
                            label: 'Issue',
                            value:
                                _selectedSlot!.prediction?.predictedIssue ??
                                'No prediction has been saved yet for this BMS.',
                          ),
                          MetricRow(
                            label: 'Window',
                            value:
                                '${_formatDate(_selectedSlot!.prediction?.windowStart)} to ${_formatDate(_selectedSlot!.prediction?.windowEnd)}',
                          ),
                          MetricRow(
                            label: 'Predicted at',
                            value: _formatDate(
                              _selectedSlot!.prediction?.predictedAt,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommended action',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.oceanDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedSlot!.prediction?.recommendedAction ??
                                'Use refresh or wait for the five-minute scheduler to create the first prediction.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Prediction history',
                subtitle:
                    '${_history.length} saved prediction points for this pack.',
                child: _historyLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _history.isEmpty
                    ? const Text(
                        'No saved history yet. Scheduled predictions and manual refreshes will build it.',
                      )
                    : Column(
                        children: [
                          for (final item in _history.take(12)) ...[
                            _HistoryCard(
                              prediction: item,
                              scoreText: _scoreText(item.riskScore),
                              anomalyText: _scoreText(item.anomalyScore),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _resolveSelectedPackCode(List<VisiblePack> packs) {
    final currentCode = _selectedPackCode;
    if (currentCode != null &&
        packs.any((pack) => pack.packageCode == currentCode)) {
      return currentCode;
    }

    return packs.isNotEmpty ? packs.first.packageCode : '';
  }

  Future<void> _syncSelection({String? preferredBmsId}) async {
    final selectedBmsId = preferredBmsId ?? _selectedSlot?.bmsId;
    final slots = _buildSlots();
    final nextSelection = slots.firstWhere(
      (slot) => slot.bmsId == selectedBmsId,
      orElse: () => slots.isNotEmpty ? slots.first : _emptySlot,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedSlot = slots.isEmpty && identical(nextSelection, _emptySlot)
          ? null
          : nextSelection;
    });

    if (_selectedSlot != null) {
      await _loadHistory(_selectedSlot!.bmsId);
    } else if (mounted) {
      setState(() => _history = const []);
    }
  }

  List<_PredictionSlot> _buildSlots() {
    final pack = _selectedPack;
    if (pack == null) {
      return const [];
    }

    final slots = <_PredictionSlot>[];

    if (pack.lfpBmsId?.trim().isNotEmpty ?? false) {
      slots.add(
        _PredictionSlot(
          packType: 'LFP',
          bmsId: pack.lfpBmsId!,
          prediction: _latest.cast<AiPrediction?>().firstWhere(
            (prediction) => prediction?.bmsId == pack.lfpBmsId,
            orElse: () => null,
          ),
        ),
      );
    }

    if (pack.supercapBmsId?.trim().isNotEmpty ?? false) {
      slots.add(
        _PredictionSlot(
          packType: 'SUPERCAP',
          bmsId: pack.supercapBmsId!,
          prediction: _latest.cast<AiPrediction?>().firstWhere(
            (prediction) => prediction?.bmsId == pack.supercapBmsId,
            orElse: () => null,
          ),
        ),
      );
    }

    return slots;
  }
}

class _AiHero extends StatelessWidget {
  const _AiHero({
    required this.totalPredictions,
    required this.highRiskCount,
    required this.selectedPackLabel,
  });

  final int totalPredictions;
  final int highRiskCount;
  final String selectedPackLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF2F6FF), Colors.white, Color(0xFFFAFCFF)],
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
                      'AI Prediction Feed',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ocean.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  selectedPackLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.oceanDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Tracked packs',
                  value: '$totalPredictions',
                  color: AppColors.ocean,
                  icon: Icons.memory_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'High risk',
                  value: '$highRiskCount',
                  color: AppColors.danger,
                  icon: Icons.warning_rounded,
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
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
    required this.slot,
    required this.packTitle,
    required this.packMeta,
    required this.ownerMeta,
    required this.selected,
    required this.busy,
    required this.scoreText,
    required this.anomalyText,
    required this.onTap,
    required this.onRefresh,
  });

  final _PredictionSlot slot;
  final String packTitle;
  final String packMeta;
  final String ownerMeta;
  final bool selected;
  final bool busy;
  final String scoreText;
  final String anomalyText;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.ocean : AppColors.line;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFAFCFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ocean.withValues(alpha: selected ? 0.12 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        packMeta,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: slot.prediction?.riskLevel ?? 'PENDING',
                  color: severityColor(
                    (slot.prediction?.riskLevel ?? '').toUpperCase() == 'HIGH'
                        ? 'CRITICAL'
                        : (slot.prediction?.riskLevel ?? '').toUpperCase() ==
                              'MEDIUM'
                        ? 'WARNING'
                        : slot.prediction == null
                        ? 'WARNING'
                        : 'INFO',
                  ),
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
                  MetricRow(label: 'Risk score', value: scoreText),
                  MetricRow(label: 'Anomaly score', value: anomalyText),
                  MetricRow(
                    label: 'Issue',
                    value:
                        slot.prediction?.predictedIssue ??
                        'No prediction yet for this pack side.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              slot.prediction?.recommendedAction ??
                  'Use refresh or wait for the scheduler to save the first AI result.',
            ),
            const SizedBox(height: 12),
            Text(ownerMeta, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    slot.prediction?.predictedAt == null
                        ? 'Updated -'
                        : 'Updated ${slot.prediction!.predictedAt!.hour.toString().padLeft(2, '0')}:${slot.prediction!.predictedAt!.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: busy ? null : onRefresh,
                  icon: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackChooserCard extends StatelessWidget {
  const _PackChooserCard({
    required this.pack,
    required this.selected,
    required this.isAdmin,
    required this.onTap,
  });

  final VisiblePack pack;
  final bool selected;
  final bool isAdmin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.ocean : AppColors.line,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFAFCFF)],
          ),
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
                        pack.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code ${pack.packageCode}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: pack.status,
                  color: selected ? AppColors.ocean : AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isAdmin)
              Text(
                'Owner: ${pack.ownerFullName} (${pack.ownerEmail})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (isAdmin) const SizedBox(height: 8),
            Text(
              'LFP BMS: ${pack.lfpBmsId ?? 'Not assigned'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Supercap BMS: ${pack.supercapBmsId ?? 'Not assigned'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.prediction,
    required this.scoreText,
    required this.anomalyText,
  });

  final AiPrediction prediction;
  final String scoreText;
  final String anomalyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prediction.predictedIssue ?? 'Prediction snapshot',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(
                label: prediction.riskLevel,
                color: severityColor(
                  prediction.riskLevel.toUpperCase() == 'HIGH'
                      ? 'CRITICAL'
                      : prediction.riskLevel.toUpperCase() == 'MEDIUM'
                      ? 'WARNING'
                      : 'INFO',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MetricRow(label: 'Risk score', value: scoreText),
          MetricRow(label: 'Anomaly score', value: anomalyText),
          MetricRow(
            label: 'Predicted at',
            value: prediction.predictedAt == null
                ? '-'
                : '${prediction.predictedAt!.day.toString().padLeft(2, '0')}/${prediction.predictedAt!.month.toString().padLeft(2, '0')}/${prediction.predictedAt!.year} ${prediction.predictedAt!.hour.toString().padLeft(2, '0')}:${prediction.predictedAt!.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 8),
          Text(
            prediction.recommendedAction ?? 'No recommendation available yet.',
          ),
        ],
      ),
    );
  }
}

class _PredictionSlot {
  const _PredictionSlot({
    required this.packType,
    required this.bmsId,
    required this.prediction,
  });

  final String packType;
  final String bmsId;
  final AiPrediction? prediction;
}

const _PredictionSlot _emptySlot = _PredictionSlot(
  packType: '',
  bmsId: '',
  prediction: null,
);
