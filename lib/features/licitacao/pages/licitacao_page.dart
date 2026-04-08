import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../licitacao_providers.dart';

class LicitacaoPage extends ConsumerStatefulWidget {
  const LicitacaoPage({super.key});

  @override
  ConsumerState<LicitacaoPage> createState() => _LicitacaoPageState();
}

class _LicitacaoPageState extends ConsumerState<LicitacaoPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        title: const Text('Licitações'),
        commandBar: FilledButton(
          onPressed: () => context.go('/licitacao/new'),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 6),
              Text('Nova Licitação'),
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
            body: const _LicitacaoList(status: 'draft'),
          ),
          Tab(
            text: const Text('Enviadas'),
            body: const _LicitacaoList(status: 'sent'),
          ),
        ],
      ),
    );
  }
}

class _LicitacaoList extends ConsumerWidget {
  final String status;
  const _LicitacaoList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(licitacoesDraftProvider)
        : ref.watch(licitacoesEnviadasProvider);

    return stream.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (licitacoes) {
        if (licitacoes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'draft'
                      ? Icons.gavel_outlined
                      : Icons.check_circle_outline,
                  size: 64,
                  color: FluentTheme.of(context).inactiveColor,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'draft'
                      ? 'Nenhum rascunho de licitação'
                      : 'Nenhuma licitação enviada',
                  style: FluentTheme.of(context).typography.body,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: licitacoes.length,
          itemBuilder: (context, i) =>
              _LicitacaoCard(licitacao: licitacoes[i]),
        );
      },
    );
  }
}

class _LicitacaoCard extends ConsumerWidget {
  final Licitacoe licitacao;
  const _LicitacaoCard({required this.licitacao});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final isSent = licitacao.status == 'sent';
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSent
                ? theme.accentColor.lighter
                : theme.resources.controlFillColorDefault,
          ),
          alignment: Alignment.center,
          child: Icon(
            isSent ? Icons.check : Icons.edit_outlined,
            size: 20,
          ),
        ),
        title: Text(
          licitacao.codigoEdital,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Município: ${licitacao.municipio}  |  Entidade: ${licitacao.entidade}',
            ),
            Text(
              'Atualizado: ${fmt.format(licitacao.updatedAt)}',
              style: theme.typography.caption,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (licitacao.retificacao)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.accentColor.lightest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Retificação',
                    style: TextStyle(fontSize: 11)),
              ),
            const SizedBox(width: 4),
            if (!isSent)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref),
              ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () => context.go('/licitacao/${licitacao.id}'),
            ),
          ],
        ),
        onPressed: () => context.go('/licitacao/${licitacao.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Excluir Licitação'),
        content: Text(
            'Deseja excluir a licitação do edital "${licitacao.codigoEdital}"? Esta ação não pode ser desfeita.'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: const ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(Color(0xFFB00020)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(licitacoesDaoProvider).deleteById(licitacao.id);
    }
  }
}
