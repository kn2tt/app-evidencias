
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class CameraHomeScreen extends StatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  State<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  CameraController? _controller;

  final List<XFile> _fotografias = [];

  bool _inicializando = true;
  bool _capturando = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    _inicializarCamara();
  }

  Future<void> _inicializarCamara() async {
    try {
      final camaras = await availableCameras();

      if (camaras.isEmpty) {
        throw Exception('No se encontró ninguna cámara disponible.');
      }

      final camaraTrasera = camaras.firstWhere(
        (camara) => camara.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );

      final controller = CameraController(
        camaraTrasera,
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
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _inicializando = false;
        _error = e.toString();
      });
    }
  }

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
      final fotografia = await controller.takePicture();

      if (!mounted) return;

      setState(() {
        _fotografias.add(fotografia);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo tomar la fotografía: $e'),
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

  void _eliminarFotografia(int indice) {
    setState(() {
      _fotografias.removeAt(indice);
    });
  }

  void _abrirFotografia(int indice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoPreviewScreen(
          fotografias: _fotografias,
          indiceInicial: indice,
          onEliminar: (indice) {
            _eliminarFotografia(indice);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _botonSuperior(
                      icono: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
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
    );
  }

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

  Widget _construirVistaCamara() {
    if (_inicializando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_error != null) {
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
                _error!,
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
        final previewSize = controller.value.previewSize!;

        // La vista previa se adapta a la orientación vertical
        // del teléfono y cubre todo el espacio disponible.
        final cameraWidth = previewSize.height;
        final cameraHeight = previewSize.width;

        return SizedBox.expand(
          child: ClipRect(
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
        );
      },
    );
  }

  Widget _construirControlesCamara() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        18,
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
          if (_fotografias.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fotografias.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final fotografia = _fotografias[index];

                  return GestureDetector(
                    onTap: () => _abrirFotografia(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(fotografia.path),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

          if (_fotografias.isNotEmpty)
            const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white54,
                    ),
                  ),
                  child: _fotografias.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
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
                onTap: _capturando ? null : _tomarFotografia,
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
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
                              child: CircularProgressIndicator(
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

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late int _indiceActual;

  @override
  void initState() {
    super.initState();

    _indiceActual = widget.indiceInicial;
  }

  void _eliminarActual() {
    widget.onEliminar(_indiceActual);

    if (widget.fotografias.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      if (_indiceActual >= widget.fotografias.length) {
        _indiceActual = widget.fotografias.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fotografia = widget.fotografias[_indiceActual];

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
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.file(
            File(fotografia.path),
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Text(
            'Puedes ampliar la imagen con dos dedos.',
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
