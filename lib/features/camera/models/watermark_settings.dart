
import 'dart:convert';

class WatermarkSettings {
  // FECHA Y HORA
  final bool showDateTime;
  final String dateFormat;
  final String timeFormat;
  final String timeZone;

  // UBICACIÓN Y GPS
  final bool showAddress;
  final bool showCoordinates;
  final bool showAltitude;
  final bool showAccuracy;
  final bool showSpeed;
  final bool showCompass;
  final String coordinatesFormat;
  final String addressFormat;

  // MAPA
  final bool showMap;
  final double mapSize;
  final double mapOpacity;
  final String mapPosition;

  // TEXTO PERSONALIZADO
  final bool showCustomText;
  final String customText;

  // ETIQUETA Y NOTA
  final bool showLabel;
  final String labelText;
  final bool showNote;
  final String noteText;

  // NUMERACIÓN
  final bool showSequence;
  final int sequenceStart;
  final int sequenceDigits;
  final String sequencePrefix;
  final String sequenceSuffix;

  // LOGOTIPO
  final bool showLogo;
  final String? logoPath;
  final double logoSize;
  final double logoOpacity;
  final String logoPosition;

  // APARIENCIA DEL TEXTO
  final double fontSize;
  final int colorValue;
  final String fontFamily;
  final bool bold;
  final bool italic;
  final bool textShadow;
  final bool textOutline;
  final int outlineColorValue;
  final double outlineWidth;
  final String textAlignment;
  final double lineSpacing;

  // FONDO DEL TEXTO
  final int backgroundColorValue;
  final double backgroundOpacity;
  final double backgroundPadding;
  final double backgroundRadius;

  // POSICIÓN GENERAL
  final String position;
  final double margin;

  // ORDEN DE LOS ELEMENTOS
  final List<String> contentOrder;

  // CALIDAD DE FOTOGRAFÍA
  final int imageQuality;

  const WatermarkSettings({
    this.showDateTime = true,
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = 'HH:mm:ss',
    this.timeZone = 'local',

    this.showAddress = true,
    this.showCoordinates = true,
    this.showAltitude = false,
    this.showAccuracy = false,
    this.showSpeed = false,
    this.showCompass = false,
    this.coordinatesFormat = 'decimal',
    this.addressFormat = 'full',

    this.showMap = false,
    this.mapSize = 120,
    this.mapOpacity = 1,
    this.mapPosition = 'topRight',

    this.showCustomText = true,
    this.customText = '',

    this.showLabel = false,
    this.labelText = '',
    this.showNote = false,
    this.noteText = '',

    this.showSequence = false,
    this.sequenceStart = 1,
    this.sequenceDigits = 3,
    this.sequencePrefix = '',
    this.sequenceSuffix = '',

    this.showLogo = false,
    this.logoPath,
    this.logoSize = 80,
    this.logoOpacity = 1,
    this.logoPosition = 'topLeft',

    this.fontSize = 16,
    this.colorValue = 0xFFFFFFFF,
    this.fontFamily = 'Roboto',
    this.bold = false,
    this.italic = false,
    this.textShadow = true,
    this.textOutline = false,
    this.outlineColorValue = 0xFF000000,
    this.outlineWidth = 1,
    this.textAlignment = 'left',
    this.lineSpacing = 1.2,

    this.backgroundColorValue = 0xFF000000,
    this.backgroundOpacity = 0,
    this.backgroundPadding = 8,
    this.backgroundRadius = 8,

    this.position = 'bottomRight',
    this.margin = 16,

    this.contentOrder = const [
      'dateTime',
      'address',
      'coordinates',
      'altitude',
      'accuracy',
      'speed',
      'compass',
      'sequence',
      'label',
      'customText',
      'note',
    ],

    this.imageQuality = 95,
  });

