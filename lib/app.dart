import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/pages/admin_page.dart';
import 'features/ajuste/pages/ajuste_page.dart';
import 'features/ata/pages/ata_form_page.dart';
import 'features/ata/pages/ata_page.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/profile_page.dart';
import 'features/edital/pages/edital_form_page.dart';
import 'features/edital/pages/edital_page.dart';
import 'features/licitacao/pages/licitacao_form_page.dart';
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
      final user = ref.read(localSessionProvider);
      final loggedIn = user != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login';

      // Não logado → sempre para o login
      if (!loggedIn && !isAuthRoute) return '/login';

      // Logado e na tela de login → módulo inicial
      if (loggedIn && loc == '/login') return '/edital';

      // Não-admin tentando acessar a área de admin → redireciona
      if (loggedIn && loc.startsWith('/admin') && user.isAdmin != true) {
        return '/edital';
      }

      // Admin tentando acessar o perfil de usuário → redireciona para admin
      if (loggedIn && loc == '/profile' && user.isAdmin == true) {
        return '/admin';
      }

      return null;
    },
    routes: [
      // Rota de autenticação (sem shell)
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginPage(),
      ),

      // Perfil do usuário (sem shell, acessível a todos após login)
      GoRoute(
        path: '/profile',
        builder: (context, _) => const ProfilePage(),
      ),

      // Painel de administração (sem shell, admin only — guard no redirect)
      GoRoute(
        path: '/admin',
        builder: (context, _) => const AdminPage(),
      ),

      // Shell com NavigationRail envolvendo os módulos principais
      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: '/edital',
            builder: (context, _) => const EditalPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, _) => const EditalFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '');
                  return EditalFormPage(editalId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/licitacao',
            builder: (context, _) => const LicitacaoPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) {
                  final editalId =
                      int.tryParse(state.uri.queryParameters['editalId'] ?? '');
                  return LicitacaoFormPage(preselectedEditalId: editalId);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '');
                  return LicitacaoFormPage(licitacaoId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/ata',
            builder: (context, _) => const AtaPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) {
                  final editalId =
                      int.tryParse(state.uri.queryParameters['editalId'] ?? '');
                  return AtaFormPage(preselectedEditalId: editalId);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '');
                  return AtaFormPage(ataId: id);
                },
              ),
            ],
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
    );
  }
}

