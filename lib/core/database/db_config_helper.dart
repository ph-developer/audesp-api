import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:ini/ini.dart';

class DbConfigHelper {
  DbConfigHelper._();

  static Config? loadConfigSync() {
    try {
      final appDir = getAppDirectory();
      final iniFile = File(p.join(appDir, 'config.ini'));

      if (!iniFile.existsSync()) return null;

      final lines = iniFile.readAsLinesSync();
      return Config.fromStrings(lines);
    } catch (e) {
      debugPrint('Erro ao ler config.ini: $e');
      return null;
    }
  }

  static String getAppDirectory() {
    if (kReleaseMode) {
      final exePath = Platform.resolvedExecutable;
      return File(exePath).parent.path;
    } else {
      return Directory.current.path;
    }
  }
}
