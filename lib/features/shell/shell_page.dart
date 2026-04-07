import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/environments.dart';
import '../../features/auth/auth_providers.dart';
import 'widgets/environment_dialog.dart';

/// Índice da aba selecionada na NavigationRail.
final selectedShellIndexProvider = StateProvider<int>((_) => 0);

/// Shell com NavigationRail lateral — envolve todos os módulos principais.
class ShellPage extends ConsumerWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  static const _destinations = [
    (icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Edital'),
    (icon: Icons.gavel_outlined, activeIcon: Icons.gavel, label: 'Licitação'),
    (icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Ata'),
    (icon: Icons.handshake_outlined, activeIcon: Icons.handshake, label: 'Ajuste'),
    (icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Logs'),
  ];

  static const _routes = ['/edital', '/licitacao', '/ata', '/ajuste', '/logs'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedShellIndexProvider);
    final user = ref.watch(localSessionProvider);
    final env = ref.watch(environmentProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // ── NavigationRail ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: NavigationRail(
              extended: false,
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) {
                ref.read(selectedShellIndexProvider.notifier).state = i;
                context.go(_routes[i]);
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    // Logo / título compacto
                    Icon(
                      Icons.account_balance_outlined,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AUDESP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chip de ambiente
                        _EnvironmentChip(env: env),
                        const SizedBox(height: 8),
                        // Botão configurações (abre seletor de ambiente)
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Configurações',
                          onPressed: () =>
                              showEnvironmentDialog(context, ref),
                        ),
                        const Divider(height: 16),
                        // Avatar do usuário com tooltip e logout
                        _UserAvatar(user: user, ref: ref),
                      ],
                    ),
                  ),
                ),
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
    final initials =
        user?.nome?.isNotEmpty == true ? user.nome[0].toUpperCase() : '?';

    return PopupMenuButton<String>(
      tooltip: '${user?.nome ?? 'Perfil'}\n${user?.email ?? ''}',
      offset: const Offset(60, 0),
      child: CircleAvatar(
        radius: 18,
        child: Text(initials),
      ),
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
              Text(
                user?.email ?? '',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '${user?.entidade ?? ''} — ${user?.municipio ?? ''}',
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
