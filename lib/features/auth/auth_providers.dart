import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sessão local — usuário selecionado no login do app
// ─────────────────────────────────────────────────────────────────────────────

final localSessionProvider = NotifierProvider<LocalSessionNotifier, User?>(
  LocalSessionNotifier.new,
);

class LocalSessionNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void login(User user) => state = user;

  void logout() {
    ref.read(authServiceProvider).clearToken();
    state = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RouterNotifier — notifica o GoRouter quando o estado de auth muda
// ─────────────────────────────────────────────────────────────────────────────

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<User?>(
      localSessionProvider,
      (previous, next) => notifyListeners(),
    );
  }
}
