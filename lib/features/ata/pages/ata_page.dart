import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../ata_providers.dart';

class AtaPage extends ConsumerStatefulWidget {
  const AtaPage({super.key});

  @override
  ConsumerState<AtaPage> createState() => _AtaPageState();
}

class _AtaPageState extends ConsumerState<AtaPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        title: const Text('Atas de Registro de Preço'),
        commandBar: FilledButton(
          onPressed: () => context.go('/ata/new'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(FluentIcons.add, size: 16),
              SizedBox(width: 6),
              Text('Nova Ata'),
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
            body: const _AtaList(status: 'draft'),
          ),
          Tab(
            text: const Text('Enviadas'),
            body: const _AtaList(status: 'sent'),
          ),
        ],
      ),
    );
  }
}

class _AtaList extends ConsumerWidget {
  final String status;
  const _AtaList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = status == 'draft'
        ? ref.watch(atasDraftProvider)
        : ref.watch(atasEnviadasProvider);

    return stream.when(
      loading: () => const Center(child: ProgressRing()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (atas) {
        if (atas.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'draft'
                      ? FluentIcons.task_list
                      : FluentIcons.task_add,
                  size: 64,
                  color: FluentTheme.of(context).inactiveColor,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'draft'
                      ? 'Nenhum rascunho de ata'
                      : 'Nenhuma ata enviada',
                  style: FluentTheme.of(context).typography.body,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: atas.length,
          itemBuilder: (context, i) => _AtaCard(ata: atas[i]),
        );
      },
    );
  }
}

class _AtaCard extends ConsumerWidget {
  final Ata ata;
  const _AtaCard({required this.ata});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final isSent = ata.status == 'sent';
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
          'Ata: ${ata.codigoAta}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edital: ${ata.codigoEdital}'),
            Text(
              'Município: ${ata.municipio}  |  Entidade: ${ata.entidade}',
            ),
            Text(
              'Atualizado: ${fmt.format(ata.updatedAt)}',
              style: theme.typography.caption,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ata.retificacao)
              const StatusBadge(status: AppStatus.retificacao),
            const SizedBox(width: 4),
            if (!isSent)
              IconButton(
                icon: const Icon(FluentIcons.delete, size: 16),
                onPressed: () => _confirmDelete(context, ref),
              ),
            IconButton(
              icon: const Icon(FluentIcons.caret_right, size: 16),
              onPressed: () => context.go('/ata/${ata.id}'),
            ),
          ],
        ),
        onPressed: () => context.go('/ata/${ata.id}'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Excluir Ata'),
        content: Text(
            'Deseja excluir a ata "${ata.codigoAta}"? Esta ação não pode ser desfeita.'),
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
      await ref.read(atasDaoProvider).deleteById(ata.id);
    }
  }
}
