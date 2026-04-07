import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/ajuste/pages/ajuste_page.dart';
import 'features/ata/pages/ata_page.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/users_page.dart';
import 'features/edital/pages/edital_page.dart';
import 'features/licitacao/pages/licitacao_page.dart';
import 'features/logs/pages/logs_page.dart';
import 'features/shell/shell_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/edital',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = ref.read(localSessionProvider) != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/users';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && loc == '/login') return '/edital';
      return null;
    },
    routes: [
      // Rotas de autenticação (sem shell)
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, _) => const UsersPage(),
      ),

      // Shell com NavigationRail envolvendo os módulos principais
      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: '/edital',
            builder: (context, _) => const EditalPage(),
          ),
          GoRoute(
            path: '/licitacao',
            builder: (context, _) => const LicitacaoPage(),
          ),
          GoRoute(
            path: '/ata',
            builder: (context, _) => const AtaPage(),
          ),
          GoRoute(
            path: '/ajuste',
            builder: (context, _) => const AjustePage(),
          ),
          GoRoute(
            path: '/logs',
            builder: (context, _) => const LogsPage(),
          ),
        ],
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


