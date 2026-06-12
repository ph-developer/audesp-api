import 'dart:io';

import 'package:path/path.dart' as p;

class LocalPrefs {
  LocalPrefs._();

  static String get _dir => p.join(Platform.environment['APPDATA'] ?? '', 'audesp_api');
  static String get _file => p.join(_dir, 'last_user.txt');

  static Future<String?> getLastUser() async {
    try {
      final file = File(_file);
      if (!await file.exists()) return null;
      return (await file.readAsString()).trim();
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastUser(String email) async {
    try {
      final dir = Directory(_dir);
      if (!await dir.exists()) await dir.create(recursive: true);
      await File(_file).writeAsString(email);
    } catch (_) {
      // silently ignore
    }
  }
}
