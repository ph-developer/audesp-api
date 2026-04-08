import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_env.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/password_hasher.dart';
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
  bool _obscure = true;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
      // ── Administrador ────────────────────────────────────────────────────
      if (username == 'admin') {
        if (password == AppEnv.adminPassword) {
          ref.read(localSessionProvider.notifier).login(buildAdminUser());
        } else {
          setState(() => _error = 'Senha de administrador incorreta.');
        }
        return;
      }

      // ── Usuário comum ────────────────────────────────────────────────────
      final dao = ref.read(usersDaoProvider);

      final user = await dao.findByEmail(username);
      if (user == null) {
        setState(() => _error = 'Usuário não encontrado.');
        return;
      }

      if (user.passwordHash == null) {
        // Primeiro acesso: aceitar senha padrão e salvar hash no banco
        if (password == AppEnv.defaultUserPassword) {
          final hash = PasswordHasher.hash(username, password);
          await dao.setPasswordHash(user.id, hash);
          ref.read(localSessionProvider.notifier).login(user);
        } else {
          setState(() => _error =
              'Senha incorreta. Use a senha padrão fornecida pelo administrador.');
        }
      } else {
        // Acesso normal: verificar hash do banco
        if (PasswordHasher.verify(username, password, user.passwordHash!)) {
          ref.read(localSessionProvider.notifier).login(user);
        } else {
          setState(() => _error = 'Senha incorreta.');
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                    Icon(
                      Icons.account_balance_outlined,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AUDESP API',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistema de Prestação de Dados — TCE-SP',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Formulário ──────────────────────────────────────
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      onChanged: (_) => setState(() => _error = null),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        errorText: _error,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _doLogin(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obrigatório' : null,
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
