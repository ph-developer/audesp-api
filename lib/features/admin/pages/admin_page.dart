import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/environments.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/daos/app_settings_dao.dart';
import '../../auth/auth_providers.dart';
import '../../auth/widgets/user_form_dialog.dart';

/// Painel de administração: Usuários · Ambiente · Registros.
/// Acessível apenas por usuários com [User.isAdmin == true].
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        leading: BackButton(onPressed: () => context.go('/edital')),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.people_outlined), text: 'Usuários'),
            Tab(icon: Icon(Icons.cloud_outlined), text: 'Ambiente'),
            Tab(icon: Icon(Icons.auto_fix_high_outlined), text: 'IA / Gemini'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _UsersTab(),
          _EnvironmentTab(),
          _GeminiTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Gerenciamento de usuários
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = ref.read(usersDaoProvider).watchAll();
  }

  void _refresh() {
    setState(() {
      _usersFuture = ref.read(usersDaoProvider).watchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<User>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data!;
            if (users.isEmpty) {
              return const Center(
                child: Text('Nenhum usuário cadastrado.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final u = users[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(u.nome[0].toUpperCase()),
                    ),
                    title: Text(u.nome),
                    subtitle: Text(u.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _openForm(u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Excluir',
                          color: Theme.of(ctx).colorScheme.error,
                          onPressed: () => _confirmDelete(u),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'admin_users_fab',
            onPressed: () => _openForm(null),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Novo usuário'),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(User? user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );
    if (result == true) _refresh();
  }

  Future<void> _confirmDelete(User user) async {
    final session = ref.read(localSessionProvider);
    if (session?.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não é possível excluir o usuário logado.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir usuário'),
        content:
            Text('Deseja excluir o perfil de "${user.nome}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(usersDaoProvider).deleteById(user.id);
      _refresh();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Configurações AUDESP (ambiente + códigos de município e entidade)
// ─────────────────────────────────────────────────────────────────────────────

class _EnvironmentTab extends ConsumerStatefulWidget {
  const _EnvironmentTab();

  @override
  ConsumerState<_EnvironmentTab> createState() => _EnvironmentTabState();
}

class _EnvironmentTabState extends ConsumerState<_EnvironmentTab> {
  final _municipioCtrl = TextEditingController();
  final _entidadeCtrl = TextEditingController();
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _municipioCtrl.dispose();
    _entidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dao = ref.read(appSettingsDaoProvider);
    final m = await dao.get(SettingsKeys.codigoMunicipio);
    final e = await dao.get(SettingsKeys.codigoEntidade);
    if (!mounted) return;
    setState(() {
      _municipioCtrl.text = m ?? '';
      _entidadeCtrl.text = e ?? '';
      _loading = false;
    });
  }

  Future<void> _saveCodes() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(codigoMunicipioProvider.notifier)
          .setValue(_municipioCtrl.text.trim());
      await ref
          .read(codigoEntidadeProvider.notifier)
          .setValue(_entidadeCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final currentEnv = ref.watch(environmentProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Ambiente ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: RadioGroup<Environment>(
                    groupValue: currentEnv,
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(environmentProvider.notifier)
                            .setEnvironment(v);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Ambiente da API AUDESP',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const Divider(),
                        ...Environment.values.map(
                          (env) => RadioListTile<Environment>(
                            value: env,
                            title: Text(env.label),
                            subtitle: Text(env.baseUrl),
                            secondary: env == Environment.piloto
                                ? Chip(
                                    label: const Text('Teste'),
                                    backgroundColor: Colors.orange.shade100,
                                  )
                                : Chip(
                                    label: const Text('Produção'),
                                    backgroundColor: Colors.green.shade100,
                                  ),
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'A seleção de ambiente é persistida e aplica-se a todas as chamadas API.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Códigos de Município e Entidade ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_city_outlined),
                          const SizedBox(width: 12),
                          Text(
                            'Códigos AUDESP',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      TextFormField(
                        controller: _municipioCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código do Município',
                          hintText: 'Ex.: 3550308',
                          helperText:
                              'Código numérico do município conforme cadastro AUDESP.',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _entidadeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código da Entidade',
                          hintText: 'Ex.: 1',
                          helperText:
                              'Código numérico da entidade conforme cadastro AUDESP.',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _saveCodes,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salvar'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Configurações IA / Gemini
// ─────────────────────────────────────────────────────────────────────────────

class _GeminiTab extends ConsumerStatefulWidget {
  const _GeminiTab();

  @override
  ConsumerState<_GeminiTab> createState() => _GeminiTabState();
}

class _GeminiTabState extends ConsumerState<_GeminiTab> {
  final _apiKeyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dao = ref.read(appSettingsDaoProvider);
    final key = await dao.get(SettingsKeys.geminiApiKey);
    final model = await dao.get(SettingsKeys.geminiModel);
    if (!mounted) return;
    setState(() {
      _apiKeyCtrl.text = key ?? '';
      _modelCtrl.text = model ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dao = ref.read(appSettingsDaoProvider);
      final apiKey = _apiKeyCtrl.text.trim();
      final model = _modelCtrl.text.trim();

      if (apiKey.isNotEmpty) {
        await dao.set(SettingsKeys.geminiApiKey, apiKey);
      } else {
        await dao.delete(SettingsKeys.geminiApiKey);
      }

      if (model.isNotEmpty) {
        await dao.set(SettingsKeys.geminiModel, model);
      } else {
        await dao.delete(SettingsKeys.geminiModel);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high),
                    const SizedBox(width: 12),
                    Text(
                      'IA / Gemini',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const Divider(height: 24),
                TextFormField(
                  controller: _apiKeyCtrl,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    labelText: 'Chave de API do Gemini',
                    hintText: 'AIza...',
                    helperText:
                        'Obtenha em https://aistudio.google.com/apikey',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscureKey ? 'Mostrar' : 'Ocultar',
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Modelo Gemini',
                    hintText: 'gemini-3.1-flash-lite',
                    helperText:
                        'Deixe em branco para usar "gemini-3.1-flash-lite" (padrão).',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
