import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kEndpointLabels = <String, String>{
  '/login': 'Login',
  'enviar-edital': 'Edital',
  'enviar-licitacao': 'Licitação',
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

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  // ── Filtros ───────────────────────────────────────────────────────────
  String? _endpointFilter;       // null → todos
  _StatusFilter _statusFilter = _StatusFilter.todos;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _timeFmt = DateFormat('dd/MM/yy HH:mm:ss');

  // ─────────────────────────────────────────────────────────────────────

  List<ApiLog> _applyFilters(List<ApiLog> all) {
    return all.where((log) {
      // endpoint
      if (_endpointFilter != null &&
          !log.endpoint.contains(_endpointFilter!)) {
        return false;
      }
      // status
      final code = log.statusCode;
      if (_statusFilter == _StatusFilter.sucesso &&
          (code == null || code < 200 || code >= 300)) {
        return false;
      }
      if (_statusFilter == _StatusFilter.erro &&
          (code == null || code < 300)) {
        return false;
      }
      // date from
      if (_dateFrom != null && log.timestamp.isBefore(_dateFrom!)) {
        return false;
      }
      // date to — include the full day
      if (_dateTo != null) {
        final endOfDay =
            DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59);
        if (log.timestamp.isAfter(endOfDay)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _deleteLog(int id) async {
    await ref.read(apiLogsDaoProvider).deleteById(id);
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2099),
      );

  void _openDetail(ApiLog log) {
    showDialog(
      context: context,
      builder: (_) => _LogDetailDialog(log: log),
    );
  }

  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(apiLogsDaoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Chamadas API'),
      ),
      body: Column(
        children: [
          // ── Barra de filtros ──────────────────────────────────────────
          _FilterBar(
            endpointFilter: _endpointFilter,
            statusFilter: _statusFilter,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            dateFmt: _dateFmt,
            onEndpointChanged: (v) => setState(() => _endpointFilter = v),
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            onDateFromTap: () async {
              final d = await _pickDate(_dateFrom);
              if (d != null) setState(() => _dateFrom = d);
            },
            onDateToTap: () async {
              final d = await _pickDate(_dateTo);
              if (d != null) setState(() => _dateTo = d);
            },
            onClearFilters: () => setState(() {
              _endpointFilter = null;
              _statusFilter = _StatusFilter.todos;
              _dateFrom = null;
              _dateTo = null;
            }),
          ),

          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<ApiLog>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                final filtered = _applyFilters(all);

                if (all.isEmpty) {
                  return const Center(
                      child: Text('Nenhuma chamada registrada ainda.'));
                }
                if (filtered.isEmpty) {
                  return const Center(
                      child: Text('Nenhum resultado para os filtros selecionados.'));
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

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String? endpointFilter;
  final _StatusFilter statusFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final DateFormat dateFmt;
  final ValueChanged<String?> onEndpointChanged;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final VoidCallback onDateFromTap;
  final VoidCallback onDateToTap;
  final VoidCallback onClearFilters;

  const _FilterBar({
    required this.endpointFilter,
    required this.statusFilter,
    required this.dateFrom,
    required this.dateTo,
    required this.dateFmt,
    required this.onEndpointChanged,
    required this.onStatusChanged,
    required this.onDateFromTap,
    required this.onDateToTap,
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
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Módulo
          DropdownButton<String?>(
            value: endpointFilter,
            hint: const Text('Módulo'),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('Todos os módulos')),
              ...const {
                'enviar-edital': 'Edital',
                'enviar-licitacao': 'Licitação',
                'enviar-ata': 'Ata',
                'enviar-ajuste': 'Ajuste',
                'enviar-empenho-contrato': 'Empenho de Contrato',
                'enviar-termo-contrato': 'Termo de Contrato',
                '/login': 'Login',
              }.entries.map((e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value),
                  )),
            ],
            onChanged: onEndpointChanged,
          ),

          // Status
          DropdownButton<_StatusFilter>(
            value: statusFilter,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                  value: _StatusFilter.todos, child: Text('Todos os status')),
              DropdownMenuItem(
                  value: _StatusFilter.sucesso, child: Text('✓ Sucesso (2xx)')),
              DropdownMenuItem(
                  value: _StatusFilter.erro, child: Text('✗ Erro (3xx+)')),
            ],
            onChanged: (v) {
              if (v != null) onStatusChanged(v);
            },
          ),

          // Data de
          InkWell(
            onTap: onDateFromTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(dateFrom != null
                      ? 'De: ${dateFmt.format(dateFrom!)}'
                      : 'Data início'),
                ],
              ),
            ),
          ),

          // Data até
          InkWell(
            onTap: onDateToTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(dateTo != null
                      ? 'Até: ${dateFmt.format(dateTo!)}'
                      : 'Data fim'),
                ],
              ),
            ),
          ),

          // Limpar filtros
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Limpar filtros'),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log card
// ─────────────────────────────────────────────────────────────────────────────

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

  Color _statusColor(BuildContext context) {
    final code = log.statusCode;
    if (code == null) return Colors.grey;
    if (code >= 200 && code < 300) return Colors.green.shade700;
    if (code >= 400 && code < 500) return Colors.orange.shade800;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    final label = _labelFor(log.endpoint);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Status badge
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withAlpha(80)),
                ),
                alignment: Alignment.center,
                child: Text(
                  log.statusCode?.toString() ?? '—',
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
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.endpoint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(140),
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
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (log.userId != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.person_outline, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Usuário #${log.userId}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Ver detalhes',
                onPressed: onTap,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                tooltip: 'Excluir',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail dialog
// ─────────────────────────────────────────────────────────────────────────────

class _LogDetailDialog extends StatefulWidget {
  final ApiLog log;
  const _LogDetailDialog({required this.log});

  @override
  State<_LogDetailDialog> createState() => _LogDetailDialogState();
}

class _LogDetailDialogState extends State<_LogDetailDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

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

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 900,
        height: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 10),
                            _StatusChip(code: log.statusCode),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.endpoint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          timeFmt.format(log.timestamp.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tabs
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Request'),
                Tab(text: 'Response'),
              ],
            ),

            // Body
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _JsonPanel(content: prettyRequest, label: 'Request'),
                  _JsonPanel(content: prettyResponse, label: 'Response'),
                ],
              ),
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
    Color color;
    if (code == null) {
      color = Colors.grey;
    } else if (code! >= 200 && code! < 300) {
      color = Colors.green.shade700;
    } else if (code! >= 400 && code! < 500) {
      color = Colors.orange.shade800;
    } else {
      color = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        code?.toString() ?? '—',
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copiado')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar'),
              ),
            ],
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

