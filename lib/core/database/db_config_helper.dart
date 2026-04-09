import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class DbConfigHelper {
  DbConfigHelper._();

  static Future<String> getDatabasePath() async {
    final fallbackPath = p.join(getAppDirectory(), 'audesp_default.sqlite');

    try {
      final appDir = getAppDirectory();
      final iniFile = File(p.join(appDir, 'config.ini'));

      if (!await iniFile.exists()) {
        debugPrint('Arquivo config.ini não encontrado. Usando fallback.');
        return fallbackPath;
      }

      final lines = await iniFile.readAsLines();
      
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
          continue;
        }

        if (line.toLowerCase().startsWith('path=')) {
          final extractedPath = line.substring(5).trim(); // Pega o que vem depois do "path="
          if (extractedPath.isNotEmpty) {
            debugPrint('Caminho do banco carregado do config.ini: $extractedPath');
            return extractedPath;
          }
        }
      }

      debugPrint('Chave "Path" não encontrada no config.ini. Usando fallback.');
      return fallbackPath;

    } catch (e) {
      debugPrint('Erro ao ler config.ini: $e');
      return fallbackPath;
    }
  }

  static String getAppDirectory() {
    if (kReleaseMode) {
      final exePath = Platform.resolvedExecutable;
      return File(exePath).parent.path;
    } 
    else {
      return Directory.current.path;
    }
  }
}