import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/utils/local_prefs.dart';
import '../../../core/utils/password_hasher.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadLastUser();
  }

  Future<void> _loadLastUser() async {
    final last = await LocalPrefs.getLastUser();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (last != null) {
        _emailCtrl.text = last;
        _passwordFocus.requestFocus();
      } else {
        _emailFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _loading = true;
    });

    final username = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    try {
      // ── Usuário ──────────────────────────────────────────────────────────
      final dao = ref.read(usersDaoProvider);

      final user = await dao.findByEmail(username);
      if (!mounted) return;
      if (user == null) {
        setState(() => _error = 'Usuário não encontrado.');
        return;
      }

      if (!user.isAdmin && user.permissions == 0) {
        setState(() => _error = 'Usuário sem permissões de acesso.');
        return;
      }

      if (user.passwordHash == null) {
        // Primeiro acesso: forçar criação de senha via modal
        final newPassword = await _showSetPasswordModal(context, password);
        if (newPassword != null) {
          final hash = PasswordHasher.hash(username, newPassword);
          await dao.setPasswordHash(user.id, hash);
          final updatedUser = await dao.findById(user.id);
          ref.read(localSessionProvider.notifier).login(updatedUser ?? user);
          LocalPrefs.setLastUser(username);
        }
        return;
      } else {
        if (password.isEmpty) {
          setState(() => _error = 'Senha obrigatória.');
          return;
        }
        // Acesso normal: verificar hash do banco
        if (PasswordHasher.verify(username, password, user.passwordHash!)) {
          ref.read(localSessionProvider.notifier).login(user);
          LocalPrefs.setLastUser(username);
        } else {
          setState(() => _error = 'Senha incorreta.');
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showSetPasswordModal(
    BuildContext context,
    String initialPassword,
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final ctrl = TextEditingController(text: initialPassword);
        final confirmCtrl = TextEditingController();
        final formKey = GlobalKey<FormState>();
        bool obscure1 = true;
        bool obscure2 = true;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: const Text('Definir Nova Senha'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Este é o seu primeiro acesso. Por favor, defina uma senha para sua conta.',
                    ),
                    const SizedBox(height: 16),
                    AudespTextField(
                      label: 'Nova senha',
                      controller: ctrl,
                      obscureText: obscure1,
                      suffixIcon: AudespIconButton(
                        icon: obscure1
                            ? Icons.visibility_off
                            : Icons.visibility,
                        tooltip: obscure1 ? 'Mostrar senha' : 'Ocultar senha',
                        onPressed: () =>
                            setModalState(() => obscure1 = !obscure1),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    AudespTextField(
                      label: 'Confirmar senha',
                      controller: confirmCtrl,
                      obscureText: obscure2,
                      suffixIcon: AudespIconButton(
                        icon: obscure2
                            ? Icons.visibility_off
                            : Icons.visibility,
                        tooltip: obscure2 ? 'Mostrar senha' : 'Ocultar senha',
                        onPressed: () =>
                            setModalState(() => obscure2 = !obscure2),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obrigatório';
                        if (v != ctrl.text) return 'As senhas não coincidem';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, ctrl.text);
                    }
                  },
                  child: const Text('Salvar e Entrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Image.asset(
                      'assets/logo_audesp.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistema de Prestação de Dados — TCE-SP',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Formulário ──────────────────────────────────────
                    AudespTextField(
                      label: 'E-mail',
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      prefixIcon: const Icon(Icons.person_outline),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _error = null),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        isDense: true,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: AudespIconButton(
                          icon: _obscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                          tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        errorText: _error,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _doLogin(),
                      validator: (v) => null, // Validated manually in _doLogin
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _doLogin,
                      child: _loading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Entrar'),
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
