import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../ajuste_providers.dart';

class AjustePage extends ConsumerStatefulWidget {
  const AjustePage({super.key});

  @override
  ConsumerState<AjustePage> createState() => _AjustePageState();
}

class _AjustePageState extends ConsumerState<AjustePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        title: const Text('Ajustes (Contratos)'),
        commandBar: FilledButton(
          onPressed: () => context.go('/ajuste/new'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(FluentIcons.add, size: 16),
              SizedBox(width: 6),
              Text('Novo Ajuste'),
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
            body: const _AjusteList(status: 'draft'),
          ),
          Tab(
            text: const Text('Enviados'),
            body: const _AjusteList(status: 'sent'),
          ),
        ],
      ),
    );
  }
}

class _AjusteList extends ConsumerWidget {
  final String status;
  const _AjusteList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(ajustesDraftProvider)
        : ref.watch(ajustesEnviadosProvider);

    return stream.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (ajustes) {
        if (ajustes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'draft'
                      ? FluentIcons.task_list
                      : FluentIcons.accept,
                  size: 64,
                  color: FluentTheme.of(context).inactiveColor,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'draft'
                      ? 'Nenhum rascunho de ajuste'
                      : 'Nenhum ajuste enviado',
                  style: FluentTheme.of(context).typography.body,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: ajustes.length,
          itemBuilder: (context, i) => _AjusteCard(ajuste: ajustes[i]),
        );
      },
    );
  }
}

class _AjusteCard extends ConsumerWidget {
  final Ajuste ajuste;
  const _AjusteCard({required this.ajuste});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final isSent = ajuste.status == 'sent';
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
                : theme.resources.cardStrokeColorDefault,
          ),
          alignment: Alignment.center,
          child: Icon(
            isSent ? FluentIcons.accept : FluentIcons.edit,
            color: isSent ? theme.accentColor : theme.inactiveColor,
          ),
        ),
        title: Text(
          'Contrato: ${ajuste.codigoContrato}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edital: ${ajuste.codigoEdital}'),
            if (ajuste.codigoAta != null)
              Text('Ata: ${ajuste.codigoAta}'),
            Text(
              'Município: ${ajuste.municipio}  |  Entidade: ${ajuste.entidade}',
            ),
            Text(
              'Atualizado: ${fmt.format(ajuste.updatedAt)}',
              style: theme.typography.caption,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ajuste.retificacao)
              const StatusBadge(status: AppStatus.retificacao),
            const SizedBox(width: 4),
            if (!isSent)
              IconButton(
                icon: const Icon(FluentIcons.delete, size: 16),
                onPressed: () => _confirmDelete(context, ref),
              ),
            IconButton(
              icon: const Icon(FluentIcons.caret_right, size: 16),
              onPressed: () => context.go('/ajuste/${ajuste.id}'),
            ),
          ],
        ),
        onPressed: () => context.go('/ajuste/${ajuste.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Excluir Ajuste'),
        content: Text(
            'Deseja excluir o ajuste "${ajuste.codigoContrato}"? Esta ação não pode ser desfeita.'),
        constraints: const BoxConstraints(maxWidth: 400),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: ButtonStyle(
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
      await ref.read(ajustesDaoProvider).deleteById(ajuste.id);
    }
  }
}

