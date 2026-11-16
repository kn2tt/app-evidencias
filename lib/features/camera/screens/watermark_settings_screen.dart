
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../models/watermark_settings.dart';
import '../services/watermark_settings_service.dart';
import '../widgets/watermark_order_dialog.dart';

class WatermarkSettingsScreen extends StatefulWidget {
  final WatermarkSettings initialSettings;

  const WatermarkSettingsScreen({
    super.key,
    required this.initialSettings,
  });

  @override
  State<WatermarkSettingsScreen> createState() =>
      _WatermarkSettingsScreenState();
}

class _WatermarkSettingsScreenState
    extends State<WatermarkSettingsScreen> {
  final WatermarkSettingsService _service =
      WatermarkSettingsService();

  final ImagePicker _imagePicker = ImagePicker();

  late WatermarkSettings _settings;

  late final TextEditingController _customTextController;
  late final TextEditingController _labelController;
  late final TextEditingController _noteController;
  late final TextEditingController _sequenceStartController;
  late final TextEditingController _sequencePrefixController;
  late final TextEditingController _sequenceSuffixController;

  bool _saving = false;

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    const Color(0xFF2563EB),
    const Color(0xFF22C55E),
    const Color(0xFFFFD700),
    const Color(0xFFFF5252),
    const Color(0xFF06B6D4),
    const Color(0xFFF97316),
  ];

  final List<Color> _backgroundColors = [
    Colors.black,
    Colors.white,
    const Color(0xFF1E293B),
    const Color(0xFF2563EB),
    const Color(0xFF0F766E),
  ];

  @override
  void initState() {
    super.initState();

    _settings = widget.initialSettings;

    _customTextController =
        TextEditingController(text: _settings.customText);
    _labelController =
        TextEditingController(text: _settings.labelText);
    _noteController =
        TextEditingController(text: _settings.noteText);
    _sequenceStartController =
        TextEditingController(text: _settings.sequenceStart.toString());
    _sequencePrefixController =
        TextEditingController(text: _settings.sequencePrefix);
    _sequenceSuffixController =
        TextEditingController(text: _settings.sequenceSuffix);
  }

  void _update(WatermarkSettings updated) {
    setState(() {
      _settings = updated;
    });
  }

  Future<void> _openContentOrder() async {
    final result = await showWatermarkOrderDialog(
      context: context,
      currentOrder: _settings.contentOrder,
    );

    if (result == null || !mounted) return;

    _update(
      _settings.copyWith(contentOrder: result),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null || !mounted) return;

      _update(_settings.copyWith(
        logoPath: image.path,
        showLogo: true,
      ));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo seleccionar el logotipo.'),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final updatedSettings = _settings.copyWith(
        customText: _customTextController.text.trim(),
        labelText: _labelController.text.trim(),
        noteText: _noteController.text.trim(),
        sequenceStart:
            int.tryParse(_sequenceStartController.text) ??
                _settings.sequenceStart,
        sequencePrefix: _sequencePrefixController.text,
        sequenceSuffix: _sequenceSuffixController.text,
      );

      await _service.save(updatedSettings);

      if (!mounted) return;

      Navigator.of(context).pop(updatedSettings);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la configuración.'),
        ),
      );
    }
  }

  Widget _sectionTitle(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _switch({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      activeThumbColor: AppTheme.primaryColor,
      onChanged: onChanged,
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          activeColor: AppTheme.primaryColor,
          onChanged: onChanged,
        ),
        Text(
          valueLabel,
          style: const TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLength = 100,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _colorSelector({
    required String title,
    required int selectedColor,
    required List<Color> colors,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: colors.map((color) {
            final value = color.toARGB32();
            final selected = selectedColor == value;

            return GestureDetector(
              onTap: () => onSelected(value),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: color == Colors.white
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<String> _buildPreviewLines() {
    final values = <String, String?>{
      'customText': _settings.showCustomText &&
              _customTextController.text.trim().isNotEmpty
          ? _customTextController.text.trim()
          : null,
      'address': _settings.showAddress
          ? 'Av. Ejemplo, Lima, Perú'
          : null,
      'coordinates': _settings.showCoordinates
          ? '-12.046374, -77.042793'
          : null,
      'altitude': _settings.showAltitude
          ? 'Altitud: 150 m'
          : null,
      'speed': _settings.showSpeed
          ? 'Velocidad: 0 km/h'
          : null,
      'dateTime': _settings.showDateTime
          ? '15/11/2026 14:30:45'
          : null,
      'compass': _settings.showCompass
          ? 'Orientación: NE'
          : null,
      'label': _settings.showLabel &&
              _labelController.text.trim().isNotEmpty
          ? _labelController.text.trim()
          : null,
      'sequence': _settings.showSequence
          ? '${_settings.sequencePrefix}'
              '${_settings.sequenceStart.toString().padLeft(_settings.sequenceDigits, '0')}'
              '${_settings.sequenceSuffix}'
          : null,
      'accuracy': _settings.showAccuracy
          ? 'Precisión: 5 m'
          : null,
      'note': _settings.showNote &&
              _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    };

    final lines = <String>[];

    for (final key in _settings.contentOrder) {
      final value = values[key];

      if (value != null && value.isNotEmpty) {
        lines.add(value);
      }
    }

    for (final entry in values.entries) {
      if (!_settings.contentOrder.contains(entry.key) &&
          entry.value != null &&
          entry.value!.isNotEmpty) {
        lines.add(entry.value!);
      }
    }

    return lines;
  }

  Widget _buildPreview() {
    final lines = _buildPreviewLines();

    final textColor = Color(_settings.colorValue);
    final backgroundColor =
        Color(_settings.backgroundColorValue);

    final alignment = _settings.textAlignment == 'center'
        ? TextAlign.center
        : _settings.textAlignment == 'right'
            ? TextAlign.right
            : TextAlign.left;

    final crossAlignment =
        _settings.textAlignment == 'center'
            ? CrossAxisAlignment.center
            : _settings.textAlignment == 'right'
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF475569),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/camera_preview.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF64748B),
                        Color(0xFF334155),
                        Color(0xFF1E293B),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 60,
                      color: Colors.white24,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_settings.showLogo &&
              _settings.logoPath != null)
            Positioned(
              left: _settings.logoPosition.endsWith('Left')
                  ? 12
                  : null,
              right: _settings.logoPosition.endsWith('Right')
                  ? 12
                  : null,
              top: _settings.logoPosition.startsWith('top')
                  ? 12
                  : null,
              bottom: _settings.logoPosition.startsWith('bottom')
                  ? 12
                  : null,
              child: Opacity(
                opacity: _settings.logoOpacity.clamp(0, 1),
                child: Image.file(
                  File(_settings.logoPath!),
                  width: _settings.logoSize.clamp(30, 180),
                  height: _settings.logoSize.clamp(30, 180),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          if (lines.isNotEmpty)
            Positioned(
              left: _settings.position.endsWith('Left')
                  ? _settings.margin
                  : null,
              right: _settings.position.endsWith('Right')
                  ? _settings.margin
                  : null,
              top: _settings.position.startsWith('top')
                  ? _settings.margin
                  : null,
              bottom: _settings.position.startsWith('bottom')
                  ? _settings.margin
                  : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 260,
                ),
                child: Container(
                  padding: EdgeInsets.all(
                    _settings.backgroundPadding.clamp(0, 30),
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor.withValues(
                      alpha: _settings.backgroundOpacity
                          .clamp(0, 1),
                    ),
                    borderRadius: BorderRadius.circular(
                      _settings.backgroundRadius.clamp(0, 30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: crossAlignment,
                    mainAxisSize: MainAxisSize.min,
                    children: lines.map((line) {
                      return Text(
                        line,
                        textAlign: alignment,
                        style: TextStyle(
                          color: textColor,
                          fontSize:
                              _settings.fontSize.clamp(10, 28),
                          fontFamily: _settings.fontFamily,
                          fontWeight: _settings.bold
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontStyle: _settings.italic
                              ? FontStyle.italic
                              : FontStyle.normal,
                          height: _settings.lineSpacing,
                          shadows: _settings.textShadow
                              ? const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 4,
                                    offset: Offset(1, 1),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          if (lines.isEmpty)
            const Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Text(
                'Activa algún elemento para visualizarlo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _expansionSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.borderColor,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        expandedCrossAxisAlignment:
            CrossAxisAlignment.start,
        children: [child],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      children: [
        _switch(
          title: 'Mostrar fecha y hora',
          value: _settings.showDateTime,
          onChanged: (v) => _update(
            _settings.copyWith(showDateTime: v),
          ),
        ),
        _dropdown<String>(
          label: 'Formato de fecha',
          value: _settings.dateFormat,
          items: const [
            DropdownMenuItem(
              value: 'dd/MM/yyyy',
              child: Text('15/11/2026'),
            ),
            DropdownMenuItem(
              value: 'MM/dd/yyyy',
              child: Text('11/15/2026'),
            ),
            DropdownMenuItem(
              value: 'yyyy-MM-dd',
              child: Text('2026-11-15'),
            ),
            DropdownMenuItem(
              value: 'dd-MM-yyyy',
              child: Text('15-11-2026'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(dateFormat: v));
            }
          },
        ),
        const SizedBox(height: 12),
        _dropdown<String>(
          label: 'Formato de hora',
          value: _settings.timeFormat,
          items: const [
            DropdownMenuItem(
              value: 'HH:mm:ss',
              child: Text('24 horas (14:30:45)'),
            ),
            DropdownMenuItem(
              value: 'hh:mm:ss a',
              child: Text('12 horas (02:30:45 PM)'),
            ),
            DropdownMenuItem(
              value: 'HH:mm',
              child: Text('24 horas (14:30)'),
            ),
            DropdownMenuItem(
              value: 'hh:mm a',
              child: Text('12 horas (02:30 PM)'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(timeFormat: v));
            }
          },
        ),
        const SizedBox(height: 12),
        _dropdown<String>(
          label: 'Zona horaria',
          value: _settings.timeZone,
          items: const [
            DropdownMenuItem(
              value: 'local',
              child: Text('Hora local del dispositivo'),
            ),
            DropdownMenuItem(
              value: 'UTC',
              child: Text('UTC'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(timeZone: v));
            }
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        _switch(
          title: 'Dirección',
          subtitle: 'Mostrar la dirección obtenida mediante GPS.',
          value: _settings.showAddress,
          onChanged: (v) => _update(
            _settings.copyWith(showAddress: v),
          ),
        ),
        _switch(
          title: 'Coordenadas GPS',
          value: _settings.showCoordinates,
          onChanged: (v) => _update(
            _settings.copyWith(showCoordinates: v),
          ),
        ),
        _dropdown<String>(
          label: 'Formato de coordenadas',
          value: _settings.coordinatesFormat,
          items: const [
            DropdownMenuItem(
              value: 'decimal',
              child: Text('Decimal'),
            ),
            DropdownMenuItem(
              value: 'dms',
              child: Text('Grados, minutos y segundos'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(
                _settings.copyWith(coordinatesFormat: v),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _dropdown<String>(
          label: 'Formato de dirección',
          value: _settings.addressFormat,
          items: const [
            DropdownMenuItem(
              value: 'full',
              child: Text('Dirección completa'),
            ),
            DropdownMenuItem(
              value: 'short',
              child: Text('Dirección resumida'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(
                _settings.copyWith(addressFormat: v),
              );
            }
          },
        ),
        const Divider(height: 24),
        _switch(
          title: 'Altitud',
          value: _settings.showAltitude,
          onChanged: (v) => _update(
            _settings.copyWith(showAltitude: v),
          ),
        ),
        _switch(
          title: 'Precisión GPS',
          value: _settings.showAccuracy,
          onChanged: (v) => _update(
            _settings.copyWith(showAccuracy: v),
          ),
        ),
        _switch(
          title: 'Velocidad',
          value: _settings.showSpeed,
          onChanged: (v) => _update(
            _settings.copyWith(showSpeed: v),
          ),
        ),
      ],
    );
  }

  Widget _buildCompassSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _switch(
          title: 'Mostrar orientación / brújula',
          subtitle:
              'Incluir el punto cardinal y los grados de orientación en la fotografía.',
          value: _settings.showCompass,
          onChanged: (v) => _update(
            _settings.copyWith(showCompass: v),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.explore_outlined,
                size: 32,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'La orientación se obtiene mediante los sensores del dispositivo.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      children: [
        _switch(
          title: 'Mostrar mapa',
          subtitle: 'Incluir un mapa de la ubicación.',
          value: _settings.showMap,
          onChanged: (v) => _update(
            _settings.copyWith(showMap: v),
          ),
        ),
        _slider(
          label: 'Tamaño del mapa',
          value: _settings.mapSize,
          min: 60,
          max: 200,
          divisions: 14,
          valueLabel: '${_settings.mapSize.round()} px',
          onChanged: (v) => _update(
            _settings.copyWith(mapSize: v),
          ),
        ),
        _slider(
          label: 'Opacidad del mapa',
          value: _settings.mapOpacity,
          min: 0.1,
          max: 1,
          divisions: 9,
          valueLabel:
              '${(_settings.mapOpacity * 100).round()}%',
          onChanged: (v) => _update(
            _settings.copyWith(mapOpacity: v),
          ),
        ),
        _dropdown<String>(
          label: 'Posición del mapa',
          value: _settings.mapPosition,
          items: const [
            DropdownMenuItem(
              value: 'topLeft',
              child: Text('Superior izquierda'),
            ),
            DropdownMenuItem(
              value: 'topRight',
              child: Text('Superior derecha'),
            ),
            DropdownMenuItem(
              value: 'bottomLeft',
              child: Text('Inferior izquierda'),
            ),
            DropdownMenuItem(
              value: 'bottomRight',
              child: Text('Inferior derecha'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(mapPosition: v));
            }
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'La incorporación del mapa real se conectará al procesamiento de la fotografía.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextSection() {
    return Column(
      children: [
        _switch(
          title: 'Texto personalizado',
          value: _settings.showCustomText,
          onChanged: (v) => _update(
            _settings.copyWith(showCustomText: v),
          ),
        ),
        _textField(
          label: 'Texto personalizado',
          controller: _customTextController,
          hint: 'Ej. Proyecto, cliente o ubicación',
        ),
        const Divider(height: 28),
        _switch(
          title: 'Mostrar etiqueta',
          value: _settings.showLabel,
          onChanged: (v) => _update(
            _settings.copyWith(showLabel: v),
          ),
        ),
        _textField(
          label: 'Etiqueta',
          controller: _labelController,
          hint: 'Ej. SITE: LIMA-001',
        ),
        const Divider(height: 28),
        _switch(
          title: 'Mostrar nota',
          value: _settings.showNote,
          onChanged: (v) => _update(
            _settings.copyWith(showNote: v),
          ),
        ),
        _textField(
          label: 'Nota',
          controller: _noteController,
          hint: 'Escribe una observación',
          maxLength: 250,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSequenceSection() {
    return Column(
      children: [
        _switch(
          title: 'Numeración de fotografías',
          subtitle:
              'Mostrar un número consecutivo en cada fotografía.',
          value: _settings.showSequence,
          onChanged: (v) => _update(
            _settings.copyWith(showSequence: v),
          ),
        ),
        _textField(
          label: 'Número inicial',
          controller: _sequenceStartController,
          hint: '1',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _textField(
          label: 'Prefijo',
          controller: _sequencePrefixController,
          hint: 'Ej. FOTO-',
        ),
        const SizedBox(height: 12),
        _textField(
          label: 'Sufijo',
          controller: _sequenceSuffixController,
          hint: 'Ej. -SITE',
        ),
        const SizedBox(height: 12),
        _dropdown<int>(
          label: 'Cantidad de dígitos',
          value: _settings.sequenceDigits,
          items: const [
            DropdownMenuItem(
              value: 1,
              child: Text('1 dígito (1)'),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('2 dígitos (01)'),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('3 dígitos (001)'),
            ),
            DropdownMenuItem(
              value: 4,
              child: Text('4 dígitos (0001)'),
            ),
            DropdownMenuItem(
              value: 5,
              child: Text('5 dígitos (00001)'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(
                _settings.copyWith(sequenceDigits: v),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _switch(
          title: 'Incluir logotipo',
          value: _settings.showLogo,
          onChanged: (v) => _update(
            _settings.copyWith(showLogo: v),
          ),
        ),
        if (_settings.logoPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.image_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _settings.logoPath!.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar logotipo',
                  onPressed: () {
                    _update(_settings.copyWith(
                      clearLogoPath: true,
                      showLogo: false,
                    ));
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: _pickLogo,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Seleccionar logotipo'),
        ),
        const SizedBox(height: 12),
        _slider(
          label: 'Tamaño del logotipo',
          value: _settings.logoSize,
          min: 30,
          max: 180,
          divisions: 15,
          valueLabel: '${_settings.logoSize.round()} px',
          onChanged: (v) => _update(
            _settings.copyWith(logoSize: v),
          ),
        ),
        _slider(
          label: 'Opacidad del logotipo',
          value: _settings.logoOpacity,
          min: 0.1,
          max: 1,
          divisions: 9,
          valueLabel:
              '${(_settings.logoOpacity * 100).round()}%',
          onChanged: (v) => _update(
            _settings.copyWith(logoOpacity: v),
          ),
        ),
        _dropdown<String>(
          label: 'Posición del logotipo',
          value: _settings.logoPosition,
          items: const [
            DropdownMenuItem(
              value: 'topLeft',
              child: Text('Superior izquierda'),
            ),
            DropdownMenuItem(
              value: 'topRight',
              child: Text('Superior derecha'),
            ),
            DropdownMenuItem(
              value: 'bottomLeft',
              child: Text('Inferior izquierda'),
            ),
            DropdownMenuItem(
              value: 'bottomRight',
              child: Text('Inferior derecha'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(
                _settings.copyWith(logoPosition: v),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slider(
          label: 'Tamaño del texto',
          value: _settings.fontSize,
          min: 10,
          max: 28,
          divisions: 9,
          valueLabel: '${_settings.fontSize.round()} px',
          onChanged: (v) => _update(
            _settings.copyWith(fontSize: v),
          ),
        ),
        const SizedBox(height: 16),
        _colorSelector(
          title: 'Color de fuente',
          selectedColor: _settings.colorValue,
          colors: _colors,
          onSelected: (v) => _update(
            _settings.copyWith(colorValue: v),
          ),
        ),
        const SizedBox(height: 20),
        _colorSelector(
          title: 'Color de fondo',
          selectedColor: _settings.backgroundColorValue,
          colors: _backgroundColors,
          onSelected: (v) => _update(
            _settings.copyWith(backgroundColorValue: v),
          ),
        ),
        const SizedBox(height: 12),
        _slider(
          label: 'Opacidad del fondo',
          value: _settings.backgroundOpacity,
          min: 0,
          max: 1,
          divisions: 10,
          valueLabel:
              '${(_settings.backgroundOpacity * 100).round()}%',
          onChanged: (v) => _update(
            _settings.copyWith(backgroundOpacity: v),
          ),
        ),
        _slider(
          label: 'Espaciado interno del fondo',
          value: _settings.backgroundPadding,
          min: 0,
          max: 24,
          divisions: 12,
          valueLabel:
              '${_settings.backgroundPadding.round()} px',
          onChanged: (v) => _update(
            _settings.copyWith(backgroundPadding: v),
          ),
        ),
        _slider(
          label: 'Redondeado de esquinas',
          value: _settings.backgroundRadius,
          min: 0,
          max: 24,
          divisions: 12,
          valueLabel:
              '${_settings.backgroundRadius.round()} px',
          onChanged: (v) => _update(
            _settings.copyWith(backgroundRadius: v),
          ),
        ),
        const SizedBox(height: 16),
        _dropdown<String>(
          label: 'Familia tipográfica',
          value: _settings.fontFamily,
          items: const [
            DropdownMenuItem(
              value: 'Roboto',
              child: Text('Roboto'),
            ),
            DropdownMenuItem(
              value: 'Arial',
              child: Text('Arial'),
            ),
            DropdownMenuItem(
              value: 'serif',
              child: Text('Serif'),
            ),
            DropdownMenuItem(
              value: 'monospace',
              child: Text('Monospace'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(
                _settings.copyWith(fontFamily: v),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Estilo de texto',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        _switch(
          title: 'Negrita',
          value: _settings.bold,
          onChanged: (v) => _update(
            _settings.copyWith(bold: v),
          ),
        ),
        _switch(
          title: 'Cursiva',
          value: _settings.italic,
          onChanged: (v) => _update(
            _settings.copyWith(italic: v),
          ),
        ),
        _switch(
          title: 'Sombra del texto',
          value: _settings.textShadow,
          onChanged: (v) => _update(
            _settings.copyWith(textShadow: v),
          ),
        ),
        _switch(
          title: 'Contorno del texto',
          subtitle:
              'Se aplicará al procesar la fotografía.',
          value: _settings.textOutline,
          onChanged: (v) => _update(
            _settings.copyWith(textOutline: v),
          ),
        ),
        _slider(
          label: 'Grosor del contorno',
          value: _settings.outlineWidth,
          min: 0.5,
          max: 4,
          divisions: 7,
          valueLabel:
              _settings.outlineWidth.toStringAsFixed(1),
          onChanged: (v) => _update(
            _settings.copyWith(outlineWidth: v),
          ),
        ),
        _dropdown<String>(
          label: 'Alineación del texto',
          value: _settings.textAlignment,
          items: const [
            DropdownMenuItem(
              value: 'left',
              child: Text('Izquierda'),
            ),
            DropdownMenuItem(
              value: 'center',
              child: Text('Centro'),
            ),
            DropdownMenuItem(
              value: 'right',
              child: Text('Derecha'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(
                _settings.copyWith(textAlignment: v),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _slider(
          label: 'Espaciado entre líneas',
          value: _settings.lineSpacing,
          min: 0.8,
          max: 2,
          divisions: 12,
          valueLabel:
              _settings.lineSpacing.toStringAsFixed(1),
          onChanged: (v) => _update(
            _settings.copyWith(lineSpacing: v),
          ),
        ),
        const SizedBox(height: 16),
        _dropdown<String>(
          label: 'Posición de la marca de agua',
          value: _settings.position,
          items: const [
            DropdownMenuItem(
              value: 'bottomLeft',
              child: Text('Inferior izquierda'),
            ),
            DropdownMenuItem(
              value: 'bottomRight',
              child: Text('Inferior derecha'),
            ),
            DropdownMenuItem(
              value: 'topLeft',
              child: Text('Superior izquierda'),
            ),
            DropdownMenuItem(
              value: 'topRight',
              child: Text('Superior derecha'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(position: v));
            }
          },
        ),
        const SizedBox(height: 12),
        _slider(
          label: 'Margen',
          value: _settings.margin,
          min: 4,
          max: 30,
          divisions: 13,
          valueLabel: '${_settings.margin.round()} px',
          onChanged: (v) => _update(
            _settings.copyWith(margin: v),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        _slider(
          label: 'Calidad de imagen',
          value: _settings.imageQuality.toDouble(),
          min: 60,
          max: 100,
          divisions: 8,
          valueLabel: '${_settings.imageQuality}%',
          onChanged: (v) => _update(
            _settings.copyWith(imageQuality: v.round()),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Una calidad alta conserva más detalles, pero genera archivos de mayor tamaño.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _customTextController.dispose();
    _labelController.dispose();
    _noteController.dispose();
    _sequenceStartController.dispose();
    _sequencePrefixController.dispose();
    _sequenceSuffixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marca de agua'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(
            'Vista previa',
            'Visualiza cómo se organizará la información en tus fotografías.',
          ),
          const SizedBox(height: 12),
          _buildPreview(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _openContentOrder,
              icon: const Icon(Icons.swap_vert),
              label: const Text('Ordenar elementos'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta vista previa es ilustrativa. Los datos reales de captura se incorporarán al conectar la cámara y el procesamiento de fotografías.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(
            'Configuración',
            'Personaliza la información que acompañará a tus fotografías.',
          ),
          const SizedBox(height: 12),
          _expansionSection(
            title: 'Fecha y hora',
            subtitle: 'Formato, hora y zona horaria',
            icon: Icons.calendar_month_outlined,
            child: _buildDateTimeSection(),
          ),
          _expansionSection(
            title: 'Ubicación y GPS',
            subtitle: 'Dirección, coordenadas y datos de captura',
            icon: Icons.location_on_outlined,
            child: _buildLocationSection(),
          ),
          _expansionSection(
            title: 'Orientación y brújula',
            subtitle: 'Punto cardinal y grados de orientación',
            icon: Icons.explore_outlined,
            child: _buildCompassSection(),
          ),
          _expansionSection(
            title: 'Mapa',
            subtitle: 'Tamaño, posición y transparencia',
            icon: Icons.map_outlined,
            child: _buildMapSection(),
          ),
          _expansionSection(
            title: 'Textos y anotaciones',
            subtitle: 'Texto personalizado, etiqueta y nota',
            icon: Icons.text_fields,
            child: _buildTextSection(),
          ),
          _expansionSection(
            title: 'Numeración',
            subtitle: 'Número inicial, prefijo y sufijo',
            icon: Icons.format_list_numbered,
            child: _buildSequenceSection(),
          ),
          _expansionSection(
            title: 'Logotipo',
            subtitle: 'Imagen, tamaño, opacidad y posición',
            icon: Icons.image_outlined,
            child: _buildLogoSection(),
          ),
          _expansionSection(
            title: 'Apariencia',
            subtitle: 'Colores, tipografía, fondo y posición',
            icon: Icons.palette_outlined,
            child: _buildAppearanceSection(),
          ),
          _expansionSection(
            title: 'Calidad de imagen',
            subtitle: 'Nivel de compresión de la fotografía',
            icon: Icons.high_quality_outlined,
            child: _buildImageSection(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _saving
                    ? 'Guardando...'
                    : 'Guardar configuración',
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
