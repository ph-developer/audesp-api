import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  AppTheme._();

  // Azul TCE-SP
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF0288D1);

  static FluentThemeData get light => FluentThemeData(
        accentColor: AccentColor.swatch({
          'darkest': const Color(0xFF003a7a),
          'darker': const Color(0xFF004da3),
          'dark': const Color(0xFF0d5fb8),
          'normal': const Color(0xFF1565C0),
          'light': const Color(0xFF3a7fd4),
          'lighter': const Color(0xFF6aa0e0),
          'lightest': const Color(0xFF9dc1ec),
        }),
        brightness: Brightness.light,
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
        cardColor: const Color(0xFFFFFFFF),
        micaBackgroundColor: const Color(0xFFF3F3F3),
        shadowColor: const Color(0x1A000000),
      );
}
