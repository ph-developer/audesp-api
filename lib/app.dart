import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/users_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = ref.read(localSessionProvider) != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/users';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && loc == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, _) => const UsersPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, _) => const _HomePlaceholder(),
      ),
    ],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────────────────────

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'AUDESP API',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder home — será substituído pela Shell (Fase 3)
// ─────────────────────────────────────────────────────────────────────────────

class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(localSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUDESP API'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
            onPressed: () {
              ref.read(localSessionProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Olá, ${user?.nome}! (Shell — Fase 3)'),
      ),
    );
  }
}

