import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:ini/ini.dart';

class DbConfigHelper {
  DbConfigHelper._(); 
  
  static Future<Config?> loadConfig() async {
    try {
      final appDir = getAppDirectory();
      debugPrint('Diretório do aplicativo: $appDir');
      final iniFile = File(p.join(appDir, 'config.ini'));

      if (!await iniFile.exists()) {
        debugPrint('Arquivo config.ini não encontrado. Usando fallback.');
        return null;
      }

      final lines = await iniFile.readAsLines();
      return Config.fromStrings(lines);
    } catch (e) {
      debugPrint('Erro ao ler config.ini: $e');
      return null;
    }
  }

  static Future<String> getSqlitePath(Config? config) async {
    final fallbackPath = p.join(getAppDirectory(), 'audesp_default.sqlite');

    if (config != null) {
      final path = config.get('SQLite', 'Path');
      if (path != null && path.isNotEmpty) {
        debugPrint('Caminho do banco carregado do config.ini: $path');
        return path;
      }
    }

    debugPrint('Usando fallback do caminho do SQLite.');
    return fallbackPath;
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