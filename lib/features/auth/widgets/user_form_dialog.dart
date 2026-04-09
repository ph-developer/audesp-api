import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_async_button.dart';
import '../../../shared/widgets/audesp_dialog.dart';

/// Abre o diálogo de criação/edição de usuário usando o sistema responsivo.
Future<bool?> showUserFormDialog(BuildContext context, {User? user}) {
  return showAudespDialog<bool>(
    context: context,
    size: DialogSize.small,
    builder: (_) => UserFormDialog(user: user),
  );
}

/// Diálogo para criar ou editar um cadastro de usuário local.
/// Não define senha — o usuário configura as credenciais AUDESP no primeiro login.
class UserFormDialog extends ConsumerStatefulWidget {
  final User? user;

  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.user?.nome ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final dao = ref.read(usersDaoProvider);
    try {
      if (_isEdit) {
        await dao.updateUser(
          UsersCompanion(
            id: Value(widget.user!.id),
            nome: Value(_nome.text.trim()),
            email: Value(_email.text.trim()),
          ),
        );
      } else {
        await dao.insertUser(
          UsersCompanion.insert(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar usuário' : 'Novo usuário'),
      content: SizedBox(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'E-mail AUDESP',
                  helperText: 'Será usado como login e nas chamadas à API',
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isEdit,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obrigatório';
                  if (!v.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A senha AUDESP será configurada pelo próprio usuário no primeiro login.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        AudespAsyncButton(
          onPressed: _save,
          label: _isEdit ? 'Salvar' : 'Criar',
        ),
      ],
    );
  }
}


/// Diálogo para criar ou editar um perfil de usuário local.
/// Ao confirmar, persiste no SQLite e armazena a senha no secure storage.
///
