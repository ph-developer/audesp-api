import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usuário administrador virtual (não persiste no banco de dados).
// Autenticado pela senha definida em assets/.env (ADMIN_PASSWORD).
// ─────────────────────────────────────────────────────────────────────────────

User buildAdminUser() => User(
      id: -1,
      nome: 'Administrador',
      email: 'admin',
      municipio: '',
      entidade: '',
      isAdmin: true,
      createdAt: DateTime.now(),
    );

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
