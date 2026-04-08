import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/environments.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../auth/auth_providers.dart';
import '../../auth/widgets/user_form_dialog.dart';

/// Painel de administração: Usuários · Ambiente · Registros.
/// Acessível apenas por usuários com [User.isAdmin == true].
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        title: const Text('Administração'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.go('/edital'),
        ),
      ),
      content: TabView(
        currentIndex: _tabIndex,
        onChanged: (i) => setState(() => _tabIndex = i),
        closeButtonVisibility: CloseButtonVisibilityMode.never,
        tabs: [
          Tab(
            icon: const Icon(Icons.people_outlined),
            text: const Text('Usuários'),
            body: const _UsersTab(),
          ),
          Tab(
            icon: const Icon(Icons.cloud_outlined),
            text: const Text('Ambiente'),
            body: const _EnvironmentTab(),
          ),
          Tab(
            icon: const Icon(Icons.folder_outlined),
            text: const Text('Registros'),
            body: const _RegistrosTab(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Gerenciamento de usuários
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersStream = ref.watch(usersDaoProvider).watchAll();

    return Stack(
      children: [
        StreamBuilder<List<User>>(
          stream: usersStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: ProgressRing());
            }
            final users = snapshot.data!;
            if (users.isEmpty) {
              return const Center(child: Text('Nenhum usuário cadastrado.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final u = users[i];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: u.isAdmin
                            ? FluentTheme.of(ctx).accentColor
                            : FluentTheme.of(ctx)
                                .resources
                                .controlFillColorDefault,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        u.nome[0].toUpperCase(),
                        style: TextStyle(
                          color: u.isAdmin ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(u.nome),
                        if (u.isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: FluentTheme.of(ctx)
                                  .accentColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle:
                        Text('${u.email}\n${u.entidade} — ${u.municipio}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _openForm(ctx, ref, u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          style: const ButtonStyle(
                            foregroundColor:
                                WidgetStatePropertyAll(Color(0xFFB00020)),
                          ),
                          onPressed: () => _confirmDelete(ctx, ref, u),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FilledButton(
            onPressed: () => _openForm(context, ref, null),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_outlined, size: 18),
                SizedBox(width: 8),
                Text('Novo usuário'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, User? user) =>
      showDialog(
        context: context,
        builder: (_) => UserFormDialog(user: user),
      );

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, User user) async {
    final session = ref.read(localSessionProvider);
    if (session?.id == user.id) {
      displayInfoBar(context, builder: (ctx, close) => const InfoBar(
        title: Text('Não é possível excluir o usuário logado.'),
        severity: InfoBarSeverity.warning,
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Excluir usuário'),
        content: Text(
            'Deseja excluir o perfil de "${user.nome}"? Esta ação não pode ser desfeita.'),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFFB00020)),
              foregroundColor: WidgetStatePropertyAll(Colors.white),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(usersDaoProvider).deleteById(user.id);
      await ref.read(secureStorageServiceProvider).deletePassword(user.email);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Seleção de ambiente
// ─────────────────────────────────────────────────────────────────────────────

class _EnvironmentTab extends ConsumerWidget {
  const _EnvironmentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(environmentProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ambiente da API AUDESP',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                RadioGroup<Environment>(
                  groupValue: current,
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(environmentProvider.notifier)
                          .setEnvironment(v);
                    }
                  },
                  child: Column(
                    children: Environment.values.map((env) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: RadioButton<Environment>(
                          value: env,
                          content: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(env.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(env.baseUrl,
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: env == Environment.piloto
                                      ? const Color(0xFFFFE0B2)
                                      : const Color(0xFFC8E6C9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  env == Environment.piloto
                                      ? 'Teste'
                                      : 'Produção',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A seleção de ambiente aplica-se a todas as chamadas API da sessão.',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Consulta de registros (leitura de todos os módulos)
// ─────────────────────────────────────────────────────────────────────────────

class _RegistrosTab extends ConsumerStatefulWidget {
  const _RegistrosTab();

  @override
  ConsumerState<_RegistrosTab> createState() => _RegistrosTabState();
}

class _RegistrosTabState extends ConsumerState<_RegistrosTab> {
  int _selectedModule = 0; // 0=Editais 1=Licitações 2=Atas 3=Ajustes

  static const _moduleLabels = ['Editais', 'Licitações', 'Atas', 'Ajustes'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            children: List.generate(_moduleLabels.length, (i) {
              final selected = _selectedModule == i;
              return selected
                  ? FilledButton(
                      onPressed: () => setState(() => _selectedModule = i),
                      child: Text(_moduleLabels[i]),
                    )
                  : Button(
                      onPressed: () => setState(() => _selectedModule = i),
                      child: Text(_moduleLabels[i]),
                    );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    return switch (_selectedModule) {
      0 => _EditaisRegistros(),
      1 => _LicitacoesRegistros(),
      2 => _AtasRegistros(),
      3 => _AjustesRegistros(),
      _ => const SizedBox(),
    };
  }
}

// ── Sub-listas de registros ──────────────────────────────────────────────────

class _EditaisRegistros extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(editaisDaoProvider).watchAll();
    return _RecordsListView(
      stream: stream,
      itemBuilder: (ctx, item) => _RecordTile(
        title: 'Edital ${item.codigoEdital}',
        subtitle: '${item.entidade} — ${item.municipio}',
        status: item.status,
        date: item.updatedAt,
      ),
    );
  }
}

class _LicitacoesRegistros extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(licitacoesDaoProvider).watchAll();
    return _RecordsListView(
      stream: stream,
      itemBuilder: (ctx, item) => _RecordTile(
        title: 'Licitação ${item.codigoEdital}',
        subtitle: '${item.entidade} — ${item.municipio}',
        status: item.status,
        date: item.updatedAt,
      ),
    );
  }
}

class _AtasRegistros extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(atasDaoProvider).watchAll();
    return _RecordsListView(
      stream: stream,
      itemBuilder: (ctx, item) => _RecordTile(
        title: 'Ata ${item.codigoAta}',
        subtitle: '${item.entidade} — ${item.municipio}',
        status: item.status,
        date: item.updatedAt,
      ),
    );
  }
}

class _AjustesRegistros extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(ajustesDaoProvider).watchAll();
    return _RecordsListView(
      stream: stream,
      itemBuilder: (ctx, item) => _RecordTile(
        title: 'Ajuste #${item.id}',
        subtitle: '${item.entidade} — ${item.municipio}',
        status: item.status,
        date: item.updatedAt,
      ),
    );
  }
}

// ── Helpers de UI ────────────────────────────────────────────────────────────

class _RecordsListView<T> extends StatelessWidget {
  final Stream<List<T>> stream;
  final Widget Function(BuildContext, T) itemBuilder;

  const _RecordsListView({
    required this.stream,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: ProgressRing());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const Center(
            child: Text('Nenhum registro encontrado.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (c, i) => itemBuilder(c, items[i]),
        );
      },
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;

  const _RecordTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = status == 'sent';
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSent
                    ? const Color(0xFFC8E6C9)
                    : const Color(0xFFFFE0B2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isSent ? 'Enviado' : 'Rascunho',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Text(
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
