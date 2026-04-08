import '../core/json_utils.dart';

class AlertItem {
  const AlertItem({
    required this.id,
    required this.packType,
    required this.bmsId,
    required this.source,
    required this.alertCode,
    required this.severity,
    required this.title,
    required this.message,
    required this.cellIndex,
    required this.measuredValue,
    required this.thresholdValue,
    required this.unit,
    required this.active,
    required this.acknowledged,
    required this.createdAt,
  });

  final int id;
  final String packType;
  final String? bmsId;
  final String source;
  final String alertCode;
  final String severity;
  final String title;
  final String? message;
  final int? cellIndex;
  final double? measuredValue;
  final double? thresholdValue;
  final String? unit;
  final bool active;
  final bool acknowledged;
  final DateTime? createdAt;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: readInt(json, 'id') ?? 0,
      packType: readString(json, 'packType') ?? '-',
      bmsId: readString(json, 'bmsId', fallbackKey: 'bms_id'),
      source: readString(json, 'source') ?? '-',
      alertCode: readString(json, 'alertCode') ?? '-',
      severity: readString(json, 'severity') ?? 'INFO',
      title: readString(json, 'title') ?? 'Untitled alert',
      message: readString(json, 'message'),
      cellIndex: readInt(json, 'cellIndex'),
      measuredValue: readDouble(json, 'measuredValue'),
      thresholdValue: readDouble(json, 'thresholdValue'),
      unit: readString(json, 'unit'),
      active: readBool(json, 'active', defaultValue: false),
      acknowledged: readBool(json, 'acknowledged', defaultValue: false),
      createdAt: readDateTime(json, 'createdAt'),
    );
  }
}
