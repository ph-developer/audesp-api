import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/secure_storage_service.dart';
import '../widgets/user_form_dialog.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersStream = ref.watch(usersDaoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar perfis')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Novo perfil'),
      ),
      body: StreamBuilder<List<User>>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(
              child: Text('Nenhum perfil cadastrado.\nClique em + para adicionar.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final u = users[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(u.nome[0].toUpperCase()),
                  ),
                  title: Text(u.nome),
                  subtitle: Text('${u.email}\n${u.entidade} — ${u.municipio}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        onPressed: () => _openForm(context, ref, u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Excluir',
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => _confirmDelete(context, ref, u),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(
      BuildContext context, WidgetRef ref, User? user) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir perfil'),
        content: Text(
            'Tem certeza que deseja excluir o perfil de "${user.nome}"?'),
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
