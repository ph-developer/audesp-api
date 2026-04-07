import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sessão local — usuário selecionado no login do app
// ─────────────────────────────────────────────────────────────────────────────

final localSessionProvider =
    StateNotifierProvider<LocalSessionNotifier, User?>(
  (_) => LocalSessionNotifier(),
);

class LocalSessionNotifier extends StateNotifier<User?> {
  LocalSessionNotifier() : super(null);

  void login(User user) => state = user;

  void logout() => state = null;
}

// ─────────────────────────────────────────────────────────────────────────────
// RouterNotifier — notifica o GoRouter quando o estado de auth muda
// ─────────────────────────────────────────────────────────────────────────────

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen<User?>(localSessionProvider, (previous, next) => notifyListeners());
  }
}
