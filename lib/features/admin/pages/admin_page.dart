import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _AdminPageState extends ConsumerState<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.people_outlined), text: 'Usuários'),
            Tab(icon: Icon(Icons.cloud_outlined), text: 'Ambiente'),
            Tab(icon: Icon(Icons.folder_outlined), text: 'Registros'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _UsersTab(),
          _EnvironmentTab(),
          _RegistrosTab(),
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
              return const Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data!;
            if (users.isEmpty) {
              return const Center(
                child: Text('Nenhum usuário cadastrado.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final u = users[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: u.isAdmin
                          ? Theme.of(ctx).colorScheme.primary
                          : null,
                      foregroundColor: u.isAdmin
                          ? Theme.of(ctx).colorScheme.onPrimary
                          : null,
                      child: Text(u.nome[0].toUpperCase()),
                    ),
                    title: Row(
                      children: [
                        Text(u.nome),
                        if (u.isAdmin) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('Admin'),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(fontSize: 11),
                            backgroundColor:
                                Theme.of(ctx).colorScheme.primaryContainer,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text('${u.email}\n${u.entidade} — ${u.municipio}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _openForm(ctx, ref, u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Excluir',
                          color: Theme.of(ctx).colorScheme.error,
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
          child: FloatingActionButton.extended(
            heroTag: 'admin_users_fab',
            onPressed: () => _openForm(context, ref, null),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Novo usuário'),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, User? user) =>
      showDialog(
        context: context,
        builder: (_) =>
            UserFormDialog(user: user, isCurrentUserAdmin: true),
      );

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, User user) async {
    final session = ref.read(localSessionProvider);
    if (session?.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não é possível excluir o usuário logado.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir usuário'),
        content:
            Text('Deseja excluir o perfil de "${user.nome}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RadioGroup<Environment>(
              groupValue: current,
              onChanged: (v) {
                if (v != null) {
                  ref
                      .read(environmentProvider.notifier)
                      .setEnvironment(v);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ambiente da API AUDESP',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Divider(),
                  ...Environment.values.map(
                    (env) => RadioListTile<Environment>(
                      value: env,
                      title: Text(env.label),
                      subtitle: Text(env.baseUrl),
                      secondary: env == Environment.piloto
                          ? Chip(
                              label: const Text('Teste'),
                              backgroundColor:
                                  Colors.orange.shade100,
                            )
                          : Chip(
                              label: const Text('Produção'),
                              backgroundColor: Colors.green.shade100,
                            ),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A seleção de ambiente aplica-se a todas as chamadas API da sessão.',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        // Filtro de módulo
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<int>(
            segments: List.generate(
              _moduleLabels.length,
              (i) => ButtonSegment(
                value: i,
                label: Text(_moduleLabels[i]),
              ),
            ),
            selected: {_selectedModule},
            onSelectionChanged: (s) =>
                setState(() => _selectedModule = s.first),
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
          return const Center(child: CircularProgressIndicator());
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
            Chip(
              label: Text(isSent ? 'Enviado' : 'Rascunho'),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelStyle: const TextStyle(fontSize: 11),
              backgroundColor: isSent
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
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
