import 'dart:convert';

class WatermarkSettings {
  final bool showDateTime;
  final String customText;
  final double fontSize;
  final int colorValue;
  final String position;

  const WatermarkSettings({
    this.showDateTime = true,
    this.customText = '',
    this.fontSize = 16,
    this.colorValue = 0xFFFFFFFF,
    this.position = 'bottomRight',
  });

  WatermarkSettings copyWith({
    bool? showDateTime,
    String? customText,
    double? fontSize,
    int? colorValue,
    String? position,
  }) {
    return WatermarkSettings(
      showDateTime: showDateTime ?? this.showDateTime,
      customText: customText ?? this.customText,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showDateTime': showDateTime,
      'customText': customText,
      'fontSize': fontSize,
      'colorValue': colorValue,
      'position': position,
    };
  }

  factory WatermarkSettings.fromMap(Map<String, dynamic> map) {
    return WatermarkSettings(
      showDateTime: map['showDateTime'] ?? true,
      customText: map['customText'] ?? '',
      fontSize: (map['fontSize'] ?? 16).toDouble(),
      colorValue: map['colorValue'] ?? 0xFFFFFFFF,
      position: map['position'] ?? 'bottomRight',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WatermarkSettings.fromJson(String source) {
    return WatermarkSettings.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }
}
