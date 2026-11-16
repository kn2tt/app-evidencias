import 'package:material_ui/material_ui.dart';

class CameraHomeScreen extends StatelessWidget {
  const CameraHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Evidencias',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,

                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(28),
                    ),

                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 52,
                      color: Color(0xFF1565C0),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Captura de evidencias',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202124),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Aplicación móvil para registrar fotografías '
                    'de los trabajos realizados y adjuntarlas '
                    'a los requisitos del checklist.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),

                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF1565C0),
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'La cámara se integrará en la '
                              'siguiente etapa del desarrollo.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
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
}
