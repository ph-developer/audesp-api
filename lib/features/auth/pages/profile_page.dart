import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/secure_storage_service.dart';
import '../auth_providers.dart';

/// Página para o usuário comum editar apenas o próprio cadastro.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome;
  late TextEditingController _municipio;
  late TextEditingController _entidade;
  late TextEditingController _senha;
  bool _obscure = true;
  bool _saving = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = ref.read(localSessionProvider);
    _nome = TextEditingController(text: _user?.nome ?? '');
    _municipio = TextEditingController(text: _user?.municipio ?? '');
    _entidade = TextEditingController(text: _user?.entidade ?? '');
    _senha = TextEditingController();
  }

  @override
  void dispose() {
    _nome.dispose();
    _municipio.dispose();
    _entidade.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;
    setState(() => _saving = true);

    final dao = ref.read(usersDaoProvider);
    final storage = ref.read(secureStorageServiceProvider);

    try {
      await dao.updateUser(
        UsersCompanion(
          id: Value(_user!.id),
          nome: Value(_nome.text.trim()),
          email: Value(_user!.email),
          municipio: Value(_municipio.text.trim()),
          entidade: Value(_entidade.text.trim()),
          isAdmin: Value(_user!.isAdmin),
        ),
      );

      if (_senha.text.isNotEmpty) {
        await storage.storePassword(_user!.email, _senha.text);
      }

      // Atualiza o objeto na sessão local
      final updated = await dao.findById(_user!.id);
      if (updated != null) {
        ref.read(localSessionProvider.notifier).login(updated);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso.')),
        );
        Navigator.of(context).pop();
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // E-mail (somente leitura)
                    TextFormField(
                      initialValue: _user?.email ?? '',
                      decoration: const InputDecoration(
                        labelText: 'E-mail AUDESP',
                        helperText: 'O e-mail não pode ser alterado',
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nome,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _municipio,
                      decoration:
                          const InputDecoration(labelText: 'Município'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _entidade,
                      decoration:
                          const InputDecoration(labelText: 'Entidade'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senha,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Nova senha AUDESP (deixe em branco para manter)',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              _saving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Salvar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