  WatermarkSettings copyWith({
    bool? showDateTime,
    String? dateFormat,
    String? timeFormat,
    String? timeZone,

    bool? showAddress,
    bool? showCoordinates,
    bool? showAltitude,
    bool? showAccuracy,
    bool? showSpeed,
    bool? showCompass,
    String? coordinatesFormat,
    String? addressFormat,

    bool? showMap,
    double? mapSize,
    double? mapOpacity,
    String? mapPosition,

    bool? showCustomText,
    String? customText,

    bool? showLabel,
    String? labelText,
    bool? showNote,
    String? noteText,

    bool? showSequence,
    int? sequenceStart,
    int? sequenceDigits,
    String? sequencePrefix,
    String? sequenceSuffix,

    bool? showLogo,
    String? logoPath,
    bool clearLogoPath = false,
    double? logoSize,
    double? logoOpacity,
    String? logoPosition,

    double? fontSize,
    int? colorValue,
    String? fontFamily,
    bool? bold,
    bool? italic,
    bool? textShadow,
    bool? textOutline,
    int? outlineColorValue,
    double? outlineWidth,
    String? textAlignment,
    double? lineSpacing,

    int? backgroundColorValue,
    double? backgroundOpacity,
    double? backgroundPadding,
    double? backgroundRadius,

    String? position,
    double? margin,
    List<String>? contentOrder,

    int? imageQuality,
  }) {
    return WatermarkSettings(
      showDateTime: showDateTime ?? this.showDateTime,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      timeZone: timeZone ?? this.timeZone,

      showAddress: showAddress ?? this.showAddress,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showAltitude: showAltitude ?? this.showAltitude,
      showAccuracy: showAccuracy ?? this.showAccuracy,
      showSpeed: showSpeed ?? this.showSpeed,
      showCompass: showCompass ?? this.showCompass,
      coordinatesFormat: coordinatesFormat ?? this.coordinatesFormat,
      addressFormat: addressFormat ?? this.addressFormat,

      showMap: showMap ?? this.showMap,
      mapSize: mapSize ?? this.mapSize,
      mapOpacity: mapOpacity ?? this.mapOpacity,
      mapPosition: mapPosition ?? this.mapPosition,

      showCustomText: showCustomText ?? this.showCustomText,
      customText: customText ?? this.customText,

      showLabel: showLabel ?? this.showLabel,
      labelText: labelText ?? this.labelText,
      showNote: showNote ?? this.showNote,
      noteText: noteText ?? this.noteText,

      showSequence: showSequence ?? this.showSequence,
      sequenceStart: sequenceStart ?? this.sequenceStart,
      sequenceDigits: sequenceDigits ?? this.sequenceDigits,
      sequencePrefix: sequencePrefix ?? this.sequencePrefix,
      sequenceSuffix: sequenceSuffix ?? this.sequenceSuffix,

      showLogo: showLogo ?? this.showLogo,
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      logoSize: logoSize ?? this.logoSize,
      logoOpacity: logoOpacity ?? this.logoOpacity,
      logoPosition: logoPosition ?? this.logoPosition,

      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      textShadow: textShadow ?? this.textShadow,
      textOutline: textOutline ?? this.textOutline,
      outlineColorValue: outlineColorValue ?? this.outlineColorValue,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      textAlignment: textAlignment ?? this.textAlignment,
      lineSpacing: lineSpacing ?? this.lineSpacing,

      backgroundColorValue:
          backgroundColorValue ?? this.backgroundColorValue,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundPadding: backgroundPadding ?? this.backgroundPadding,
      backgroundRadius: backgroundRadius ?? this.backgroundRadius,

      position: position ?? this.position,
      margin: margin ?? this.margin,
      contentOrder: contentOrder ?? this.contentOrder,

      imageQuality: imageQuality ?? this.imageQuality,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showDateTime': showDateTime,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'timeZone': timeZone,

      'showAddress': showAddress,
      'showCoordinates': showCoordinates,
      'showAltitude': showAltitude,
      'showAccuracy': showAccuracy,
      'showSpeed': showSpeed,
      'showCompass': showCompass,
      'coordinatesFormat': coordinatesFormat,
      'addressFormat': addressFormat,

      'showMap': showMap,
      'mapSize': mapSize,
      'mapOpacity': mapOpacity,
      'mapPosition': mapPosition,

      'showCustomText': showCustomText,
      'customText': customText,

      'showLabel': showLabel,
      'labelText': labelText,
      'showNote': showNote,
      'noteText': noteText,

      'showSequence': showSequence,
      'sequenceStart': sequenceStart,
      'sequenceDigits': sequenceDigits,
      'sequencePrefix': sequencePrefix,
      'sequenceSuffix': sequenceSuffix,

      'showLogo': showLogo,
      'logoPath': logoPath,
      'logoSize': logoSize,
      'logoOpacity': logoOpacity,
      'logoPosition': logoPosition,

      'fontSize': fontSize,
      'colorValue': colorValue,
      'fontFamily': fontFamily,
      'bold': bold,
      'italic': italic,
      'textShadow': textShadow,
      'textOutline': textOutline,
      'outlineColorValue': outlineColorValue,
      'outlineWidth': outlineWidth,
      'textAlignment': textAlignment,
      'lineSpacing': lineSpacing,

      'backgroundColorValue': backgroundColorValue,
      'backgroundOpacity': backgroundOpacity,
      'backgroundPadding': backgroundPadding,
      'backgroundRadius': backgroundRadius,

      'position': position,
      'margin': margin,
      'contentOrder': contentOrder,

      'imageQuality': imageQuality,
    };
  }

