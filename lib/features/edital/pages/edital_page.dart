import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../edital_providers.dart';

class EditalPage extends ConsumerStatefulWidget {
  const EditalPage({super.key});

  @override
  ConsumerState<EditalPage> createState() => _EditalPageState();
}

class _EditalPageState extends ConsumerState<EditalPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        title: const Text('Editais'),
        commandBar: FilledButton(
          onPressed: () => context.go('/edital/new'),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 6),
              Text('Novo Edital'),
            ],
          ),
        ),
      ),
      content: TabView(
        currentIndex: _tabIndex,
        onChanged: (i) => setState(() => _tabIndex = i),
        closeButtonVisibility: CloseButtonVisibilityMode.never,
        tabs: [
          Tab(
            text: const Text('Rascunhos'),
            body: const _EditalList(status: 'draft'),
          ),
          Tab(
            text: const Text('Enviados'),
            body: const _EditalList(status: 'sent'),
          ),
        ],
      ),
    );
  }
}

class _EditalList extends ConsumerWidget {
  final String status;
  const _EditalList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(editaisDraftProvider)
        : ref.watch(editaisEnviadosProvider);

    return stream.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (editais) {
        if (editais.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'draft'
                      ? Icons.description_outlined
                      : Icons.check_circle_outline,
                  size: 64,
                  color: FluentTheme.of(context).inactiveColor,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'draft'
                      ? 'Nenhum rascunho de edital'
                      : 'Nenhum edital enviado',
                  style: FluentTheme.of(context).typography.body,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: editais.length,
          itemBuilder: (context, i) =>
              _EditalCard(edital: editais[i]),
        );
      },
    );
  }
}

class _EditalCard extends ConsumerWidget {
  final Editai edital;
  const _EditalCard({required this.edital});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSent = edital.status == 'sent';
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSent
                    ? FluentTheme.of(context).accentColor.withValues(alpha: 0.15)
                    : FluentTheme.of(context).resources.controlFillColorDefault,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isSent ? Icons.check : Icons.edit_outlined,
                size: 20,
                color: isSent ? FluentTheme.of(context).accentColor : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => context.go('/edital/${edital.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edital.codigoEdital,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Município: ${edital.municipio}  |  Entidade: ${edital.entidade}',
                    ),
                    Text(
                      'Atualizado: ${fmt.format(edital.updatedAt)}',
                      style: FluentTheme.of(context).typography.caption,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (edital.retificacao)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DEF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Retificação',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                if (!isSent)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () => context.go('/edital/${edital.id}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Excluir Edital'),
        content: Text(
            'Deseja excluir o edital "${edital.codigoEdital}"? Esta ação não pode ser desfeita.'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFFB00020)),
              foregroundColor: WidgetStatePropertyAll(Colors.white),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(editaisDaoProvider).deleteById(edital.id);
    }
  }
}

