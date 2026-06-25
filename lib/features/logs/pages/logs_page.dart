import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../features/edital/domain/edital_domain.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../services/consulta_service.dart';
import '../services/pdf_comprovante_service.dart';

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

String _searchableLogText(ApiLog log) {
  return [
    log.endpoint,
    log.protocolo ?? '',
    log.statusProtocolo ?? '',
    log.userName ?? '',
    log.statusCode?.toString() ?? '',
    _docLabelFromRequest(log) ?? '',
  ].join(' ');
}

String? _docLabelFromRequest(ApiLog log, {Map<String, Edital>? editaisMap}) {
  try {
    final doc = jsonDecode(log.request) as Map<String, dynamic>;
    final endpoint = log.endpoint;

    if (endpoint.contains('enviar-edital')) {
      return _editalDocLabel(doc);
    }

    if (endpoint.contains('enviar-licitacao')) {
      return _licitacaoDocLabel(doc, editaisMap);
    }

    if (endpoint.contains('enviar-ata')) {
      final numero = doc['numeroAtaRegistroPreco']?.toString();
      final ano = doc['anoAta']?.toString();
      if (numero != null && numero.isNotEmpty) {
        return 'Ata de Registro $numero/$ano';
      }
    }

    if (endpoint.contains('enviar-ajuste') ||
        endpoint.contains('enviar-empenho-contrato') ||
        endpoint.contains('enviar-termo-contrato')) {
      final numero = doc['numeroContratoEmpenho']?.toString();
      final ano = doc['anoContrato']?.toString();
      if (numero != null && numero.isNotEmpty) {
        return 'Contrato $numero/$ano';
      }
    }
  } catch (_) {}
  return null;
}

String? _editalDocLabel(Map<String, dynamic> doc) {
  final modalidadeId = doc['modalidadeId'] as int?;
  final modalidade = modalidadeId != null
      ? (kModalidadesDropdown[modalidadeId] ?? '')
      : '';
  final numero = doc['numeroCompra']?.toString() ?? '';
  final ano = doc['anoCompra']?.toString() ?? '';
  if (numero.isEmpty) return null;
  return modalidade.isNotEmpty ? '$modalidade $numero/$ano' : '$numero/$ano';
}