  factory WatermarkSettings.fromMap(Map<String, dynamic> map) {
    double readDouble(String key, double fallback) {
      final value = map[key];
      return value is num ? value.toDouble() : fallback;
    }

    int readInt(String key, int fallback) {
      final value = map[key];
      return value is num ? value.toInt() : fallback;
    }

    bool readBool(String key, bool fallback) {
      final value = map[key];
      return value is bool ? value : fallback;
    }

    String readString(String key, String fallback) {
      final value = map[key];
      return value is String ? value : fallback;
    }

    List<String> readStringList(
      String key,
      List<String> fallback,
    ) {
      final value = map[key];

      if (value is List) {
        return value.whereType<String>().toList();
      }

      return fallback;
    }

    return WatermarkSettings(
      showDateTime: readBool('showDateTime', true),
      dateFormat: readString('dateFormat', 'dd/MM/yyyy'),
      timeFormat: readString('timeFormat', 'HH:mm:ss'),
      timeZone: readString('timeZone', 'local'),

      showAddress: readBool('showAddress', true),
      showCoordinates: readBool('showCoordinates', true),
      showAltitude: readBool('showAltitude', false),
      showAccuracy: readBool('showAccuracy', false),
      showSpeed: readBool('showSpeed', false),
      showCompass: readBool('showCompass', false),
      coordinatesFormat: readString('coordinatesFormat', 'decimal'),
      addressFormat: readString('addressFormat', 'full'),

      showMap: readBool('showMap', false),
      mapSize: readDouble('mapSize', 120),
      mapOpacity: readDouble('mapOpacity', 1),
      mapPosition: readString('mapPosition', 'topRight'),

      showCustomText: readBool('showCustomText', true),
      customText: readString('customText', ''),

      showLabel: readBool('showLabel', false),
      labelText: readString('labelText', ''),
      showNote: readBool('showNote', false),
      noteText: readString('noteText', ''),

      showSequence: readBool('showSequence', false),
      sequenceStart: readInt('sequenceStart', 1),
      sequenceDigits: readInt('sequenceDigits', 3),
      sequencePrefix: readString('sequencePrefix', ''),
      sequenceSuffix: readString('sequenceSuffix', ''),

      showLogo: readBool('showLogo', false),
      logoPath: map['logoPath'] is String
          ? map['logoPath'] as String
          : null,
      logoSize: readDouble('logoSize', 80),
      logoOpacity: readDouble('logoOpacity', 1),
      logoPosition: readString('logoPosition', 'topLeft'),

      fontSize: readDouble('fontSize', 16),
      colorValue: readInt('colorValue', 0xFFFFFFFF),
      fontFamily: readString('fontFamily', 'Roboto'),
      bold: readBool('bold', false),
      italic: readBool('italic', false),
      textShadow: readBool('textShadow', true),
      textOutline: readBool('textOutline', false),
      outlineColorValue: readInt('outlineColorValue', 0xFF000000),
      outlineWidth: readDouble('outlineWidth', 1),
      textAlignment: readString('textAlignment', 'left'),
      lineSpacing: readDouble('lineSpacing', 1.2),

      backgroundColorValue:
          readInt('backgroundColorValue', 0xFF000000),
      backgroundOpacity: readDouble('backgroundOpacity', 0),
      backgroundPadding: readDouble('backgroundPadding', 8),
      backgroundRadius: readDouble('backgroundRadius', 8),

      position: readString('position', 'bottomRight'),
      margin: readDouble('margin', 16),

      contentOrder: readStringList(
        'contentOrder',
        const [
          'dateTime',
          'address',
          'coordinates',
          'altitude',
          'accuracy',
          'speed',
          'compass',
          'sequence',
          'label',
          'customText',
          'note',
        ],
      ),

      imageQuality: readInt('imageQuality', 95),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WatermarkSettings.fromJson(String source) {
    final decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'La configuración de marca de agua no es válida.',
      );
    }

    return WatermarkSettings.fromMap(decoded);
  }
}
