import 'package:drift/drift.dart' hide Column;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_env.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/secure_storage_service.dart';
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
  late TextEditingController _nome;

  // Seção de senha do sistema
  final _sysPwAtualCtrl = TextEditingController();
  final _sysPwNovaCtrl = TextEditingController();
  bool _obscureSysPwAtual = true;
  bool _obscureSysPwNova = true;
  bool _savingSysPw = false;

  // Seção de credenciais AUDESP
  final _senhaAtualCtrl = TextEditingController();
  final _senhaNovaCtr1 = TextEditingController();
  bool _obscureAtual = true;
  bool _obscureNova = true;

  bool _saving = false;
  bool _savingPassword = false;
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
    _senhaAtualCtrl.dispose();
    _senhaNovaCtr1.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nome.text.trim().isEmpty) return;
    if (_user == null) return;
    setState(() => _saving = true);

    final dao = ref.read(usersDaoProvider);

    try {
      await dao.updateUser(
        UsersCompanion(
          id: Value(_user!.id),
          nome: Value(_nome.text.trim()),
          email: Value(_user!.email),
          municipio: Value(_user!.municipio),
          entidade: Value(_user!.entidade),
          isAdmin: Value(_user!.isAdmin),
        ),
      );

      final updated = await dao.findById(_user!.id);
      if (updated != null) {
        ref.read(localSessionProvider.notifier).login(updated);
        _user = updated;
      }

      if (mounted) {
        displayInfoBar(context, builder: (ctx, close) => const InfoBar(
          title: Text('Perfil atualizado com sucesso.'),
          severity: InfoBarSeverity.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(context, builder: (ctx, close) => InfoBar(
          title: Text('Erro ao salvar perfil: $e'),
          severity: InfoBarSeverity.error,
        ));
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
      displayInfoBar(context, builder: (ctx, close) => const InfoBar(
        title: Text('Preencha a senha atual e a nova senha.'),
        severity: InfoBarSeverity.warning,
      ));
      return;
    }
    if (next.length < 6) {
      displayInfoBar(context, builder: (ctx, close) => const InfoBar(
        title: Text('A nova senha deve ter ao menos 6 caracteres.'),
        severity: InfoBarSeverity.warning,
      ));
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
          displayInfoBar(context, builder: (ctx, close) => const InfoBar(
            title: Text('Senha atual incorreta.'),
            severity: InfoBarSeverity.error,
          ));
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
        displayInfoBar(context, builder: (ctx, close) => const InfoBar(
          title: Text('Senha do sistema atualizada.'),
          severity: InfoBarSeverity.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(context, builder: (ctx, close) => InfoBar(
          title: Text('Erro ao atualizar senha: $e'),
          severity: InfoBarSeverity.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _savingSysPw = false);
    }
  }

  Future<void> _savePassword() async {
    if (_user == null) return;
    final current = _senhaAtualCtrl.text;
    final next = _senhaNovaCtr1.text;

    if (current.isEmpty || next.isEmpty) {
      displayInfoBar(context, builder: (ctx, close) => const InfoBar(
        title: Text('Preencha a senha atual e a nova senha.'),
        severity: InfoBarSeverity.warning,
      ));
      return;
    }
    if (next.length < 4) {
      displayInfoBar(context, builder: (ctx, close) => const InfoBar(
        title: Text('A nova senha deve ter ao menos 4 caracteres.'),
        severity: InfoBarSeverity.warning,
      ));
      return;
    }

    setState(() => _savingPassword = true);
    final storage = ref.read(secureStorageServiceProvider);

    try {
      final ok = await storage.verifyPassword(_user!.email, current);
      if (!ok) {
        if (mounted) {
          displayInfoBar(context, builder: (ctx, close) => const InfoBar(
            title: Text('Senha atual incorreta.'),
            severity: InfoBarSeverity.error,
          ));
        }
        return;
      }

      await storage.storePassword(_user!.email, next);
      _senhaAtualCtrl.clear();
      _senhaNovaCtr1.clear();

      if (mounted) {
        displayInfoBar(context, builder: (ctx, close) => const InfoBar(
          title: Text('Senha AUDESP atualizada com sucesso.'),
          severity: InfoBarSeverity.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(context, builder: (ctx, close) => InfoBar(
          title: Text('Erro ao atualizar senha: $e'),
          severity: InfoBarSeverity.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Meu perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.go('/edital'),
        ),
      ),
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Dados cadastrais ────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Dados cadastrais',
                        style: FluentTheme.of(context).typography.bodyStrong,
                      ),
                      const SizedBox(height: 16),
                      InfoLabel(
                        label: 'E-mail AUDESP',
                        child: TextBox(
                          controller: TextEditingController(text: _user?.email ?? ''),
                          enabled: false,
                          placeholder: 'O e-mail n\u00e3o pode ser alterado',
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoLabel(
                        label: 'Nome',
                        child: TextBox(controller: _nome),
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
                                  child: ProgressRing(strokeWidth: 2),
                                )
                              : const Text('Salvar dados'),
                        ),
                      ),
                    ],
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
                            style: FluentTheme.of(context).typography.bodyStrong,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Senha usada para acessar este aplicativo.',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                      const SizedBox(height: 16),
                      InfoLabel(
                        label: 'Senha atual',
                        child: TextBox(
                          controller: _sysPwAtualCtrl,
                          obscureText: _obscureSysPwAtual,
                          suffix: IconButton(
                            icon: Icon(_obscureSysPwAtual
                                ? Icons.visibility_off
                                : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _obscureSysPwAtual = !_obscureSysPwAtual),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoLabel(
                        label: 'Nova senha',
                        child: TextBox(
                          controller: _sysPwNovaCtrl,
                          obscureText: _obscureSysPwNova,
                          suffix: IconButton(
                            icon: Icon(_obscureSysPwNova
                                ? Icons.visibility_off
                                : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () => setState(
                                () => _obscureSysPwNova = !_obscureSysPwNova),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Mínimo de 6 caracteres',
                            style: FluentTheme.of(context).typography.caption),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Button(
                          onPressed: _savingSysPw ? null : _saveSystemPassword,
                          child: _savingSysPw
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: ProgressRing(strokeWidth: 2),
                                )
                              : const Text('Alterar senha do sistema'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Credenciais AUDESP ───────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Senha AUDESP',
                            style: FluentTheme.of(context).typography.bodyStrong,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Altere aqui se sua senha do sistema AUDESP foi modificada.',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                      const SizedBox(height: 16),
                      InfoLabel(
                        label: 'Senha atual',
                        child: TextBox(
                          controller: _senhaAtualCtrl,
                          obscureText: _obscureAtual,
                          suffix: IconButton(
                            icon: Icon(_obscureAtual
                                ? Icons.visibility_off
                                : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _obscureAtual = !_obscureAtual),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoLabel(
                        label: 'Nova senha',
                        child: TextBox(
                          controller: _senhaNovaCtr1,
                          obscureText: _obscureNova,
                          suffix: IconButton(
                            icon: Icon(_obscureNova
                                ? Icons.visibility_off
                                : Icons.visibility,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNova = !_obscureNova),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Button(
                          onPressed: _savingPassword ? null : _savePassword,
                          child: _savingPassword
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: ProgressRing(strokeWidth: 2),
                                )
                              : const Text('Atualizar senha AUDESP'),
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

