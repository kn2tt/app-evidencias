import 'package:material_ui/material_ui.dart';

class AppTheme {
  // Colores oficiales del sistema web.
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryDarkColor = Color(0xFF1D4ED8);
  static const Color primaryLightColor = Color(0xFFEFF6FF);

  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  static const Color textColor = Color(0xFF1E293B);
  static const Color secondaryTextColor = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  // Tema claro de la aplicación.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryColor,
        onPrimary: Colors.white,
        surface: surfaceColor,
      ),

      scaffoldBackgroundColor: backgroundColor,

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: secondaryTextColor,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: secondaryTextColor,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: borderColor,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),
    );
  }
}