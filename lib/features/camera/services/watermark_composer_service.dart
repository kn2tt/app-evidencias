
import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/watermark_settings.dart';
import 'location_service.dart';

class WatermarkComposerService {
  Future<File> compose({
    required String imagePath,
    required WatermarkSettings settings,
    LocationData? location,
    required int sequenceNumber,
    double? heading,
  }) async {
    final originalFile = File(imagePath);

    if (!await originalFile.exists()) {
      throw Exception('No se encontró la fotografía original.');
    }

    final originalBytes = await originalFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(originalBytes);

    ui.Image? originalImage;
    ui.Image? composedImage;

    try {
      final frame = await codec.getNextFrame();
      originalImage = frame.image;

      final width = originalImage.width;
      final height = originalImage.height;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(
          0,
          0,
          width.toDouble(),
          height.toDouble(),
        ),
      );

      final fullRect = ui.Rect.fromLTWH(
        0,
        0,
        width.toDouble(),
        height.toDouble(),
      );

      canvas.drawImageRect(
        originalImage,
        ui.Rect.fromLTWH(
          0,
          0,
          width.toDouble(),
          height.toDouble(),
        ),
        fullRect,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );

      if (settings.showLogo &&
          settings.logoPath != null &&
          await File(settings.logoPath!).exists()) {
        await _drawLogo(
          canvas: canvas,
          imagePath: settings.logoPath!,
          settings: settings,
          width: width.toDouble(),
          height: height.toDouble(),
        );
      }

      final lines = buildLines(
        settings: settings,
        location: location,
        sequenceNumber: sequenceNumber,
        heading: heading,
      );

      if (lines.isNotEmpty) {
        _drawText(
          canvas: canvas,
          lines: lines,
          settings: settings,
          width: width.toDouble(),
          height: height.toDouble(),
        );
      }

      final picture = recorder.endRecording();

      try {
        composedImage = await picture.toImage(width, height);
      } finally {
        picture.dispose();
      }

      final pngData = await composedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (pngData == null) {
        throw Exception('No se pudo generar la imagen procesada.');
      }

      final decoded = img.decodeImage(
        pngData.buffer.asUint8List(),
      );

      if (decoded == null) {
        throw Exception('No se pudo codificar la fotografía.');
      }

      final jpgBytes = img.encodeJpg(
        decoded,
        quality: settings.imageQuality.clamp(60, 100),
      );

      final directory = await getApplicationDocumentsDirectory();

      final photosDirectory = Directory(
        '${directory.path}/evidencias',
      );

      if (!await photosDirectory.exists()) {
        await photosDirectory.create(recursive: true);
      }

      final timestamp = DateTime.now().microsecondsSinceEpoch;

      final outputFile = File(
        '${photosDirectory.path}/evidencia_$timestamp.jpg',
      );

      await outputFile.writeAsBytes(
        jpgBytes,
        flush: true,
      );

      return outputFile;
    } finally {
      originalImage?.dispose();
      composedImage?.dispose();
      codec.dispose();
    }
  }

  List<String> buildLines({
    required WatermarkSettings settings,
    required LocationData? location,
    required int sequenceNumber,
    double? heading,
  }) {
    final values = <String, String>{};

    if (settings.showDateTime) {
      final now = settings.timeZone == 'UTC'
          ? DateTime.now().toUtc()
          : DateTime.now();

      final date = DateFormat(settings.dateFormat).format(now);
      final time = DateFormat(settings.timeFormat).format(now);

      values['dateTime'] = '$date $time';
    }

    if (settings.showAddress && location != null) {
      values['address'] = location.address;
    }

    if (settings.showCoordinates && location != null) {
      values['coordinates'] =
          settings.coordinatesFormat == 'dms'
              ? '${_toDms(location.latitude, true)}, '
                  '${_toDms(location.longitude, false)}'
              : '${location.latitude.toStringAsFixed(6)}, '
                  '${location.longitude.toStringAsFixed(6)}';
    }

    if (settings.showAltitude && location != null) {
      values['altitude'] =
          'Altitud: ${location.altitude.toStringAsFixed(1)} m';
    }

    if (settings.showAccuracy && location != null) {
      values['accuracy'] =
          'Precisión: ${location.accuracy.toStringAsFixed(1)} m';
    }

    if (settings.showSpeed && location != null) {
      final speedKmh = location.speed * 3.6;
      values['speed'] =
          'Velocidad: ${speedKmh.toStringAsFixed(1)} km/h';
    }

    if (settings.showCompass &&
        heading != null &&
        heading.isFinite) {
      const directions = [
        'N',
        'NE',
        'E',
        'SE',
        'S',
        'SO',
        'O',
        'NO',
      ];

      final normalizedHeading = (heading + 360) % 360;

      final directionIndex =
          ((normalizedHeading + 22.5) / 45).floor() % 8;

      values['compass'] =
          'Brújula: ${directions[directionIndex]} '
          '(${normalizedHeading.toStringAsFixed(0)}°)';
    }

    if (settings.showSequence) {
      final number = sequenceNumber
          .toString()
          .padLeft(settings.sequenceDigits, '0');

      values['sequence'] =
          '${settings.sequencePrefix}$number'
          '${settings.sequenceSuffix}';
    }

    if (settings.showLabel &&
        settings.labelText.trim().isNotEmpty) {
      values['label'] = settings.labelText.trim();
    }

    if (settings.showCustomText &&
        settings.customText.trim().isNotEmpty) {
      values['customText'] = settings.customText.trim();
    }

    if (settings.showNote &&
        settings.noteText.trim().isNotEmpty) {
      values['note'] = settings.noteText.trim();
    }

    final orderedLines = <String>[];

    for (final key in settings.contentOrder) {
      final value = values.remove(key);

      if (value != null && value.isNotEmpty) {
        orderedLines.add(value);
      }
    }

    for (final value in values.values) {
      if (value.isNotEmpty) {
        orderedLines.add(value);
      }
    }

    return orderedLines;
  }

  void _drawText({
    required ui.Canvas canvas,
    required List<String> lines,
    required WatermarkSettings settings,
    required double width,
    required double height,
  }) {
    final fontSize = settings.fontSize.clamp(10, 100).toDouble();

    final textColor = Color(settings.colorValue);
    final backgroundColor = Color(settings.backgroundColorValue);
    final outlineColor = Color(settings.outlineColorValue);

    final alignment = switch (settings.textAlignment) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

    const textDirection = ui.TextDirection.ltr;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontFamily: settings.fontFamily,
      fontWeight:
          settings.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle:
          settings.italic ? FontStyle.italic : FontStyle.normal,
      height: settings.lineSpacing,
    );

    final maxTextWidth = width * 0.85;

    final textPainter = TextPainter(
      text: TextSpan(
        children: lines.map((line) {
          return TextSpan(
            text: '$line\n',
            style: textStyle,
          );
        }).toList(),
      ),
      textDirection: textDirection,
      textAlign: alignment,
    );

    textPainter.layout(maxWidth: maxTextWidth);

    final padding = settings.backgroundPadding
        .clamp(0, 100)
        .toDouble();

    final margin = settings.margin
        .clamp(0, 200)
        .toDouble();

    final contentWidth = textPainter.width + padding * 2;
    final contentHeight = textPainter.height + padding * 2;

    double left;

    if (settings.position.endsWith('Left')) {
      left = margin;
    } else if (settings.position.endsWith('Right')) {
      left = width - contentWidth - margin;
    } else {
      left = (width - contentWidth) / 2;
    }

    double top;

    if (settings.position.startsWith('top')) {
      top = margin;
    } else if (settings.position.startsWith('bottom')) {
      top = height - contentHeight - margin;
    } else {
      top = (height - contentHeight) / 2;
    }

    final maxLeft = (width - contentWidth).clamp(0.0, width);
    final maxTop = (height - contentHeight).clamp(0.0, height);

    left = left.clamp(0.0, maxLeft);
    top = top.clamp(0.0, maxTop);

    final contentRect = ui.Rect.fromLTWH(
      left,
      top,
      contentWidth,
      contentHeight,
    );

    if (settings.backgroundOpacity > 0) {
      final backgroundPaint = ui.Paint()
        ..color = backgroundColor.withValues(
          alpha: settings.backgroundOpacity.clamp(0.0, 1.0),
        );

      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          contentRect,
          ui.Radius.circular(
            settings.backgroundRadius.clamp(0, 100).toDouble(),
          ),
        ),
        backgroundPaint,
      );
    }

    final textOffset = ui.Offset(
      left + padding,
      top + padding,
    );

    if (settings.textShadow) {
      final shadowPainter = TextPainter(
        text: TextSpan(
          children: lines.map((line) {
            return TextSpan(
              text: '$line\n',
              style: textStyle.copyWith(
                color: Colors.black.withValues(alpha: 0.85),
              ),
            );
          }).toList(),
        ),
        textDirection: textDirection,
        textAlign: alignment,
      );

      shadowPainter.layout(maxWidth: maxTextWidth);

      shadowPainter.paint(
        canvas,
        textOffset + const ui.Offset(2, 2),
      );
    }

    if (settings.textOutline) {
      final outlinePainter = TextPainter(
        text: TextSpan(
          children: lines.map((line) {
            return TextSpan(
              text: '$line\n',
              style: textStyle.copyWith(
                foreground: ui.Paint()
                  ..style = ui.PaintingStyle.stroke
                  ..strokeWidth =
                      settings.outlineWidth.clamp(0.5, 10).toDouble()
                  ..color = outlineColor,
              ),
            );
          }).toList(),
        ),
        textDirection: textDirection,
        textAlign: alignment,
      );

      outlinePainter.layout(maxWidth: maxTextWidth);
      outlinePainter.paint(canvas, textOffset);
    }

    textPainter.paint(canvas, textOffset);
  }

  Future<void> _drawLogo({
    required ui.Canvas canvas,
    required String imagePath,
    required WatermarkSettings settings,
    required double width,
    required double height,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);

    ui.Image? logo;

    try {
      final frame = await codec.getNextFrame();
      logo = frame.image;

      final logoWidth = settings.logoSize.clamp(30, 500).toDouble();
      final aspectRatio = logo.width / logo.height;
      final logoHeight = logoWidth / aspectRatio;

      final margin = settings.margin.clamp(0, 200).toDouble();

      double left;
      double top;

      if (settings.logoPosition.endsWith('Left')) {
        left = margin;
      } else {
        left = width - logoWidth - margin;
      }

      if (settings.logoPosition.startsWith('top')) {
        top = margin;
      } else {
        top = height - logoHeight - margin;
      }

      final maxLeft = (width - logoWidth).clamp(0.0, width);
      final maxTop = (height - logoHeight).clamp(0.0, height);

      left = left.clamp(0.0, maxLeft);
      top = top.clamp(0.0, maxTop);

      final paint = ui.Paint()
        ..color = Colors.white.withValues(
          alpha: settings.logoOpacity.clamp(0.0, 1.0),
        )
        ..filterQuality = ui.FilterQuality.high;

      canvas.drawImageRect(
        logo,
        ui.Rect.fromLTWH(
          0,
          0,
          logo.width.toDouble(),
          logo.height.toDouble(),
        ),
        ui.Rect.fromLTWH(
          left,
          top,
          logoWidth,
          logoHeight,
        ),
        paint,
      );
    } finally {
      logo?.dispose();
      codec.dispose();
    }
  }

  String _toDms(double coordinate, bool latitude) {
    final absolute = coordinate.abs();

    final degrees = absolute.floor();
    final minutesValue = (absolute - degrees) * 60;
    final minutes = minutesValue.floor();
    final seconds = (minutesValue - minutes) * 60;

    final direction = latitude
        ? (coordinate >= 0 ? 'N' : 'S')
        : (coordinate >= 0 ? 'E' : 'O');

    return '$degrees° $minutes\' '
        '${seconds.toStringAsFixed(2)}" $direction';
  }
}
