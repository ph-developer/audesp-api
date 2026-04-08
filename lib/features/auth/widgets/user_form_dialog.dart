import 'package:drift/drift.dart' hide Column;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';

/// DiÃ¡logo para criar ou editar um cadastro de usuÃ¡rio local.
/// NÃ£o define senha â€” o usuÃ¡rio configura as credenciais AUDESP no primeiro login.
class UserFormDialog extends ConsumerStatefulWidget {
  final User? user;

  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _municipio;
  late final TextEditingController _entidade;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.user?.nome ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _municipio = TextEditingController(text: widget.user?.municipio ?? '');
    _entidade = TextEditingController(text: widget.user?.entidade ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _municipio.dispose();
    _entidade.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_nome.text.trim().isEmpty) return 'Nome Ã© obrigatÃ³rio.';
    if (_email.text.trim().isEmpty) return 'E-mail Ã© obrigatÃ³rio.';
    if (!_isEdit && !_email.text.contains('@')) return 'E-mail invÃ¡lido.';
    if (_municipio.text.trim().isEmpty) return 'MunicÃ­pio Ã© obrigatÃ³rio.';
    if (_entidade.text.trim().isEmpty) return 'Entidade Ã© obrigatÃ³ria.';
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final dao = ref.read(usersDaoProvider);
    try {
      if (_isEdit) {
        await dao.updateUser(
          UsersCompanion(
            id: Value(widget.user!.id),
            nome: Value(_nome.text.trim()),
            email: Value(_email.text.trim()),
            municipio: Value(_municipio.text.trim()),
            entidade: Value(_entidade.text.trim()),
            isAdmin: Value(widget.user!.isAdmin),
          ),
        );
      } else {
        await dao.insertUser(
          UsersCompanion.insert(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
            municipio: _municipio.text.trim(),
            entidade: _entidade.text.trim(),
          ),
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMessage = 'Erro ao salvar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(_isEdit ? 'Editar usuÃ¡rio' : 'Novo usuÃ¡rio'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoLabel(
              label: 'Nome',
              child: TextBox(
                controller: _nome,
                placeholder: 'Nome completo',
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'E-mail AUDESP',
              child: TextBox(
                controller: _email,
                placeholder: 'email@municipio.sp.gov.br',
                keyboardType: TextInputType.emailAddress,
                enabled: !_isEdit,
              ),
            ),
            if (!_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'SerÃ¡ usado como login e nas chamadas Ã  API',
                  style: FluentTheme.of(context).typography.caption,
                ),
              ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'MunicÃ­pio',
              child: TextBox(
                controller: _municipio,
                placeholder: 'MunicÃ­pio',
              ),
            ),
            const SizedBox(height: 12),
            InfoLabel(
              label: 'Entidade',
              child: TextBox(
                controller: _entidade,
                placeholder: 'Entidade',
              ),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 12),
              const InfoBar(
                title: Text('Senha AUDESP'),
                content: Text(
                  'A senha AUDESP serÃ¡ configurada pelo prÃ³prio usuÃ¡rio no primeiro login.',
                ),
                severity: InfoBarSeverity.info,
                isLong: true,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              InfoBar(
                title: Text(_errorMessage!),
                severity: InfoBarSeverity.error,
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: ProgressRing(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}
