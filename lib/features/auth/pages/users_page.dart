import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => _openForm(context, ref, null),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 6),
                  Text('Novo perfil'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<User>>(
            stream: usersStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: ProgressRing());
              }
              final users = snapshot.data!;
              if (users.isEmpty) {
                return const Center(
                  child: Text(
                      'Nenhum perfil cadastrado.\nClique em + para adicionar.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final u = users[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: FluentTheme.of(context).accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                u.nome[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.nome,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(u.email,
                                    style: const TextStyle(fontSize: 12)),
                                Text('${u.entidade} — ${u.municipio}',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _openForm(context, ref, u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            style: ButtonStyle(
                              foregroundColor:
                                  WidgetStatePropertyAll(Color(0xFFB00020)),
                            ),
                            onPressed: () =>
                                _confirmDelete(context, ref, u),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
      builder: (ctx) => ContentDialog(
        title: const Text('Excluir perfil'),
        content: Text(
            'Tem certeza que deseja excluir o perfil de "${user.nome}"?'),
        actions: [
          Button(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(Color(0xFFB00020)),
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

