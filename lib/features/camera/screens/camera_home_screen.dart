import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_compass/flutter_device_compass.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../models/watermark_settings.dart';
import '../services/location_service.dart';
import '../services/watermark_composer_service.dart';
import '../services/watermark_settings_service.dart';
import 'watermark_settings_screen.dart';

class CameraHomeScreen extends StatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  State<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  CameraController? _controller;

  final List<XFile> _fotografias = [];

  final WatermarkSettingsService _watermarkService =
      WatermarkSettingsService();

  final WatermarkComposerService _composerService =
      WatermarkComposerService();

  final LocationService _locationService = LocationService();

  final GlobalKey _mapBoundaryKey = GlobalKey();

  WatermarkSettings _watermarkSettings =
      const WatermarkSettings();

  bool _inicializando = true;
  bool _capturando = false;
  bool _cambiandoCamara = false;
  bool _panelExpandido = true;
  bool _mapTileError = false;

  String? _error;

  FlashMode _modoFlash = FlashMode.off;

  LocationData? _ubicacionActual;

  bool _obteniendoUbicacion = false;

  StreamSubscription<CompassEvent>? _suscripcionBrujula;

  double? _rumboActual;

  Timer? _relojTimer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    _configurarActualizacionFechaHora();

    _cargarConfiguracionMarcaAgua();
    _inicializarCamara();
  }

  // ---------------------------------------------------------
  // CONFIGURACIÓN DE MARCA DE AGUA
  // ---------------------------------------------------------

  Future<void> _cargarConfiguracionMarcaAgua() async {
    try {
      final configuracion = await _watermarkService.load();

      if (!mounted) return;

      setState(() {
        _watermarkSettings = configuracion;
      });

      _configurarActualizacionFechaHora();

      _configurarBrujula();

      if (_requiereUbicacion) {
        _actualizarUbicacionPreview();
      }
    } catch (_) {
      // Se mantienen los valores predeterminados.
    }
  }

  Future<void> _abrirConfiguracionMarcaAgua() async {
    try {
      final configuracionGuardada =
          await _watermarkService.load();

      if (!mounted) return;

      setState(() {
        _watermarkSettings = configuracionGuardada;
      });

      _configurarActualizacionFechaHora();

      _configurarBrujula();

      final resultado =
          await Navigator.of(context).push<WatermarkSettings>(
        MaterialPageRoute(
          builder: (context) => WatermarkSettingsScreen(
            initialSettings: _watermarkSettings,
          ),
        ),
      );

      if (!mounted || resultado == null) return;

      setState(() {
        _watermarkSettings = resultado;
      });

      _configurarBrujula();

      if (_requiereUbicacion) {
        _actualizarUbicacionPreview();
      } else {
        setState(() {
          _ubicacionActual = null;
        });
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la configuración de marca de agua.',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // UBICACIÓN PARA LA VISTA PREVIA
  // ---------------------------------------------------------

  bool get _requiereUbicacion {
    return _watermarkSettings.showAddress ||
        _watermarkSettings.showCoordinates ||
        _watermarkSettings.showAltitude ||
        _watermarkSettings.showAccuracy ||
        _watermarkSettings.showSpeed ||
        _watermarkSettings.showCompass ||
        _watermarkSettings.showMap;
  }

  Future<void> _actualizarUbicacionPreview() async {
    if (_obteniendoUbicacion || !_requiereUbicacion) {
      return;
    }

    _obteniendoUbicacion = true;

    try {
      final ubicacion =
          await _locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        _ubicacionActual = ubicacion;
        _mapTileError = false;
      });
    } catch (_) {
      // La cámara continúa funcionando sin datos GPS.
    } finally {
      _obteniendoUbicacion = false;
    }
  }

  // ---------------------------------------------------------
  // ACTUALIZACIÓN DE FECHA Y HORA
  // ---------------------------------------------------------

  void _configurarActualizacionFechaHora() {
    _relojTimer?.cancel();
    _relojTimer = null;

    if (!_watermarkSettings.showDateTime) return;

    _relojTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {});
      },
    );
  }

  // ---------------------------------------------------------
  // BRÚJULA
  // ---------------------------------------------------------

  void _configurarBrujula() {
    if (!_watermarkSettings.showCompass) {
      _suscripcionBrujula?.cancel();
      _suscripcionBrujula = null;
      _rumboActual = null;
      return;
    }

    if (_suscripcionBrujula != null) return;

    _suscripcionBrujula = FlutterCompass.events?.listen(
      (CompassEvent event) {
        final heading = event.headingForCameraMode;

        if (!mounted || heading == null || !heading.isFinite) {
          return;
        }

        setState(() {
          _rumboActual = (heading + 360) % 360;
        });
      },
    );
  }

  // ---------------------------------------------------------
  // LÍNEAS DE VISTA PREVIA
  // ---------------------------------------------------------

  List<String> _obtenerLineasPreview() {
    final numeroSecuencia =
        _watermarkSettings.sequenceStart + _fotografias.length;

    return _composerService.buildLines(
      settings: _watermarkSettings,
      location: _ubicacionActual,
      sequenceNumber: numeroSecuencia,
      heading: _rumboActual,
    );
  }

  // ---------------------------------------------------------
  // INICIALIZACIÓN DE CÁMARA
  // ---------------------------------------------------------

  Future<void> _inicializarCamara({
    CameraDescription? camara,
  }) async {
    CameraController? controller;

    try {
      final camaras = await availableCameras();

      if (camaras.isEmpty) {
        throw Exception(
          'No se encontró ninguna cámara disponible.',
        );
      }

      final camaraSeleccionada = camara ??
          camaras.firstWhere(
            (element) =>
                element.lensDirection == CameraLensDirection.back,
            orElse: () => camaras.first,
          );

      controller = CameraController(
        camaraSeleccionada,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _inicializando = false;
        _error = null;
        _modoFlash = FlashMode.off;
      });
    } catch (e) {
      await controller?.dispose();

      if (!mounted) return;

      setState(() {
        _inicializando = false;
        _error = e.toString();
      });
    }
  }

  // ---------------------------------------------------------
  // CAPTURA DE FOTOGRAFÍAS
  // ---------------------------------------------------------

  Future<void> _tomarFotografia() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _capturando) {
      return;
    }

    setState(() {
      _capturando = true;
    });

    try {
      // 1. Capturar la fotografía original.
      final fotografiaOriginal = await controller.takePicture();

      // 2. Obtener la ubicación si la configuración la necesita.
      LocationData? ubicacion;

      if (_requiereUbicacion) {
        try {
          ubicacion =
              await _locationService.getCurrentLocation();

          if (mounted) {
            setState(() {
              _ubicacionActual = ubicacion;
            });
          }
        } catch (e) {
          // Se utilizan los últimos datos disponibles.
          ubicacion = _ubicacionActual;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ubicacion == null
                      ? 'No se pudo obtener la ubicación. '
                          'La fotografía se guardará sin datos GPS. $e'
                      : 'No se pudo actualizar la ubicación. '
                          'Se utilizarán los últimos datos disponibles.',
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // Capturar el mapa visible para incorporarlo a la fotografía.
      final mapImageBytes = await _capturarMapaPreview();

      // 3. Calcular el número correlativo.
      final numeroSecuencia =
          _watermarkSettings.sequenceStart + _fotografias.length;

      // 4. Aplicar la marca de agua.
      final fotografiaProcesada =
          await _composerService.compose(
        imagePath: fotografiaOriginal.path,
        settings: _watermarkSettings,
        location: ubicacion,
        sequenceNumber: numeroSecuencia,
        heading: _rumboActual,
        mapImageBytes: mapImageBytes,
      );

      if (!mounted) return;

      // 5. Agregar la fotografía procesada a la galería.
      setState(() {
        _fotografias.add(
          XFile(fotografiaProcesada.path),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fotografía capturada y procesada correctamente.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo procesar la fotografía: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturando = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // CAMBIO DE CÁMARA
  // ---------------------------------------------------------

  Future<void> _cambiarCamara() async {
    if (_cambiandoCamara || _inicializando) return;

    setState(() {
      _cambiandoCamara = true;
      _inicializando = true;
      _error = null;
    });

    final camaraActual = _controller?.description;

    await _controller?.dispose();
    _controller = null;

    try {
      final camaras = await availableCameras();

      if (camaras.length < 2) {
        throw Exception(
          'No hay otra cámara disponible.',
        );
      }

      final nuevaCamara = camaras.firstWhere(
        (camara) =>
            camara.lensDirection != camaraActual?.lensDirection,
        orElse: () => camaras.first,
      );

      await _inicializarCamara(
        camara: nuevaCamara,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _inicializando = false;
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _cambiandoCamara = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // FLASH
  // ---------------------------------------------------------

  Future<void> _cambiarFlash() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    FlashMode siguienteModo;

    switch (_modoFlash) {
      case FlashMode.off:
        siguienteModo = FlashMode.auto;
        break;

      case FlashMode.auto:
        siguienteModo = FlashMode.always;
        break;

      case FlashMode.always:
        siguienteModo = FlashMode.off;
        break;

      default:
        siguienteModo = FlashMode.off;
    }

    try {
      await controller.setFlashMode(siguienteModo);

      if (!mounted) return;

      setState(() {
        _modoFlash = siguienteModo;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El flash no está disponible en esta cámara.',
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // GALERÍA INTERNA
  // ---------------------------------------------------------

  void _eliminarFotografia(int indice) {
    if (indice < 0 || indice >= _fotografias.length) {
      return;
    }

    setState(() {
      _fotografias.removeAt(indice);
    });
  }

  void _abrirFotografia(int indice) {
    if (indice < 0 || indice >= _fotografias.length) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoPreviewScreen(
          fotografias: _fotografias,
          indiceInicial: indice,
          onEliminar: _eliminarFotografia,
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // CONTROLES DEL PANEL
  // ---------------------------------------------------------

  void _alternarPanel() {
    setState(() {
      _panelExpandido = !_panelExpandido;
    });
  }

  void _gestionarDeslizamientoVertical(
    DragEndDetails details,
  ) {
    final velocidad = details.primaryVelocity ?? 0;

    if (velocidad < -100 && !_panelExpandido) {
      _alternarPanel();
    } else if (velocidad > 100 && _panelExpandido) {
      _alternarPanel();
    }
  }

  // ---------------------------------------------------------
  // MAPA DE UBICACIÓN - OPENSTREETMAP
  // ---------------------------------------------------------

  Widget _construirMapaPreview({
    required double scale,
  }) {
    final settings = _watermarkSettings;
    final location = _ubicacionActual;

    if (!settings.showMap ||
        location == null ||
        _mapTileError) {
      return const SizedBox.shrink();
    }

    final mapSize = settings.mapSize * scale;
    final margin = settings.margin * scale;

    final position = settings.mapPosition;

    return Positioned(
      left: position.endsWith('Left') ? margin : null,
      right: position.endsWith('Right') ? margin : null,
      top: position.startsWith('top') ? margin : null,
      bottom: position.startsWith('bottom') ? margin : null,
      child: Opacity(
        opacity: settings.mapOpacity.clamp(0.0, 1.0),
        child: RepaintBoundary(
          key: _mapBoundaryKey,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8 * scale),
            child: SizedBox(
              width: mapSize,
              height: mapSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FlutterMap(
                    key: ValueKey(
                      '${location.latitude}_${location.longitude}',
                    ),
                    options: MapOptions(
                      initialCenter: LatLng(
                        location.latitude,
                        location.longitude,
                      ),
                      initialZoom: 17,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.app_evidencias',
                        errorTileCallback: (tile, error, stackTrace) {
                          if (!mounted || _mapTileError) return;

                          setState(() {
                            _mapTileError = true;
                          });
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              location.latitude,
                              location.longitude,
                            ),
                            width: 24,
                            height: 24,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Atribución obligatoria de OpenStreetMap.
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      color: Colors.white.withValues(alpha: 0.85),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // CAPTURA DEL MAPA PARA LA FOTOGRAFÍA
  // ---------------------------------------------------------

  Future<Uint8List?> _capturarMapaPreview() async {
    if (!_watermarkSettings.showMap ||
        _ubicacionActual == null ||
        _mapTileError) {
      return null;
    }

    ui.Image? image;

    try {
      // Esperar a que Flutter termine de dibujar el mapa.
      await WidgetsBinding.instance.endOfFrame;

      // Dar tiempo a que se carguen las teselas visibles.
      await Future.delayed(
        const Duration(milliseconds: 900),
      );

      if (!mounted || _mapTileError) {
        return null;
      }

      final boundaryContext = _mapBoundaryKey.currentContext;

      final renderObject =
          boundaryContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary ||
          renderObject.size.isEmpty) {
        return null;
      }

      final previewSize = _controller?.value.previewSize;

      if (previewSize == null) {
        return null;
      }

      final scale = (
        MediaQuery.of(context).size.width /
        previewSize.height
      ).clamp(0.25, 1.0).toDouble();

      image = await renderObject.toImage(
        pixelRatio: 1 / scale,
      ).timeout(
        const Duration(seconds: 3),
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (_) {
      // Si falla el mapa, no se interrumpe la fotografía.
      return null;
    } finally {
      image?.dispose();
    }
  }

  // ---------------------------------------------------------
  // VISTA PREVIA DE MARCA DE AGUA
  // ---------------------------------------------------------

  Widget _construirMarcaAguaPreview({
    required double scale,
  }) {
    final settings = _watermarkSettings;
    final lines = _obtenerLineasPreview();

    final tieneLogo = settings.showLogo &&
        settings.logoPath != null &&
        File(settings.logoPath!).existsSync();

    if (lines.isEmpty && !tieneLogo) {
      return const SizedBox.shrink();
    }

    final alignment = switch (settings.position) {
      'topLeft' => Alignment.topLeft,
      'topRight' => Alignment.topRight,
      'bottomLeft' => Alignment.bottomLeft,
      'bottomRight' => Alignment.bottomRight,
      _ => Alignment.bottomRight,
    };

    final textAlignment = switch (settings.textAlignment) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };

    final previewFontSize =
        (settings.fontSize * scale).clamp(8.0, 40.0);

    final previewMargin = settings.margin * scale;
    final previewPadding = settings.backgroundPadding * scale;
    final previewLogoSize = settings.logoSize * scale;
    final previewRadius = settings.backgroundRadius * scale;

    final textStyle = TextStyle(
      color: Color(settings.colorValue),
      fontSize: previewFontSize,
      fontFamily: settings.fontFamily,
      fontWeight:
          settings.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle:
          settings.italic ? FontStyle.italic : FontStyle.normal,
      height: settings.lineSpacing,
      shadows: settings.textShadow
          ? const [
              Shadow(
                color: Colors.black87,
                offset: Offset(2, 2),
                blurRadius: 3,
              ),
            ]
          : null,
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: EdgeInsets.all(previewMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  settings.textAlignment == 'center'
                      ? CrossAxisAlignment.center
                      : settings.textAlignment == 'right'
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
              children: [
                if (tieneLogo)
                  Opacity(
                    opacity:
                        settings.logoOpacity.clamp(0.0, 1.0),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 8 * scale,
                      ),
                      child: Image.file(
                        File(settings.logoPath!),
                        width: previewLogoSize,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),

                if (lines.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(previewPadding),
                    decoration: BoxDecoration(
                      color: Color(
                        settings.backgroundColorValue,
                      ).withValues(
                        alpha: settings.backgroundOpacity
                            .clamp(0.0, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(
                        previewRadius,
                      ),
                    ),
                    child: Text(
                      lines.join('\n'),
                      textAlign: textAlignment,
                      style: textStyle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // LIBERACIÓN DE RECURSOS
  // ---------------------------------------------------------

  @override
  void dispose() {
    _relojTimer?.cancel();
    _controller?.dispose();
    _suscripcionBrujula?.cancel();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    super.dispose();
  }

  // ---------------------------------------------------------
  // INTERFAZ PRINCIPAL
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd:
            _gestionarDeslizamientoVertical,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _construirVistaCamara(),

            if (!_inicializando && _error == null) ...[
              Positioned(
                top: 12,
                left: 20,
                right: 20,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      _botonSuperior(
                        icono: Icons.arrow_back,
                        onTap: () =>
                            Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      _botonSuperior(
                        icono: _modoFlash == FlashMode.off
                            ? Icons.flash_off
                            : _modoFlash == FlashMode.auto
                                ? Icons.flash_auto
                                : Icons.flash_on,
                        onTap: _cambiarFlash,
                      ),
                      const SizedBox(width: 10),
                      _botonSuperior(
                        icono: Icons.flip_camera_android,
                        onTap: _cambiarCamara,
                      ),
                      const SizedBox(width: 10),
                      _botonSuperior(
                        icono: Icons.tune,
                        onTap: _abrirConfiguracionMarcaAgua,
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_fotografias.length} fotografías',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _construirControlesCamara(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // BOTONES SUPERIORES
  // ---------------------------------------------------------

  Widget _botonSuperior({
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icono,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // VISTA DE CÁMARA
  // ---------------------------------------------------------

  Widget _construirVistaCamara() {
    if (_inicializando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_error != null || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 56,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudo iniciar la cámara',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? 'La cámara no está disponible.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _inicializando = true;
                    _error = null;
                  });

                  _inicializarCamara();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize =
            controller.value.previewSize;

        if (previewSize == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        final cameraWidth = previewSize.height;
        final cameraHeight = previewSize.width;

        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: cameraWidth,
                    height: cameraHeight,
                    child: CameraPreview(controller),
                  ),
                ),
              ),

              _construirMapaPreview(
                scale: (constraints.maxWidth / cameraWidth)
                    .clamp(0.25, 1.0)
                    .toDouble(),
              ),

              _construirMarcaAguaPreview(
                scale: (constraints.maxWidth / cameraWidth)
                    .clamp(0.25, 1.0)
                    .toDouble(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // CONTROLES INFERIORES
  // ---------------------------------------------------------

  Widget _construirControlesCamara() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: EdgeInsets.fromLTRB(
        24,
        10,
        24,
        MediaQuery.of(context).padding.bottom + 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.75),
            Colors.black.withValues(alpha: 0.90),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _alternarPanel,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 12,
              ),
              child: Icon(
                _panelExpandido
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          if (_panelExpandido &&
              _fotografias.isNotEmpty) ...[
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fotografias.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final fotografia =
                      _fotografias[index];

                  return SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () =>
                                _abrirFotografia(index),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(10),
                              child: Image.file(
                                File(fotografia.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: -5,
                          right: -5,
                          child: GestureDetector(
                            onTap: () =>
                                _eliminarFotografia(index),
                            child: Container(
                              width: 23,
                              height: 23,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: 0.75,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _fotografias.isNotEmpty
                    ? () => _abrirFotografia(
                          _fotografias.length - 1,
                        )
                    : null,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.18,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white54,
                    ),
                  ),
                  child: _fotografias.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(9),
                          child: Image.file(
                            File(_fotografias.last.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                ),
              ),

              GestureDetector(
                onTap:
                    _capturando ? null : _tomarFotografia,
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(
                      alpha: 0.25,
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: _capturando
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: AppTheme.primaryColor,
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 52,
                height: 52,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// PANTALLA DE VISTA PREVIA DE FOTOGRAFÍAS
// =============================================================

class PhotoPreviewScreen extends StatefulWidget {
  final List<XFile> fotografias;
  final int indiceInicial;
  final Function(int) onEliminar;

  const PhotoPreviewScreen({
    super.key,
    required this.fotografias,
    required this.indiceInicial,
    required this.onEliminar,
  });

  @override
  State<PhotoPreviewScreen> createState() =>
      _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState
    extends State<PhotoPreviewScreen> {
  late int _indiceActual;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _indiceActual = widget.indiceInicial;

    _pageController = PageController(
      initialPage: _indiceActual,
    );
  }

  void _eliminarActual() {
    if (widget.fotografias.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    widget.onEliminar(_indiceActual);

    if (widget.fotografias.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      if (_indiceActual >=
          widget.fotografias.length) {
        _indiceActual =
            widget.fotografias.length - 1;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_indiceActual);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Fotografía ${_indiceActual + 1} de ${widget.fotografias.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _eliminarActual,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white,
            ),
            tooltip: 'Eliminar fotografía',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.fotografias.length,
        onPageChanged: (indice) {
          setState(() {
            _indiceActual = indice;
          });
        },
        itemBuilder: (context, indice) {
          final fotografia =
              widget.fotografias[indice];

          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.file(
                File(fotografia.path),
                key: ValueKey(fotografia.path),
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Text(
            'Desliza hacia los lados para cambiar de fotografía.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
