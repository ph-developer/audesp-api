import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_async_button.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_text_field.dart';

/// Abre o diálogo de criação/edição de usuário usando o sistema responsivo.
Future<bool?> showUserFormDialog(BuildContext context, {User? user}) {
  return showAudespDialog<bool>(
    context: context,
    size: DialogSize.small,
    builder: (_) => UserFormDialog(user: user),
  );
}

/// Diálogo para criar ou editar um cadastro de usuário local.
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

  bool _isAdmin = false;
  bool _permEdital = false;
  bool _permLicitacao = false;
  bool _permAta = false;
  bool _permAjuste = false;
  bool _permEstimativa = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.user?.nome ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');

    if (widget.user != null) {
      _isAdmin = widget.user!.isAdmin;
      _permEdital = widget.user!.hasPermission(AppPermissions.edital);
      _permLicitacao = widget.user!.hasPermission(AppPermissions.licitacao);
      _permAta = widget.user!.hasPermission(AppPermissions.ata);
      _permAjuste = widget.user!.hasPermission(AppPermissions.ajuste);
      _permEstimativa = widget.user!.hasPermission(AppPermissions.estimativa);
    }
  }

  int _buildPermissions() {
    int p = 0;
    if (_permEdital) p |= AppPermissions.edital;
    if (_permLicitacao) p |= AppPermissions.licitacao;
    if (_permAta) p |= AppPermissions.ata;
    if (_permAjuste) p |= AppPermissions.ajuste;
    if (_permEstimativa) p |= AppPermissions.estimativa;
    return p;
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
          id: widget.user!.id,
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          isAdmin: _isAdmin,
          permissions: _buildPermissions(),
        );
      } else {
        await dao.insertUser(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          passwordHash: null,
          isAdmin: _isAdmin,
          permissions: _buildPermissions(),
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
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AudespTextField(
                  label: 'Nome',
                  controller: _nome,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 12),
                AudespTextField(
                  label: 'E-mail AUDESP',
                  controller: _email,
                  helperText: 'Será usado como login e nas chamadas à API',
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
                              'A senha será configurada pelo próprio usuário no primeiro login.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                SwitchListTile(
                  title: const Text('Administrador'),
                  subtitle: const Text('Tem acesso total ao sistema'),
                  value: _isAdmin,
                  onChanged: (v) => setState(() => _isAdmin = v),
                ),
                if (!_isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Permissões de Módulo', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  AudespCheckbox(
                    label: 'Edital',
                    value: _permEdital,
                    onChanged: (v) => setState(() => _permEdital = v ?? false),
                  ),
                  AudespCheckbox(
                    label: 'Licitação',
                    value: _permLicitacao,
                    onChanged: (v) => setState(() => _permLicitacao = v ?? false),
                  ),
                  AudespCheckbox(
                    label: 'Ata',
                    value: _permAta,
                    onChanged: (v) => setState(() => _permAta = v ?? false),
                  ),
                  AudespCheckbox(
                    label: 'Ajuste',
                    value: _permAjuste,
                    onChanged: (v) => setState(() => _permAjuste = v ?? false),
                  ),
                  AudespCheckbox(
                    label: 'Estimativa',
                    value: _permEstimativa,
                    onChanged: (v) => setState(() => _permEstimativa = v ?? false),
                  ),
                ],
              ],
            ),
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
