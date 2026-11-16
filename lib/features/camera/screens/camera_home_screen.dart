import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';

class CameraHomeScreen extends StatelessWidget {
  const CameraHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidencias'),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,

                    decoration: BoxDecoration(
                      color: AppTheme.primaryLightColor,
                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 52,
                      color: AppTheme.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Captura de evidencias',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Registra fotografías de los trabajos realizados '
                    'y adjúntalas directamente a los requisitos '
                    'del checklist.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                  ),

                  const SizedBox(height: 28),

                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'La aplicación permitirá capturar, '
                              'revisar y enviar fotografías como '
                              'evidencias de cada requisito.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppTheme.secondaryTextColor,
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