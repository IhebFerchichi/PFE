Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(key.toString(), nestedValue),
    );
  }

  throw const FormatException('Expected a JSON object.');
}

List<Map<String, dynamic>> asJsonList(dynamic value) {
  if (value is! List) {
    throw const FormatException('Expected a JSON array.');
  }

  return value.map(asJsonMap).toList(growable: false);
}

String? readString(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final value = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? readInt(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final value = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double? readDouble(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final value = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

bool readBool(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
  bool defaultValue = false,
}) {
  final value = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  if (value == null) {
    return defaultValue;
  }

  if (value is bool) {
    return value;
  }

  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') {
    return true;
  }

  if (text == 'false' || text == '0') {
    return false;
  }

  return defaultValue;
}

DateTime? readDateTime(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final text = readString(json, key, fallbackKey: fallbackKey);
  if (text == null) {
    return null;
  }

  return DateTime.tryParse(text)?.toLocal();
}
