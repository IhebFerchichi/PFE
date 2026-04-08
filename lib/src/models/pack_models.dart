import '../core/json_utils.dart';

enum PackType {
  lfp,
  supercap;

  String get label => this == PackType.lfp ? 'LFP' : 'Supercap';
}

class VisiblePack {
  const VisiblePack({
    required this.id,
    required this.packageCode,
    required this.label,
    required this.status,
    required this.ownerUserId,
    required this.ownerFullName,
    required this.ownerEmail,
    required this.lfpBmsId,
    required this.supercapBmsId,
    required this.createdAt,
  });

  final int id;
  final String packageCode;
  final String? label;
  final String status;
  final int? ownerUserId;
  final String ownerFullName;
  final String ownerEmail;
  final String? lfpBmsId;
  final String? supercapBmsId;
  final DateTime? createdAt;

  String get displayName =>
      (label?.trim().isNotEmpty ?? false) ? label!.trim() : packageCode;

  factory VisiblePack.fromJson(Map<String, dynamic> json) {
    return VisiblePack(
      id: readInt(json, 'id') ?? 0,
      packageCode: readString(json, 'packageCode') ?? '-',
      label: readString(json, 'label'),
      status: readString(json, 'status') ?? 'UNKNOWN',
      ownerUserId: readInt(json, 'ownerUserId'),
      ownerFullName: readString(json, 'ownerFullName') ?? 'Unknown owner',
      ownerEmail: readString(json, 'ownerEmail') ?? '',
      lfpBmsId: readString(json, 'lfpBmsId'),
      supercapBmsId: readString(json, 'supercapBmsId'),
      createdAt: readDateTime(json, 'createdAt'),
    );
  }
}

class PackTelemetry {
  const PackTelemetry({
    required this.bmsId,
    required this.packVoltage,
    required this.packCurrent,
    required this.temperature,
    required this.timestamp,
  });

  final String? bmsId;
  final double? packVoltage;
  final double? packCurrent;
  final double? temperature;
  final DateTime? timestamp;

  factory PackTelemetry.fromJson(Map<String, dynamic> json) {
    return PackTelemetry(
      bmsId: readString(json, 'bmsId', fallbackKey: 'bms_id'),
      packVoltage: readDouble(json, 'packVoltage', fallbackKey: 'pack_voltage'),
      packCurrent: readDouble(json, 'packCurrent', fallbackKey: 'pack_current'),
      temperature: readDouble(json, 'temperature'),
      timestamp: readDateTime(json, 'ts'),
    );
  }
}

class CellTelemetry {
  const CellTelemetry({
    required this.packBmsId,
    required this.cellIndex,
    required this.cellVoltage,
    required this.balancingOn,
    required this.timestamp,
  });

  final String? packBmsId;
  final int cellIndex;
  final double? cellVoltage;
  final bool balancingOn;
  final DateTime? timestamp;

  factory CellTelemetry.fromJson(Map<String, dynamic> json) {
    final nestedPack = json['pack'];
    final nestedPackJson =
        nestedPack is Map ? asJsonMap(nestedPack) : const <String, dynamic>{};

    return CellTelemetry(
      packBmsId: readString(json, 'packBmsId', fallbackKey: 'pack_bms_id') ??
          readString(nestedPackJson, 'bmsId', fallbackKey: 'bms_id'),
      cellIndex: readInt(json, 'cellIndex', fallbackKey: 'cell_index') ?? 0,
      cellVoltage: readDouble(json, 'cellVoltage', fallbackKey: 'cell_voltage'),
      balancingOn: readBool(json, 'balancingOn', fallbackKey: 'balancing_on'),
      timestamp: readDateTime(json, 'ts'),
    );
  }
}

class PackHistoryPoint {
  const PackHistoryPoint({
    required this.bmsId,
    required this.packVoltage,
    required this.packCurrent,
    required this.temperature,
    required this.timestamp,
  });

  final String? bmsId;
  final double? packVoltage;
  final double? packCurrent;
  final double? temperature;
  final DateTime? timestamp;

  factory PackHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PackHistoryPoint(
      bmsId: readString(json, 'bmsId', fallbackKey: 'bms_id'),
      packVoltage: readDouble(json, 'packVoltage', fallbackKey: 'pack_voltage'),
      packCurrent: readDouble(json, 'packCurrent', fallbackKey: 'pack_current'),
      temperature: readDouble(json, 'temperature'),
      timestamp: readDateTime(json, 'ts'),
    );
  }
}

class CellHistoryPoint {
  const CellHistoryPoint({
    required this.packBmsId,
    required this.cellIndex,
    required this.cellVoltage,
    required this.timestamp,
  });

  final String? packBmsId;
  final int cellIndex;
  final double? cellVoltage;
  final DateTime? timestamp;

  factory CellHistoryPoint.fromJson(Map<String, dynamic> json) {
    return CellHistoryPoint(
      packBmsId: readString(json, 'packBmsId', fallbackKey: 'pack_bms_id') ??
          readString(json, 'bmsId', fallbackKey: 'bms_id'),
      cellIndex: readInt(json, 'cellIndex', fallbackKey: 'cell_index') ?? 0,
      cellVoltage: readDouble(json, 'cellVoltage', fallbackKey: 'cell_voltage'),
      timestamp: readDateTime(json, 'ts'),
    );
  }
}
