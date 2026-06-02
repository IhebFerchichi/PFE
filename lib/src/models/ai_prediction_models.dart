import '../core/json_utils.dart';

class AiPrediction {
  const AiPrediction({
    required this.id,
    required this.bmsId,
    required this.packType,
    required this.riskScore,
    required this.riskLevel,
    required this.anomalyScore,
    required this.predictedIssue,
    required this.recommendedAction,
    required this.modelVersion,
    required this.predictionSource,
    required this.windowStart,
    required this.windowEnd,
    required this.predictedAt,
  });

  final int id;
  final String bmsId;
  final String packType;
  final double? riskScore;
  final String riskLevel;
  final double? anomalyScore;
  final String? predictedIssue;
  final String? recommendedAction;
  final String? modelVersion;
  final String? predictionSource;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final DateTime? predictedAt;

  factory AiPrediction.fromJson(Map<String, dynamic> json) {
    return AiPrediction(
      id: readInt(json, 'id') ?? 0,
      bmsId: readString(json, 'bmsId', fallbackKey: 'bms_id') ?? '-',
      packType: readString(json, 'packType', fallbackKey: 'pack_type') ?? '-',
      riskScore: readDouble(json, 'riskScore', fallbackKey: 'risk_score'),
      riskLevel: readString(json, 'riskLevel', fallbackKey: 'risk_level') ?? 'LOW',
      anomalyScore:
          readDouble(json, 'anomalyScore', fallbackKey: 'anomaly_score'),
      predictedIssue:
          readString(json, 'predictedIssue', fallbackKey: 'predicted_issue'),
      recommendedAction: readString(
        json,
        'recommendedAction',
        fallbackKey: 'recommended_action',
      ),
      modelVersion:
          readString(json, 'modelVersion', fallbackKey: 'model_version'),
      predictionSource: readString(
        json,
        'predictionSource',
        fallbackKey: 'prediction_source',
      ),
      windowStart: readDateTime(json, 'windowStart', fallbackKey: 'window_start'),
      windowEnd: readDateTime(json, 'windowEnd', fallbackKey: 'window_end'),
      predictedAt:
          readDateTime(json, 'predictedAt', fallbackKey: 'predicted_at'),
    );
  }
}

class AiPredictionRefreshResponse {
  const AiPredictionRefreshResponse({
    required this.message,
    required this.prediction,
  });

  final String message;
  final AiPrediction prediction;

  factory AiPredictionRefreshResponse.fromJson(Map<String, dynamic> json) {
    return AiPredictionRefreshResponse(
      message: readString(json, 'message') ?? 'Prediction refreshed successfully.',
      prediction: AiPrediction.fromJson(asJsonMap(json['prediction'])),
    );
  }
}
