import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryColor = Color(0xFF1565C0); // Azul TCE-SP
  static const Color _secondaryColor = Color(0xFF0288D1);
  static const Color _errorColor = Color(0xFFB00020);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          secondary: _secondaryColor,
          error: _errorColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          helperStyle: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
        ),
        textTheme: const TextTheme(
          // Forçando peso normal e mesmo tamanho/espaçamento para padronizar Dropdowns (titleMedium) e TextFields (bodyLarge)
          titleMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, letterSpacing: 0.25),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, letterSpacing: 0.25),
        ),
        listTileTheme: const ListTileThemeData(
          dense: true,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
}
