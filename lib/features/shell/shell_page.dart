import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/environments.dart';
import '../../features/auth/auth_providers.dart';
import 'widgets/environment_dialog.dart';

/// Índice da aba selecionada no NavigationPane.
final selectedShellIndexProvider = StateProvider<int>((_) => 0);

/// Shell com NavigationView lateral — envolve todos os módulos principais.
class ShellPage extends ConsumerWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  static const _routes = ['/edital', '/licitacao', '/ata', '/ajuste', '/logs'];

  int _indexFromLocation(String location) {
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(localSessionProvider);
    final env = ref.watch(environmentProvider);
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFromLocation(location);

    return NavigationView(
      paneBodyBuilder: (item, body) => child,
      pane: NavigationPane(
        selected: selectedIndex,
        onChanged: (i) => context.go(_routes[i]),
        displayMode: PaneDisplayMode.expanded,
        header: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                color: FluentTheme.of(context).accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'AUDESP',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.document),
            title: const Text('Edital'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(Icons.gavel_outlined),
            title: const Text('Licitação'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.task_list),
            title: const Text('Ata'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(Icons.handshake_outlined),
            title: const Text('Ajuste'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: const Text('Logs'),
            body: const SizedBox.shrink(),
          ),
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItemAction(
            icon: _EnvironmentBadge(env: env),
            title: Text(env.label),
            onTap: user?.isAdmin == true
                ? () => showEnvironmentDialog(context, ref)
                : () {},
          ),
          if (user?.isAdmin == true)
            PaneItemAction(
              icon: const Icon(FluentIcons.shield),
              title: const Text('Administração'),
              onTap: () => context.go('/admin'),
            )
          else
            PaneItemAction(
              icon: const Icon(FluentIcons.account_management),
              title: const Text('Meu perfil'),
              onTap: () => context.go('/profile'),
            ),
          PaneItemAction(
            icon: _UserInitialsAvatar(nome: user?.nome),
            title: Text(user?.nome ?? 'Usuário'),
            onTap: () => _showUserDialog(context, ref, user),
          ),
        ],
      ),
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, dynamic user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Conta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(FluentIcons.people, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nome ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (user?.municipio != null)
              Row(
                children: [
                  const Icon(Icons.location_city_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${user?.entidade ?? ''} — ${user?.municipio ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Fechar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFFB00020)),
              foregroundColor: WidgetStatePropertyAll(Colors.white),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(localSessionProvider.notifier).logout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares internos
// ─────────────────────────────────────────────────────────────────────────────

class _EnvironmentBadge extends StatelessWidget {
  final Environment env;
  const _EnvironmentBadge({required this.env});

  @override
  Widget build(BuildContext context) {
    final isPiloto = env == Environment.piloto;
    return Tooltip(
      message: env.baseUrl,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isPiloto
              ? const Color(0xFFFFF3E0)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isPiloto
                ? const Color(0xFFFF9800)
                : const Color(0xFF4CAF50),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            env.label[0],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPiloto
                  ? const Color(0xFFE65100)
                  : const Color(0xFF1B5E20),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserInitialsAvatar extends StatelessWidget {
  final String? nome;
  const _UserInitialsAvatar({required this.nome});

  @override
  Widget build(BuildContext context) {
    final initials =
        nome?.isNotEmpty == true ? nome![0].toUpperCase() : '?';
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: FluentTheme.of(context).accentColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
