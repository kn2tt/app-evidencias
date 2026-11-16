import 'package:material_ui/material_ui.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/camera/screens/camera_home_screen.dart';

void main() {
  runApp(const EvidenciasApp());
}

class EvidenciasApp extends StatelessWidget {
  const EvidenciasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const CameraHomeScreen(),
    );
  }
}
