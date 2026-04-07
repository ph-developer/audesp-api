import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  static const _prefix = 'audesp_pw_';

  Future<void> storePassword(String email, String password) =>
      _storage.write(key: '$_prefix$email', value: password);

  Future<String?> getPassword(String email) =>
      _storage.read(key: '$_prefix$email');

  Future<void> deletePassword(String email) =>
      _storage.delete(key: '$_prefix$email');

  Future<bool> verifyPassword(String email, String password) async {
    final stored = await getPassword(email);
    return stored == password;
  }
}
