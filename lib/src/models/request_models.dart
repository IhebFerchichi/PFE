import '../core/json_utils.dart';

class PackageRequestUserSummary {
  const PackageRequestUserSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;

  factory PackageRequestUserSummary.fromJson(Map<String, dynamic> json) {
    return PackageRequestUserSummary(
      id: readInt(json, 'id') ?? 0,
      fullName: readString(json, 'fullName') ?? 'Unknown user',
      email: readString(json, 'email') ?? '',
      role: readString(json, 'role') ?? 'USER',
    );
  }
}

class PackageRequestItem {
  const PackageRequestItem({
    required this.id,
    required this.requestedLabel,
    required this.reason,
    required this.status,
    required this.requestedAt,
    required this.reviewedAt,
    required this.adminComment,
    required this.user,
    required this.reviewedBy,
  });

  final int id;
  final String? requestedLabel;
  final String? reason;
  final String status;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? adminComment;
  final PackageRequestUserSummary? user;
  final PackageRequestUserSummary? reviewedBy;

  String get displayLabel {
    final label = requestedLabel?.trim();
    return label == null || label.isEmpty ? 'Requested package' : label;
  }

  factory PackageRequestItem.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final reviewedByJson = json['reviewedBy'];

    return PackageRequestItem(
      id: readInt(json, 'id') ?? 0,
      requestedLabel: readString(json, 'requestedLabel'),
      reason: readString(json, 'reason'),
      status: readString(json, 'status') ?? 'PENDING',
      requestedAt: readDateTime(json, 'requestedAt'),
      reviewedAt: readDateTime(json, 'reviewedAt'),
      adminComment: readString(json, 'adminComment'),
      user: userJson is Map<String, dynamic>
          ? PackageRequestUserSummary.fromJson(userJson)
          : userJson is Map
              ? PackageRequestUserSummary.fromJson(asJsonMap(userJson))
              : null,
      reviewedBy: reviewedByJson is Map<String, dynamic>
          ? PackageRequestUserSummary.fromJson(reviewedByJson)
          : reviewedByJson is Map
              ? PackageRequestUserSummary.fromJson(asJsonMap(reviewedByJson))
              : null,
    );
  }
}
