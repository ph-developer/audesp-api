import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/secure_storage_service.dart';
import '../auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  User? _selectedUser;
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_selectedUser == null) return;
    setState(() {
      _error = null;
      _loading = true;
    });

    final ok = await ref
        .read(secureStorageServiceProvider)
        .verifyPassword(_selectedUser!.email, _passwordController.text);

    setState(() => _loading = false);

    if (!mounted) return;
    if (ok) {
      ref.read(localSessionProvider.notifier).login(_selectedUser!);
      // GoRouter redirect cuida do redirecionamento
    } else {
      setState(() => _error = 'Senha incorreta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersDaoProvider).watchAll();

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AUDESP API',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
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
                  Text(
                    'Selecione seu perfil',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<User>>(
                    stream: usersAsync,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final users = snapshot.data!;
                      if (users.isEmpty) {
                        return Column(
                          children: [
                            const Text(
                              'Nenhum perfil cadastrado.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.push('/users'),
                              child: const Text('Cadastrar primeiro perfil'),
                            ),
                          ],
                        );
                      }
                      return DropdownButtonFormField<User>(
                        initialValue: _selectedUser,
                        hint: const Text('Selecione...'),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: users
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text('${u.nome} — ${u.entidade}'),
                              ),
                            )
                            .toList(),
                        onChanged: (u) => setState(() {
                          _selectedUser = u;
                          _error = null;
                          _passwordController.clear();
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedUser != null) ...[
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Senha AUDESP',
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
                      onSubmitted: (_) => _doLogin(),
                    ),
                    const SizedBox(height: 20),
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
                  const SizedBox(height: 12),
                  const Divider(),
                  TextButton.icon(
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Gerenciar perfis'),
                    onPressed: () => context.push('/users'),
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