String? _licitacaoDocLabel(
  Map<String, dynamic> doc,
  Map<String, Edital>? editaisMap,
) {
  if (editaisMap == null || editaisMap.isEmpty) return null;
  final descritor = doc['descritor'] as Map<String, dynamic>?;
  if (descritor == null) return null;
  final municipio = descritor['municipio']?.toString();
  final entidade = descritor['entidade']?.toString();
  final codigoEdital = descritor['codigoEdital']?.toString();
  if (municipio == null || entidade == null || codigoEdital == null) {
    return null;
  }
  final key = '$municipio|$entidade|$codigoEdital';
  final edital = editaisMap[key];
  if (edital == null) return null;
  return _editalDocLabel(
    jsonDecode(edital.documentoJson) as Map<String, dynamic>,
  );
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
  // ── Dados ───────────────────────────────────────────────────────────
  List<ApiLog> _allLogs = [];
  List<Edital> _allEditais = [];
  bool _loading = true;

  // ── Filtros ───────────────────────────────────────────────────────────
  String? _endpointFilter; // null → todos
  _StatusFilter _statusFilter = _StatusFilter.todos;
  final _textSearchCtrl = TextEditingController();

  final _timeFmt = DateFormat('dd/MM/yy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _textSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final logs = await ref.read(apiLogsDaoProvider).watchAll();
    final editais = await ref.read(editaisDaoProvider).watchAll();
    if (mounted) {
      setState(() {
        _allLogs = logs;
        _allEditais = editais;
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────

  List<ApiLog> _applyFilters(List<ApiLog> all) {
    return all.where((log) {
      if (_endpointFilter != null && !log.endpoint.contains(_endpointFilter!)) {
        return false;
      }
      final code = log.statusCode;
      if (_statusFilter == _StatusFilter.sucesso &&
          (code == null || code < 200 || code >= 300)) {
        return false;
      }
      if (_statusFilter == _StatusFilter.erro && (code == null || code < 300)) {
        return false;
      }
      if (_textSearchCtrl.text.isNotEmpty &&
          !matchesLikeSearch(_searchableLogText(log), _textSearchCtrl.text)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openDetail(ApiLog log) {
    showDialog(
      context: context,
      builder: (_) => _LogDetailDialog(log: log),
    );
  }

  Future<void> _updateStatus(ApiLog log) async {
    if (log.protocolo == null) return;

    await showAudespAuthDialog(
      context,
      ref,
      actionLabel: 'Autenticar e Atualizar',
      onConfirm: (token) async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final consultaSvc = ref.read(consultaServiceProvider);
          final jsonRetorno = await consultaSvc.consultarStatus(log.protocolo!);
          final json = jsonDecode(jsonRetorno);
          final novoStatus = json['status']?.toString() ?? 'Desconhecido';

          final dao = ref.read(apiLogsDaoProvider);
          await dao.updateProtocoloInfo(log.id, novoStatus, jsonRetorno);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // fecha o loader
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Status atualizado para: $novoStatus')),
            );
            _loadData();
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // fecha o loader
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao atualizar: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _updateAllUpdatable() async {
    final allLogs = await ref.read(apiLogsDaoProvider).watchAll();
    final updatables = allLogs
        .where((l) => isProtocoloUpdatable(l.statusProtocolo))
        .toList();

    if (updatables.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum registro requer atualização no momento.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    await showAudespAuthDialog(
      context,
      ref,
      actionLabel: 'Autenticar e Atualizar Todos',
      onConfirm: (token) async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 24),
                Text('Atualizando ${updatables.length} registros...'),
              ],
            ),
          ),
        );

        try {
          final consultaSvc = ref.read(consultaServiceProvider);
          final dao = ref.read(apiLogsDaoProvider);
          int successCount = 0;

          for (final log in updatables) {
            try {
              final jsonRetorno = await consultaSvc.consultarStatus(
                log.protocolo!,
              );
              final json = jsonDecode(jsonRetorno);
              final novoStatus = json['status']?.toString() ?? 'Desconhecido';
              await dao.updateProtocoloInfo(log.id, novoStatus, jsonRetorno);
              successCount++;
            } catch (_) {}
          }

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // fecha o loader
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$successCount de ${updatables.length} registros atualizados com sucesso.',
                ),
              ),
            );
            _loadData();
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // fecha o loader
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro durante a atualização: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  void _showErrors(ApiLog log) {
    if (log.retornoStatus == null) return;
    try {
      final json = jsonDecode(log.retornoStatus!);
      final erros = json['erros'] as List<dynamic>? ?? [];
      if (erros.isEmpty) return;

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Erros Retornados'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: erros.length,
              itemBuilder: (itemCtx, i) {
                final erro = erros[i];
                return ListTile(
                  title: Text(erro['mensagem']?.toString() ?? 'Erro'),
                  subtitle: Text(
                    'Campo: ${erro['campo']} | Código: ${erro['codigoErro']}',
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(localSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Chamadas API'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilledButton.icon(
              onPressed: _updateAllUpdatable,
              icon: const Icon(Icons.sync),
              label: const Text('Atualizar Status'),
            ),
          ),
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
                    width: 120,
                    child: AudespDropdown<String?>.items(
                      label: 'Módulo',
                      value: _endpointFilter,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos', overflow: TextOverflow.ellipsis),
                        ),
                        ...[
                          if (user == null ||
                              user.isAdmin ||
                              user.hasPermission(AppPermissions.edital))
                            const MapEntry('edital', 'Edital'),
                          if (user == null ||
                              user.isAdmin ||
                              user.hasPermission(AppPermissions.licitacao))
                            const MapEntry('licitacao', 'Licitação'),
                          if (user == null ||
                              user.isAdmin ||
                              user.hasPermission(AppPermissions.ata))
                            const MapEntry('ata', 'Ata'),
                          if (user == null ||
                              user.isAdmin ||
                              user.hasPermission(AppPermissions.ajuste))
                            const MapEntry('ajuste', 'Ajuste'),
                        ].map(
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
                    width: 120,
                    child: AudespDropdown<_StatusFilter>(
                      label: 'Status',
                      value: _statusFilter,
                      items: const {
                        _StatusFilter.todos: 'Todos',
                        _StatusFilter.sucesso: 'Sucesso',
                        _StatusFilter.erro: 'Erro',
                      },
                      onChanged: (v) {
                        if (v != null) setState(() => _statusFilter = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 200,
                    child: AudespTextField(
                      label: 'Filtrar',
                      controller: _textSearchCtrl,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _textSearchCtrl.text.isEmpty
                          ? null
                          : AudespIconButton(
                              tooltip: 'Limpar filtro',
                              icon: Icons.close,
                              onPressed: () {
                                _textSearchCtrl.clear();
                                setState(() {});
                              },
                            ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AudespIconButton(
            icon: Icons.refresh,
            tooltip: 'Atualizar',
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Lista ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(user),
          ),
        ],
      ),
    );
  }

  Widget _buildList(dynamic user) {
    final editaisMap = <String, Edital>{
      for (final e in _allEditais)
        '${e.municipio}|${e.entidade}|${e.codigoEdital}': e,
    };
    final filtered = _applyFilters(_allLogs).where((log) {
      if (user == null || user.isAdmin) return true;
      final ep = log.endpoint.toLowerCase();
      if (ep.contains('edital') && !user.hasPermission(AppPermissions.edital)) {
        return false;
      }
      if (ep.contains('licitacao') &&
          !user.hasPermission(AppPermissions.licitacao)) {
        return false;
      }
      if (ep.contains('ata') && !user.hasPermission(AppPermissions.ata)) {
        return false;
      }
      if ((ep.contains('ajuste') || ep.contains('contrato')) &&
          !user.hasPermission(AppPermissions.ajuste)) {
        return false;
      }
      return true;
    }).toList();

    if (_allLogs.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        message: 'Nenhuma chamada registrada ainda.',
      );
    }
    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_list_off_outlined,
        message: 'Nenhum resultado para os filtros selecionados.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _LogCard(
        log: filtered[i],
        timeFmt: _timeFmt,
        editaisMap: editaisMap,
        onTap: () => _openDetail(filtered[i]),
        onUpdateStatus: () => _updateStatus(filtered[i]),
        onShowErrors: () => _showErrors(filtered[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log card
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Helpers globais
// ─────────────────────────────────────────────────────────────────────────────

bool isProtocoloUpdatable(String? status) {
  if (status == null) return false;
  final s = status.toLowerCase();
  if (s.contains('rejeitado') ||
      s.contains('arquivado') ||
      s.contains('excluido') ||
      s.contains('excluído') ||
      s.contains('armazenado') ||
      s.contains('substituido') ||
      s.contains('substituído')) {
    return false;
  }
  return true;
}

class _DocLabel extends StatelessWidget {
  final ApiLog log;
  final Map<String, Edital> editaisMap;
  final String baseLabel;

  const _DocLabel({
    required this.log,
    required this.editaisMap,
    required this.baseLabel,
  });

  @override
  Widget build(BuildContext context) {
    final docLabel = _docLabelFromRequest(log, editaisMap: editaisMap);
    return Text(
      docLabel != null ? '$baseLabel · $docLabel' : baseLabel,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _LogCard extends ConsumerWidget {
  final ApiLog log;
  final DateFormat timeFmt;
  final Map<String, Edital> editaisMap;
  final VoidCallback onTap;
  final VoidCallback onUpdateStatus;
  final VoidCallback onShowErrors;

  const _LogCard({
    required this.log,
    required this.timeFmt,
    required this.editaisMap,
    required this.onTap,
    required this.onUpdateStatus,
    required this.onShowErrors,
  });

  bool _hasErrors() {
    if (log.retornoStatus == null) return false;
    try {
      final json = jsonDecode(log.retornoStatus!);
      final erros = json['erros'] as List<dynamic>?;
      return erros != null && erros.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Color _statusColor(BuildContext context) {
    final code = log.statusCode;
    if (code == null) return Colors.grey;
    if (code >= 200 && code < 300) return Colors.green.shade700;
    if (code >= 400 && code < 500) return Colors.orange.shade800;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: _DocLabel(log: log, editaisMap: editaisMap, baseLabel: label),
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
                    log.userName ?? 'Usuário #${log.userId}',
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
            if (log.protocolo != null) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Protocolo: ${log.protocolo}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: _hasErrors() ? onShowErrors : null,
                    child: Text(
                      log.statusProtocolo ?? '—',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _hasErrors()
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                        decoration: _hasErrors()
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (isProtocoloUpdatable(log.statusProtocolo))
                AudespIconButton(
                  icon: Icons.refresh,
                  tooltip: 'Atualizar Status',
                  onPressed: onUpdateStatus,
                )
              else
                AudespIconButton(
                  icon: Icons.picture_as_pdf_outlined,
                  tooltip: 'Gerar Comprovante (PDF)',
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () =>
                      PdfComprovanteService.gerarComprovante(context, ref, log),
                ),
            ],
            AudespIconButton(
              icon: Icons.arrow_forward_ios,
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
    _tabs = TabController(length: 3, vsync: this);
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
                            StatusChip.httpCode(log.statusCode),
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
                Tab(text: 'Consulta F4'),
              ],
            ),

            // Body
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _JsonPanel(content: prettyRequest, label: 'Request'),
                  _JsonPanel(content: prettyResponse, label: 'Response'),
                  _JsonPanel(
                    content: _prettyJson(log.retornoStatus),
                    label: 'Consulta F4',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonPanel extends StatefulWidget {
  final String content;
  final String label;
  const _JsonPanel({required this.content, required this.label});

  @override
  State<_JsonPanel> createState() => _JsonPanelState();
}

class _JsonPanelState extends State<_JsonPanel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
                  Clipboard.setData(ClipboardData(text: widget.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.label} copiado')),
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
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    widget.content,
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
