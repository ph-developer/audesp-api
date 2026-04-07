import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/secure_storage_service.dart';

/// Diálogo para criar ou editar um perfil de usuário local.
/// Ao confirmar, persiste no SQLite e armazena a senha no secure storage.
///
/// [isCurrentUserAdmin] — quando `true`, exibe o toggle de administrador.
class UserFormDialog extends ConsumerStatefulWidget {
  /// Se [user] for não-nulo, é edição; caso contrário, criação.
  final User? user;

  /// Quando verdadeiro, mostra o campo "Administrador" no formulário.
  final bool isCurrentUserAdmin;

  const UserFormDialog({super.key, this.user, this.isCurrentUserAdmin = false});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _municipio;
  late final TextEditingController _entidade;
  late final TextEditingController _senha;
  bool _obscure = true;
  bool _saving = false;
  bool _isAdmin = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.user?.nome ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _municipio = TextEditingController(text: widget.user?.municipio ?? '');
    _entidade = TextEditingController(text: widget.user?.entidade ?? '');
    _senha = TextEditingController();
    _isAdmin = widget.user?.isAdmin ?? false;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _municipio.dispose();
    _entidade.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final dao = ref.read(usersDaoProvider);
    final storage = ref.read(secureStorageServiceProvider);

    try {
      if (_isEdit) {
        await dao.updateUser(
          UsersCompanion(
            id: Value(widget.user!.id),
            nome: Value(_nome.text.trim()),
            email: Value(_email.text.trim()),
            municipio: Value(_municipio.text.trim()),
            entidade: Value(_entidade.text.trim()),
            isAdmin: Value(_isAdmin),
          ),
        );
        // Atualiza senha apenas se preenchida
        if (_senha.text.isNotEmpty) {
          await storage.storePassword(
              _email.text.trim(), _senha.text);
        }
      } else {
        // Primeiro usuário a ser criado sempre vira admin
        final isFirstUser = (await dao.countUsers()) == 0;
        final id = await dao.insertUser(
          UsersCompanion.insert(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
            municipio: _municipio.text.trim(),
            entidade: _entidade.text.trim(),
            isAdmin: Value(isFirstUser || _isAdmin),
          ),
        );
        if (id > 0) {
          await storage.storePassword(_email.text.trim(), _senha.text);
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _saving = false);
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
      title: Text(_isEdit ? 'Editar perfil' : 'Novo perfil'),
      content: SizedBox(
        width: 380,
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
                decoration: const InputDecoration(labelText: 'E-mail AUDESP'),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isEdit,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obrigatório';
                  if (!v.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _municipio,
                decoration: const InputDecoration(labelText: 'Município'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _entidade,
                decoration: const InputDecoration(labelText: 'Entidade'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              if (widget.isCurrentUserAdmin) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Administrador'),
                  subtitle: const Text('Acesso ao painel de administração'),
                  value: _isAdmin,
                  onChanged: (v) => setState(() => _isAdmin = v),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _senha,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: _isEdit
                      ? 'Nova senha AUDESP (deixe em branco para manter)'
                      : 'Senha AUDESP',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (!_isEdit && (v == null || v.isEmpty)) {
                    return 'Obrigatório';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}
