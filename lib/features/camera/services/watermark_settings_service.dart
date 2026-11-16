import 'package:shared_preferences/shared_preferences.dart';

import '../models/watermark_settings.dart';

class WatermarkSettingsService {
  static const String _storageKey = 'watermark_settings';

  Future<WatermarkSettings> load() async {
    final preferences = await SharedPreferences.getInstance();

    final savedSettings = preferences.getString(_storageKey);

    if (savedSettings == null) {
      return const WatermarkSettings();
    }

    try {
      return WatermarkSettings.fromJson(savedSettings);
    } catch (_) {
      return const WatermarkSettings();
    }
  }

  Future<void> save(WatermarkSettings settings) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      settings.toJson(),
    );
  }
}
