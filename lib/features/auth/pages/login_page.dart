import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
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
    final username = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Preencha o usu\u00e1rio e a senha.');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      if (username == 'admin') {
        if (password == AppEnv.adminPassword) {
          ref.read(localSessionProvider.notifier).login(buildAdminUser());
        } else {
          setState(() => _error = 'Senha de administrador incorreta.');
        }
        return;
      }

      final dao = ref.read(usersDaoProvider);

      final user = await dao.findByEmail(username);
      if (user == null) {
        setState(() => _error = 'Usu\u00e1rio n\u00e3o encontrado.');
        return;
      }

      if (user.passwordHash == null) {
        if (password == AppEnv.defaultUserPassword) {
          final hash = PasswordHasher.hash(username, password);
          await dao.setPasswordHash(user.id, hash);
          ref.read(localSessionProvider.notifier).login(user);
        } else {
          setState(() => _error =
              'Senha incorreta. Use a senha padr\u00e3o fornecida pelo administrador.');
        }
      } else {
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
    return ColoredBox(
      color: FluentTheme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 48,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AUDESP API',
                    style: FluentTheme.of(context)
                        .typography
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: FluentTheme.of(context).accentColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sistema de Presta\u00e7\u00e3o de Dados \u2014 TCE-SP',
                    style: FluentTheme.of(context).typography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  InfoLabel(
                    label: 'Usu\u00e1rio (e-mail ou admin)',
                    child: TextBox(
                      controller: _emailCtrl,
                      placeholder: 'exemplo@municipio.sp.gov.br',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InfoLabel(
                    label: 'Senha',
                    child: TextBox(
                      controller: _passwordCtrl,
                      placeholder: 'Senha',
                      obscureText: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      onSubmitted: (_) => _doLogin(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    InfoBar(
                      title: Text(_error!),
                      severity: InfoBarSeverity.error,
                      isLong: false,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _doLogin,
                    child: _loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: ProgressRing(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

