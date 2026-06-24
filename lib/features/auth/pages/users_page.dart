import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_delete_dialog.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/user_form_dialog.dart';

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersFuture = ref.watch(usersDaoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar perfis')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Novo perfil'),
      ),
      body: FutureBuilder<List<User>>(
        future: usersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              message: 'Nenhum perfil cadastrado.\nClique em + para adicionar.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final u = users[i];
              return DocumentCard(
                leading: CircleAvatar(child: Text(u.nome[0].toUpperCase())),
                title: u.nome,
                subtitle: Text(u.email),
                onDelete: () => _confirmDelete(context, ref, u),
                onEdit: () => _openForm(context, ref, u),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    User? user,
  ) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) async {
    final confirmed = await showAudespDeleteDialog(
      context: context,
      title: 'Excluir perfil',
      entityName: user.nome,
      entityLabel: 'o perfil de',
    );

    if (confirmed == true) {
      try {
        await ref.read(usersDaoProvider).deleteById(user.id);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
