import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/environments.dart';
import '../../core/database/database_providers.dart';
import '../../core/navigation/app_modules.dart';
import '../../features/auth/auth_providers.dart';
import 'widgets/app_navigation_rail.dart';
import 'widgets/environment_dialog.dart';

/// Shell com menu lateral — envolve todos os módulos principais.
class ShellPage extends ConsumerWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(localSessionProvider);
    final env = ref.watch(environmentProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currentPath = GoRouterState.of(context).uri.path;

    final modules = user == null ? <AppModule>[] : modulosPara(user);
    final logsSelected = kLogsModule.matchesLocation(currentPath);

    return Scaffold(
      body: Row(
        children: [
          AppNavigationRail(
            modules: modules,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.asset(
                'assets/logo_audesp2.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chip de ambiente (somente admin pode alterar)
                  if (user?.isAdmin == true)
                    GestureDetector(
                      onTap: () => showEnvironmentDialog(context, ref),
                      child: _EnvironmentChip(env: env),
                    )
                  else
                    _EnvironmentChip(env: env),
                  const SizedBox(height: 8),
                  if (user != null && kLogsModule.podeAcessar(user))
                    IconButton(
                      icon: Icon(kLogsModule.icon),
                      selectedIcon: Icon(kLogsModule.activeIcon),
                      isSelected: logsSelected,
                      tooltip: kLogsModule.label,
                      style: IconButton.styleFrom(
                        backgroundColor: logsSelected
                            ? colorScheme.secondaryContainer
                            : Colors.transparent,
                        foregroundColor: logsSelected
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => context.go(kLogsModule.route),
                    ),
                  // Botão de admin ou perfil, conforme papel
                  if (user?.isAdmin == true)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      tooltip: 'Administração',
                      onPressed: () => context.go('/admin'),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.manage_accounts_outlined),
                      tooltip: 'Meu perfil',
                      onPressed: () => context.go('/profile'),
                    ),
                  const Divider(height: 16),
                  // Avatar do usuário com tooltip e logout
                  _UserAvatar(user: user, ref: ref),
                ],
              ),
            ),
          ),

          // ── Conteúdo do módulo selecionado ────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares internos
// ─────────────────────────────────────────────────────────────────────────────

class _EnvironmentChip extends StatelessWidget {
  final Environment env;
  const _EnvironmentChip({required this.env});

  @override
  Widget build(BuildContext context) {
    final isPiloto = env == Environment.piloto;
    return Tooltip(
      message: env.baseUrl,
      child: Chip(
        padding: const EdgeInsets.all(0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(
          env.label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isPiloto
            ? Colors.orange.shade100
            : Colors.green.shade100,
        side: BorderSide(
          color: isPiloto ? Colors.orange.shade300 : Colors.green.shade300,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final dynamic user;
  final WidgetRef ref;
  const _UserAvatar({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final initials = user?.nome?.isNotEmpty == true
        ? user.nome[0].toUpperCase()
        : '?';

    return PopupMenuButton<String>(
      tooltip: '${user?.nome ?? 'Perfil'}\n${user?.email ?? ''}',
      offset: const Offset(60, 0),
      child: CircleAvatar(radius: 18, child: Text(initials)),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.nome ?? '—',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(user?.email ?? '', style: const TextStyle(fontSize: 12)),
              Text(
                '${ref.watch(codigoMunicipioProvider)} — ${ref.watch(codigoEntidadeProvider)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Sair')),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(localSessionProvider.notifier).logout();
        }
      },
    );
  }
}
