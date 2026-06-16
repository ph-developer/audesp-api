import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_env.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/password_hasher.dart';
import '../auth_providers.dart';

/// Página para o usuário comum editar o próprio cadastro e as credenciais AUDESP.
/// Administradores são redirecionados — não possuem credenciais AUDESP.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome;

  // Seção de senha do sistema
  final _sysPwAtualCtrl = TextEditingController();
  final _sysPwNovaCtrl = TextEditingController();
  bool _obscureSysPwAtual = true;
  bool _obscureSysPwNova = true;
  bool _savingSysPw = false;

  bool _saving = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = ref.read(localSessionProvider);
    _nome = TextEditingController(text: _user?.nome ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _sysPwAtualCtrl.dispose();
    _sysPwNovaCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;
    setState(() => _saving = true);

    final dao = ref.read(usersDaoProvider);

    try {
      await dao.updateUser(
        id: _user!.id,
        nome: _nome.text.trim(),
        email: _user!.email,
        isAdmin: _user!.isAdmin,
        permissions: _user!.permissions,
      );

      final updated = await dao.findById(_user!.id);
      if (updated != null) {
        ref.read(localSessionProvider.notifier).login(updated);
        _user = updated;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar perfil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSystemPassword() async {
    if (_user == null) return;
    final current = _sysPwAtualCtrl.text;
    final next = _sysPwNovaCtrl.text;

    if (current.isEmpty || next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a senha atual e a nova senha.')),
      );
      return;
    }
    if (next.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A nova senha deve ter ao menos 6 caracteres.')),
      );
      return;
    }

    setState(() => _savingSysPw = true);
    final dao = ref.read(usersDaoProvider);

    try {
      // Verifica senha atual
      bool ok;
      if (_user!.passwordHash == null) {
        ok = current == AppEnv.defaultUserPassword;
      } else {
        ok = PasswordHasher.verify(_user!.email, current, _user!.passwordHash!);
      }

      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senha atual incorreta.')),
          );
        }
        return;
      }

      final newHash = PasswordHasher.hash(_user!.email, next);
      await dao.setPasswordHash(_user!.id, newHash);

      // Recarrega usuário da sessão (passwordHash pode ter mudado)
      final updated = await dao.findById(_user!.id);
      if (updated != null) {
        ref.read(localSessionProvider.notifier).login(updated);
        _user = updated;
      }

      _sysPwAtualCtrl.clear();
      _sysPwNovaCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha do sistema atualizada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar senha: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingSysPw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        leading: BackButton(onPressed: () => context.go('/edital')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Dados cadastrais ────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Dados cadastrais',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _saving ? null : _saveProfile,
                            child: _saving
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Salvar dados'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Senha do sistema ─────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.key_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Senha do sistema',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Senha usada para acessar este aplicativo.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sysPwAtualCtrl,
                        obscureText: _obscureSysPwAtual,
                        decoration: InputDecoration(
                          labelText: 'Senha atual',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureSysPwAtual
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscureSysPwAtual = !_obscureSysPwAtual),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sysPwNovaCtrl,
                        obscureText: _obscureSysPwNova,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          helperText: 'Mínimo de 6 caracteres',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureSysPwNova
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscureSysPwNova = !_obscureSysPwNova),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: _savingSysPw ? null : _saveSystemPassword,
                          child: _savingSysPw
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Alterar senha do sistema'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

