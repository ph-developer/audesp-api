import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';

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
  String? _endpointFilter; // null → todos
  _StatusFilter _statusFilter = _StatusFilter.todos;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _timeFmt = DateFormat('dd/MM/yy HH:mm:ss');

  // ─────────────────────────────────────────────────────────────────────

  List<ApiLog> _applyFilters(List<ApiLog> all) {
    return all.where((log) {
      // endpoint
      if (_endpointFilter != null && !log.endpoint.contains(_endpointFilter!)) {
        return false;
      }
      // status
      final code = log.statusCode;
      if (_statusFilter == _StatusFilter.sucesso &&
          (code == null || code < 200 || code >= 300)) {
        return false;
      }
      if (_statusFilter == _StatusFilter.erro && (code == null || code < 300)) {
        return false;
      }
      // date from
      if (_dateFrom != null && log.timestamp.isBefore(_dateFrom!)) {
        return false;
      }
      // date to — include the full day
      if (_dateTo != null) {
        final endOfDay = DateTime(
          _dateTo!.year,
          _dateTo!.month,
          _dateTo!.day,
          23,
          59,
          59,
        );
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
    final future = ref.watch(apiLogsDaoProvider).watchAll();

    final hasActiveFilters =
        _endpointFilter != null ||
        _statusFilter != _StatusFilter.todos ||
        _dateFrom != null ||
        _dateTo != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Chamadas API'),
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String?>(
                      value: _endpointFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Módulo'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Todos os módulos',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...const {
                          'enviar-edital': 'Edital',
                          'enviar-licitacao': 'Licitação',
                          'enviar-ata': 'Ata',
                          'enviar-ajuste': 'Ajuste',
                          'enviar-empenho-contrato': 'Empenho de Contrato',
                          'enviar-termo-contrato': 'Termo de Contrato',
                          '/login': 'Login',
                        }.entries.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e.key,
                            child: Text(
                              e.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _endpointFilter = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<_StatusFilter>(
                      value: _statusFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: _StatusFilter.todos,
                          child: Text(
                            'Todos os status',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: _StatusFilter.sucesso,
                          child: Text(
                            'Sucesso',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: _StatusFilter.erro,
                          child: Text('Erro', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _statusFilter = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: AudespDatePickerField(
                      isDense: true,
                      label: 'Data início',
                      value: _dateFrom,
                      onChanged: (d) => setState(() => _dateFrom = d),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    child: AudespDatePickerField(
                      isDense: true,
                      label: 'Data fim',
                      value: _dateTo,
                      onChanged: (d) => setState(() => _dateTo = d),
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() {
                        _endpointFilter = null;
                        _statusFilter = _StatusFilter.todos;
                        _dateFrom = null;
                        _dateTo = null;
                      }),
                      icon: const Icon(Icons.clear, size: 16),
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<ApiLog>>(
              future: future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                final filtered = _applyFilters(all);

                if (all.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma chamada registrada ainda.'),
                  );
                }
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum resultado para os filtros selecionados.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            shape: BoxShape.circle,
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
        title: Text(label, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              log.endpoint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Excluir',
              onPressed: onDelete,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: 'Abrir',
              onPressed: onTap,
            ),
          ],
        ),
        onTap: onTap,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$label copiado')));
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
