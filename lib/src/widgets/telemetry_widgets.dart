import 'package:flutter/material.dart';

import '../models/pack_models.dart';
import '../theme/app_theme.dart';
import 'metric_tiles.dart';
import 'section_card.dart';
import 'sparkline_chart.dart';
import 'status_badges.dart';

class TelemetrySummaryCard extends StatelessWidget {
  const TelemetrySummaryCard({
    super.key,
    required this.title,
    required this.bmsId,
    required this.telemetry,
    required this.chartValues,
    required this.color,
  });

  final String title;
  final String? bmsId;
  final PackTelemetry? telemetry;
  final List<double> chartValues;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isOnline = telemetry?.timestamp != null &&
        DateTime.now().difference(telemetry!.timestamp!).inSeconds < 30;
    final values = chartValues;

    return SectionCard(
      title: title,
      subtitle: bmsId == null ? 'No BMS linked yet' : 'BMS $bmsId',
      action: StatusBadge(
        label: isOnline ? 'ONLINE' : 'OFFLINE',
        color: isOnline ? AppColors.success : AppColors.danger,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _MiniLegend(label: 'Trend', color: color),
                    const Spacer(),
                    Text(
                      values.isEmpty
                          ? 'No recent samples'
                          : '${values.length} samples',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SparklineChart(values: values, color: color),
                if (values.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _RangeSummary(values: values, unit: 'V', color: color),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          MetricRow(
            label: 'Voltage',
            value: formatNumber(telemetry?.packVoltage, 'V'),
            emphasis: true,
          ),
          MetricRow(
            label: 'Current',
            value: formatNumber(telemetry?.packCurrent, 'A'),
          ),
          MetricRow(
            label: 'Temperature',
            value: formatNumber(telemetry?.temperature, 'deg C'),
          ),
          MetricRow(
            label: 'Last update',
            value: formatDateTime(telemetry?.timestamp),
          ),
        ],
      ),
    );
  }
}

class MetricChartCard extends StatelessWidget {
  const MetricChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.values,
    required this.color,
  });

  final String title;
  final String unit;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final latest = values.isEmpty ? null : values.last;
    final minValue =
        values.isEmpty ? null : values.reduce((a, b) => a < b ? a : b);
    final maxValue =
        values.isEmpty ? null : values.reduce((a, b) => a > b ? a : b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            latest == null
                ? 'No samples'
                : '${latest.toStringAsFixed(2)} $unit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _MiniLegend(label: unit, color: color),
                    const Spacer(),
                    Text(
                      values.isEmpty ? 'Awaiting history' : 'Last 90 min',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SparklineChart(values: values, color: color, height: 118),
                if (latest != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricHint(
                          label: 'Min',
                          value: minValue == null
                              ? '-'
                              : '${minValue.toStringAsFixed(2)} $unit',
                        ),
                      ),
                      Expanded(
                        child: _MetricHint(
                          label: 'Max',
                          value: maxValue == null
                              ? '-'
                              : '${maxValue.toStringAsFixed(2)} $unit',
                        ),
                      ),
                      Expanded(
                        child: _MetricHint(
                          label: 'Latest',
                          value: '${latest.toStringAsFixed(2)} $unit',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSummary extends StatelessWidget {
  const _RangeSummary({
    required this.values,
    required this.unit,
    required this.color,
  });

  final List<double> values;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final delta = maxValue - minValue;

    return Row(
      children: [
        Expanded(
          child: _MetricHint(
            label: 'Range',
            value: '${delta.toStringAsFixed(2)} $unit',
            color: color,
          ),
        ),
        Expanded(
          child: _MetricHint(
            label: 'Min',
            value: '${minValue.toStringAsFixed(2)} $unit',
          ),
        ),
        Expanded(
          child: _MetricHint(
            label: 'Max',
            value: '${maxValue.toStringAsFixed(2)} $unit',
          ),
        ),
      ],
    );
  }
}

class _MetricHint extends StatelessWidget {
  const _MetricHint({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _MiniLegend extends StatelessWidget {
  const _MiniLegend({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

String formatNumber(double? value, String unit) {
  if (value == null) {
    return '-';
  }

  return '${value.toStringAsFixed(2)} $unit';
}

String formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final local = value.toLocal();
  final twoDigits = (int v) => v.toString().padLeft(2, '0');
  return '${local.day}/${local.month}/${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
}
