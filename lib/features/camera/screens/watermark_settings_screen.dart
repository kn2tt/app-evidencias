import 'package:material_ui/material_ui.dart';

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
  final WatermarkSettingsService _service =
      WatermarkSettingsService();

  late WatermarkSettings _settings;
  late TextEditingController _textController;

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

    _textController = TextEditingController(
      text: _settings.customText,
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    try {
      final updatedSettings = _settings.copyWith(
        customText: _textController.text.trim(),
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

  Widget _settingsCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: child,
    );
  }

  Widget _buildPreview() {
    final color = Color(_settings.colorValue);

    return Container(
      width: double.infinity,
      height: 150,
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
            left: _settings.position == 'bottomLeft' ? 12 : null,
            right: _settings.position == 'bottomRight' ? 12 : null,
            top: _settings.position == 'topRight' ? 12 : null,
            bottom: _settings.position.startsWith('bottom') ? 12 : null,
            child: Column(
              crossAxisAlignment:
                  _settings.position == 'bottomLeft'
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
              children: [
                if (_settings.showDateTime)
                  Text(
                    '15 nov. 2026 10:30:45 a. m.',
                    style: TextStyle(
                      color: color,
                      fontSize: _settings.fontSize,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                if (_settings.customText.isNotEmpty)
                  Text(
                    _settings.customText,
                    style: TextStyle(
                      color: color,
                      fontSize: _settings.fontSize,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
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
            'Así se visualizará la información sobre la fotografía.',
          ),
          const SizedBox(height: 12),
          _buildPreview(),

          const SizedBox(height: 24),

          _sectionTitle(
            'Información',
            'Selecciona los datos que aparecerán en la fotografía.',
          ),
          const SizedBox(height: 12),

          _settingsCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha y hora'),
                  subtitle: const Text(
                    'Mostrar la fecha y hora de captura.',
                  ),
                  value: _settings.showDateTime,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        showDateTime: value,
                      );
                    });
                  },
                ),
                const Divider(),
                TextField(
                  controller: _textController,
                  maxLines: 2,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Texto personalizado',
                    hintText: 'Ej. Proyecto, cliente o ubicación',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _sectionTitle(
            'Apariencia',
            'Personaliza el aspecto de la marca de agua.',
          ),
          const SizedBox(height: 12),

          _settingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tamaño del texto',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Slider(
                  value: _settings.fontSize,
                  min: 10,
                  max: 28,
                  divisions: 9,
                  label: _settings.fontSize.round().toString(),
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(
                        fontSize: value,
                      );
                    });
                  },
                ),
                Text(
                  '${_settings.fontSize.round()} px',
                  style: const TextStyle(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Color de fuente',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: _colors.map((color) {
                    final selected =
                        _settings.colorValue == color.toARGB32();

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _settings = _settings.copyWith(
                            colorValue: color.toARGB32(),
                          );
                        });
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
                const SizedBox(height: 24),
                const Text(
                  'Posición',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'bottomLeft',
                      icon: Icon(Icons.align_horizontal_left),
                    ),
                    ButtonSegment(
                      value: 'bottomRight',
                      icon: Icon(Icons.align_horizontal_right),
                    ),
                    ButtonSegment(
                      value: 'topRight',
                      icon: Icon(Icons.vertical_align_top),
                    ),
                  ],
                  selected: {_settings.position},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _settings = _settings.copyWith(
                        position: selection.first,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

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
                _saving ? 'Guardando...' : 'Guardar configuración',
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
