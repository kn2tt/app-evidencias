
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../models/watermark_settings.dart';
import '../services/watermark_settings_service.dart';

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
  final WatermarkSettingsService _service = WatermarkSettingsService();
  final ImagePicker _imagePicker = ImagePicker();

  late WatermarkSettings _settings;

  late final TextEditingController _customTextController;
  late final TextEditingController _labelController;
  late final TextEditingController _noteController;

  bool _saving = false;

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    const Color(0xFF2563EB),
    const Color(0xFF22C55E),
    const Color(0xFFFFD700),
    const Color(0xFFFF5252),
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
  }

  void _update(WatermarkSettings updated) {
    setState(() {
      _settings = updated;
    });
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
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
    setState(() {
      _saving = true;
    });

    try {
      final updatedSettings = _settings.copyWith(
        customText: _customTextController.text.trim(),
        labelText: _labelController.text.trim(),
        noteText: _noteController.text.trim(),
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
          style: const TextStyle(fontWeight: FontWeight.w600),
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
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPreview() {
    final color = Color(_settings.colorValue);
    final backgroundColor = Color(_settings.backgroundColorValue);

    final previewText = <String>[];

    if (_settings.showDateTime) {
      previewText.add('Fecha y hora de captura');
    }
    if (_settings.showAddress) {
      previewText.add('Dirección de ubicación');
    }
    if (_settings.showCoordinates) {
      previewText.add('Coordenadas GPS');
    }
    if (_settings.showAltitude) {
      previewText.add('Altitud');
    }
    if (_settings.showAccuracy) {
      previewText.add('Precisión GPS');
    }
    if (_settings.showSpeed) {
      previewText.add('Velocidad');
    }
    if (_settings.showCompass) {
      previewText.add('Orientación');
    }
    if (_settings.showSequence) {
      previewText.add('Foto ${_settings.sequenceStart.toString().padLeft(_settings.sequenceDigits, '0')}');
    }
    if (_settings.showLabel && _settings.labelText.isNotEmpty) {
      previewText.add(_settings.labelText);
    }
    if (_settings.showCustomText && _settings.customText.isNotEmpty) {
      previewText.add(_settings.customText);
    }
    if (_settings.showNote && _settings.noteText.isNotEmpty) {
      previewText.add(_settings.noteText);
    }

    if (previewText.isEmpty) {
      previewText.add('Sin información seleccionada');
    }

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 55,
                color: Colors.white24,
              ),
            ),
          ),
          Positioned(
            left: _settings.position.endsWith('Left') ? 12 : null,
            right: _settings.position.endsWith('Right') ? 12 : null,
            top: _settings.position.startsWith('top') ? 12 : null,
            bottom: _settings.position.startsWith('bottom') ? 12 : null,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: EdgeInsets.all(_settings.margin.clamp(4, 30)),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(
                  alpha: _settings.backgroundOpacity.clamp(0, 1),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment:
                    _settings.position.endsWith('Left')
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: previewText.map((line) {
                  return Text(
                    line,
                    textAlign: _settings.position.endsWith('Left')
                        ? TextAlign.left
                        : TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontSize: _settings.fontSize.clamp(10, 28),
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
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
          onChanged: (v) =>
              _update(_settings.copyWith(showDateTime: v)),
        ),
        _dropdown<String>(
          label: 'Formato de fecha',
          value: _settings.dateFormat,
          items: const [
            DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('15/11/2026')),
            DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('11/15/2026')),
            DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('2026-11-15')),
            DropdownMenuItem(value: 'dd-MM-yyyy', child: Text('15-11-2026')),
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
            DropdownMenuItem(value: 'HH:mm:ss', child: Text('24 horas (14:30:45)')),
            DropdownMenuItem(value: 'hh:mm:ss a', child: Text('12 horas (02:30:45 PM)')),
            DropdownMenuItem(value: 'HH:mm', child: Text('24 horas (14:30)')),
            DropdownMenuItem(value: 'hh:mm a', child: Text('12 horas (02:30 PM)')),
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
            DropdownMenuItem(value: 'local', child: Text('Hora local del dispositivo')),
            DropdownMenuItem(value: 'UTC', child: Text('UTC')),
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
          onChanged: (v) =>
              _update(_settings.copyWith(showAddress: v)),
        ),
        _switch(
          title: 'Coordenadas GPS',
          value: _settings.showCoordinates,
          onChanged: (v) =>
              _update(_settings.copyWith(showCoordinates: v)),
        ),
        _dropdown<String>(
          label: 'Formato de coordenadas',
          value: _settings.coordinatesFormat,
          items: const [
            DropdownMenuItem(value: 'decimal', child: Text('Decimal')),
            DropdownMenuItem(value: 'dms', child: Text('Grados, minutos y segundos')),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(coordinatesFormat: v));
            }
          },
        ),
        const SizedBox(height: 12),
        _dropdown<String>(
          label: 'Formato de dirección',
          value: _settings.addressFormat,
          items: const [
            DropdownMenuItem(value: 'full', child: Text('Dirección completa')),
            DropdownMenuItem(value: 'short', child: Text('Dirección resumida')),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(addressFormat: v));
            }
          },
        ),
        const Divider(height: 24),
        _switch(
          title: 'Altitud',
          value: _settings.showAltitude,
          onChanged: (v) =>
              _update(_settings.copyWith(showAltitude: v)),
        ),
        _switch(
          title: 'Precisión GPS',
          value: _settings.showAccuracy,
          onChanged: (v) =>
              _update(_settings.copyWith(showAccuracy: v)),
        ),
        _switch(
          title: 'Velocidad',
          value: _settings.showSpeed,
          onChanged: (v) =>
              _update(_settings.copyWith(showSpeed: v)),
        ),
        _switch(
          title: 'Orientación / brújula',
          value: _settings.showCompass,
          onChanged: (v) =>
              _update(_settings.copyWith(showCompass: v)),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      children: [
        _switch(
          title: 'Mostrar mapa',
          subtitle: 'Incluir un pequeño mapa de la ubicación.',
          value: _settings.showMap,
          onChanged: (v) =>
              _update(_settings.copyWith(showMap: v)),
        ),
        _slider(
          label: 'Tamaño del mapa',
          value: _settings.mapSize,
          min: 60,
          max: 200,
          divisions: 14,
          valueLabel: '${_settings.mapSize.round()} px',
          onChanged: (v) =>
              _update(_settings.copyWith(mapSize: v)),
        ),
        _slider(
          label: 'Opacidad del mapa',
          value: _settings.mapOpacity,
          min: 0.1,
          max: 1,
          divisions: 9,
          valueLabel: '${(_settings.mapOpacity * 100).round()}%',
          onChanged: (v) =>
              _update(_settings.copyWith(mapOpacity: v)),
        ),
        _dropdown<String>(
          label: 'Posición del mapa',
          value: _settings.mapPosition,
          items: const [
            DropdownMenuItem(value: 'topLeft', child: Text('Superior izquierda')),
            DropdownMenuItem(value: 'topRight', child: Text('Superior derecha')),
            DropdownMenuItem(value: 'bottomLeft', child: Text('Inferior izquierda')),
            DropdownMenuItem(value: 'bottomRight', child: Text('Inferior derecha')),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(mapPosition: v));
            }
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'La visualización del mapa se implementará junto con la captura de ubicación.',
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
          onChanged: (v) =>
              _update(_settings.copyWith(showCustomText: v)),
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
          onChanged: (v) =>
              _update(_settings.copyWith(showLabel: v)),
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
          onChanged: (v) =>
              _update(_settings.copyWith(showNote: v)),
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
          subtitle: 'Mostrar un número consecutivo en cada fotografía.',
          value: _settings.showSequence,
          onChanged: (v) =>
              _update(_settings.copyWith(showSequence: v)),
        ),
        TextFormField(
          initialValue: _settings.sequenceStart.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Número inicial',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            final number = int.tryParse(v);
            if (number != null && number > 0) {
              _update(_settings.copyWith(sequenceStart: number));
            }
          },
        ),
        const SizedBox(height: 12),
        _dropdown<int>(
          label: 'Cantidad de dígitos',
          value: _settings.sequenceDigits,
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 dígito (1)')),
            DropdownMenuItem(value: 2, child: Text('2 dígitos (01)')),
            DropdownMenuItem(value: 3, child: Text('3 dígitos (001)')),
            DropdownMenuItem(value: 4, child: Text('4 dígitos (0001)')),
            DropdownMenuItem(value: 5, child: Text('5 dígitos (00001)')),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(sequenceDigits: v));
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
          onChanged: (v) =>
              _update(_settings.copyWith(showLogo: v)),
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
          onChanged: (v) =>
              _update(_settings.copyWith(logoSize: v)),
        ),
        _slider(
          label: 'Opacidad del logotipo',
          value: _settings.logoOpacity,
          min: 0.1,
          max: 1,
          divisions: 9,
          valueLabel: '${(_settings.logoOpacity * 100).round()}%',
          onChanged: (v) =>
              _update(_settings.copyWith(logoOpacity: v)),
        ),
        _dropdown<String>(
          label: 'Posición del logotipo',
          value: _settings.logoPosition,
          items: const [
            DropdownMenuItem(value: 'topLeft', child: Text('Superior izquierda')),
            DropdownMenuItem(value: 'topRight', child: Text('Superior derecha')),
            DropdownMenuItem(value: 'bottomLeft', child: Text('Inferior izquierda')),
            DropdownMenuItem(value: 'bottomRight', child: Text('Inferior derecha')),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(logoPosition: v));
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
          onChanged: (v) =>
              _update(_settings.copyWith(fontSize: v)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Color de fuente',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _colors.map((color) {
            final selected =
                _settings.colorValue == color.toARGB32();

            return GestureDetector(
              onTap: () {
                _update(_settings.copyWith(
                  colorValue: color.toARGB32(),
                ));
              },
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
        const SizedBox(height: 20),
        const Text(
          'Color de fondo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: [
            Colors.black,
            Colors.white,
            const Color(0xFF1E293B),
            const Color(0xFF2563EB),
          ].map((color) {
            final selected =
                _settings.backgroundColorValue == color.toARGB32();

            return GestureDetector(
              onTap: () {
                _update(_settings.copyWith(
                  backgroundColorValue: color.toARGB32(),
                ));
              },
              child: Container(
                width: 34,
                height: 34,
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
                    ? const Icon(Icons.check, color: Colors.grey, size: 18)
                    : null,
              ),
            );
          }).toList(),
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
          onChanged: (v) =>
              _update(_settings.copyWith(backgroundOpacity: v)),
        ),
        _dropdown<String>(
          label: 'Familia tipográfica',
          value: _settings.fontFamily,
          items: const [
            DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
            DropdownMenuItem(value: 'Arial', child: Text('Arial')),
            DropdownMenuItem(value: 'serif', child: Text('Serif')),
            DropdownMenuItem(value: 'monospace', child: Text('Monospace')),
          ],
          onChanged: (v) {
            if (v != null) {
              _update(_settings.copyWith(fontFamily: v));
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Posición de la marca de agua',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _dropdown<String>(
          label: 'Posición',
          value: _settings.position,
          items: const [
            DropdownMenuItem(value: 'bottomLeft', child: Text('Inferior izquierda')),
            DropdownMenuItem(value: 'bottomRight', child: Text('Inferior derecha')),
            DropdownMenuItem(value: 'topLeft', child: Text('Superior izquierda')),
            DropdownMenuItem(value: 'topRight', child: Text('Superior derecha')),
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
          onChanged: (v) =>
              _update(_settings.copyWith(margin: v)),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return _slider(
      label: 'Calidad de imagen',
      value: _settings.imageQuality.toDouble(),
      min: 60,
      max: 100,
      divisions: 8,
      valueLabel: '${_settings.imageQuality}%',
      onChanged: (v) =>
          _update(_settings.copyWith(imageQuality: v.round())),
    );
  }

  @override
  void dispose() {
    _customTextController.dispose();
    _labelController.dispose();
    _noteController.dispose();
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
            'Ejemplo ilustrativo de la información seleccionada.',
          ),
          const SizedBox(height: 12),
          _buildPreview(),
          const SizedBox(height: 8),
          const Text(
            'Los datos de ubicación y fecha se sustituirán por información real al implementar el procesamiento de fotografías.',
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
            subtitle: 'Número inicial y cantidad de dígitos',
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
            subtitle: 'Colores, tipografía, posición y margen',
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
