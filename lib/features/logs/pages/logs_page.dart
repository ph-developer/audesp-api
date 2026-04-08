import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Helpers
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const _kEndpointLabels = <String, String>{
  '/login': 'Login',
  'enviar-edital': 'Edital',
  'enviar-licitacao': 'LicitaÃ§Ã£o',
  'enviar-ata': 'Ata',
  'enviar-ajuste': 'Ajuste',
  'enviar-empenho-contrato': 'Empenho de Contrato',
  'enviar-termo-contrato': 'Termo de Contrato',
};

String _labelFor(String endpoint) {
  for (final entry in _kEndpointLabels.entries) {
    if (endpoint.contains(entry.key)) return entry.value;
  }
  return endpoint;
}

enum _StatusFilter { todos, sucesso, erro }

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Page
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  // â”€â”€ Filtros â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String? _endpointFilter;
  _StatusFilter _statusFilter = _StatusFilter.todos;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  final _timeFmt = DateFormat('dd/MM/yy HH:mm:ss');

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<ApiLog> _applyFilters(List<ApiLog> all) {
    return all.where((log) {
      if (_endpointFilter != null &&
          !log.endpoint.contains(_endpointFilter!)) {
        return false;
      }
      final code = log.statusCode;
      if (_statusFilter == _StatusFilter.sucesso &&
          (code == null || code < 200 || code >= 300)) {
        return false;
      }
      if (_statusFilter == _StatusFilter.erro &&
          (code == null || code < 300)) {
        return false;
      }
      if (_dateFrom != null && log.timestamp.isBefore(_dateFrom!)) {
        return false;
      }
      if (_dateTo != null) {
        final endOfDay =
            DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59);
        if (log.timestamp.isAfter(endOfDay)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Limpar todos os logs?'),
        content: const Text(
            'Esta aÃ§Ã£o removerÃ¡ permanentemente todo o histÃ³rico de chamadas Ã  API.'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(const Color(0xFFD32F2F)),
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(apiLogsDaoProvider).clearAll();
    }
  }

  Future<void> _deleteLog(int id) async {
    await ref.read(apiLogsDaoProvider).deleteById(id);
  }

  void _openDetail(ApiLog log) {
    showDialog(
      context: context,
      builder: (_) => _LogDetailDialog(log: log),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(apiLogsDaoProvider).watchAll();

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        title: const Text('HistÃ³rico de Chamadas API'),
        commandBar: IconButton(
          icon: const Icon(FluentIcons.delete),
          onPressed: _clearAll,
        ),
      ),
      content: Column(
        children: [
          // â”€â”€ Barra de filtros â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _FilterBar(
            endpointFilter: _endpointFilter,
            statusFilter: _statusFilter,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            onEndpointChanged: (v) => setState(() => _endpointFilter = v),
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            onDateFromChanged: (d) => setState(() => _dateFrom = d),
            onDateToChanged: (d) => setState(() => _dateTo = d),
            onClearFilters: () => setState(() {
              _endpointFilter = null;
              _statusFilter = _StatusFilter.todos;
              _dateFrom = null;
              _dateTo = null;
            }),
          ),

          // â”€â”€ Lista â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: StreamBuilder<List<ApiLog>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: ProgressRing());
                }
                final all = snap.data ?? [];
                final filtered = _applyFilters(all);

                if (all.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma chamada registrada ainda.'));
                }
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text(
                          'Nenhum resultado para os filtros selecionados.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _LogCard(
                    log: filtered[i],
                    timeFmt: _timeFmt,
                    onTap: () => _openDetail(filtered[i]),
                    onDelete: () => _deleteLog(filtered[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Filter bar
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FilterBar extends StatelessWidget {
  final String? endpointFilter;
  final _StatusFilter statusFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ValueChanged<String?> onEndpointChanged;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final ValueChanged<DateTime?> onDateFromChanged;
  final ValueChanged<DateTime?> onDateToChanged;
  final VoidCallback onClearFilters;

  const _FilterBar({
    required this.endpointFilter,
    required this.statusFilter,
    required this.dateFrom,
    required this.dateTo,
    required this.onEndpointChanged,
    required this.onStatusChanged,
    required this.onDateFromChanged,
    required this.onDateToChanged,
    required this.onClearFilters,
  });

  bool get _hasActiveFilters =>
      endpointFilter != null ||
      statusFilter != _StatusFilter.todos ||
      dateFrom != null ||
      dateTo != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FluentTheme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // MÃ³dulo
          ComboBox<String?>(
            value: endpointFilter,
            placeholder: const Text('Todos os mÃ³dulos'),
            items: [
              const ComboBoxItem<String?>(
                  value: null, child: Text('Todos os mÃ³dulos')),
              ...const {
                'enviar-edital': 'Edital',
                'enviar-licitacao': 'LicitaÃ§Ã£o',
                'enviar-ata': 'Ata',
                'enviar-ajuste': 'Ajuste',
                'enviar-empenho-contrato': 'Empenho de Contrato',
                'enviar-termo-contrato': 'Termo de Contrato',
                '/login': 'Login',
              }.entries.map((e) => ComboBoxItem<String?>(
                    value: e.key,
                    child: Text(e.value),
                  )),
            ],
            onChanged: onEndpointChanged,
          ),

          // Status
          ComboBox<_StatusFilter>(
            value: statusFilter,
            items: const [
              ComboBoxItem(
                  value: _StatusFilter.todos, child: Text('Todos os status')),
              ComboBoxItem(
                  value: _StatusFilter.sucesso,
                  child: Text('âœ“ Sucesso (2xx)')),
              ComboBoxItem(
                  value: _StatusFilter.erro, child: Text('âœ— Erro (3xx+)')),
            ],
            onChanged: (v) {
              if (v != null) onStatusChanged(v);
            },
          ),

          // Data de
          InfoLabel(
            label: 'De:',
            child: DatePicker(
              selected: dateFrom,
              onChanged: (d) => onDateFromChanged(d),
            ),
          ),

          // Data atÃ©
          InfoLabel(
            label: 'AtÃ©:',
            child: DatePicker(
              selected: dateTo,
              onChanged: (d) => onDateToChanged(d),
            ),
          ),

          // Limpar filtros
          if (_hasActiveFilters)
            Button(
              onPressed: onClearFilters,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(FluentIcons.clear, size: 14),
                  SizedBox(width: 6),
                  Text('Limpar filtros'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Log card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LogCard extends StatelessWidget {
  final ApiLog log;
  final DateFormat timeFmt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LogCard({
    required this.log,
    required this.timeFmt,
    required this.onTap,
    required this.onDelete,
  });

  Color _statusColor() {
    final code = log.statusCode;
    if (code == null) return const Color(0xFF9E9E9E);
    if (code >= 200 && code < 300) return const Color(0xFF388E3C);
    if (code >= 400 && code < 500) return const Color(0xFFEF6C00);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final label = _labelFor(log.endpoint);
    final theme = FluentTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Status badge
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.31)),
                ),
                alignment: Alignment.center,
                child: Text(
                  log.statusCode?.toString() ?? 'â€”',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.typography.bodyStrong),
                    const SizedBox(height: 2),
                    Text(
                      log.endpoint,
                      style: theme.typography.caption?.copyWith(
                        color: theme.inactiveColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          timeFmt.format(log.timestamp.toLocal()),
                          style: theme.typography.caption,
                        ),
                        if (log.userId != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.person_outline, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'UsuÃ¡rio #${log.userId}',
                            style: theme.typography.caption,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(FluentIcons.info, size: 16),
                onPressed: onTap,
              ),
              IconButton(
                icon: Icon(FluentIcons.delete,
                    size: 16, color: const Color(0xFFD32F2F)),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Detail dialog
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LogDetailDialog extends StatefulWidget {
  final ApiLog log;
  const _LogDetailDialog({required this.log});

  @override
  State<_LogDetailDialog> createState() => _LogDetailDialogState();
}

class _LogDetailDialogState extends State<_LogDetailDialog> {
  int _tabIndex = 0;

  String _prettyJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '(vazio)';
    try {
      final obj = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('dd/MM/yyyy HH:mm:ss');
    final log = widget.log;
    final label = _labelFor(log.endpoint);
    final prettyRequest = _prettyJson(log.request);
    final prettyResponse = _prettyJson(log.response);
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 900),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: theme.typography.subtitle),
                    const SizedBox(width: 10),
                    _StatusChip(code: log.statusCode),
                  ],
                ),
                const SizedBox(height: 2),
                Text(log.endpoint, style: theme.typography.caption),
                Text(
                  timeFmt.format(log.timestamp.toLocal()),
                  style: theme.typography.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.cancel, size: 14),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        height: 520,
        child: TabView(
          currentIndex: _tabIndex,
          onChanged: (i) => setState(() => _tabIndex = i),
          closeButtonVisibility: CloseButtonVisibilityMode.never,
          tabs: [
            Tab(
              text: const Text('Request'),
              body: _JsonPanel(content: prettyRequest, label: 'Request'),
            ),
            Tab(
              text: const Text('Response'),
              body: _JsonPanel(content: prettyResponse, label: 'Response'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final int? code;
  const _StatusChip({this.code});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (code == null) {
      color = const Color(0xFF9E9E9E);
    } else if (code! >= 200 && code! < 300) {
      color = const Color(0xFF388E3C);
    } else if (code! >= 400 && code! < 500) {
      color = const Color(0xFFEF6C00);
    } else {
      color = const Color(0xFFD32F2F);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.31)),
      ),
      child: Text(
        code?.toString() ?? 'â€”',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _JsonPanel extends StatelessWidget {
  final String content;
  final String label;
  const _JsonPanel({required this.content, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  displayInfoBar(
                    context,
                    builder: (ctx, close) => InfoBar(
                      title: Text('$label copiado'),
                      severity: InfoBarSeverity.success,
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.copy, size: 16),
                    SizedBox(width: 6),
                    Text('Copiar'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    content,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
