import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../features/logs/services/consulta_service.dart';
import '../edital_providers.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_ai_import_dialog.dart';
import '../../../shared/widgets/audesp_date_time_picker_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_field_row.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_pncp_field.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_spacing.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../csv/mappers/edital_complemento_csv_mapper.dart';
import '../domain/edital_domain.dart';
import '../services/edital_service.dart';
import '../widgets/edital_import_csv_dialog.dart';
import '../widgets/gemini_import_dialog.dart';
import '../widgets/item_compra_dialog.dart';
import '../../../shared/formatters/pcnp_input_formatter.dart';
import '../widgets/publicacao_dialog.dart';

/// Formulário de criação/edição de Edital (Fase 4 – Módulo 1).
///
/// [editalId] null → criar novo; não-null → editar existente.
class EditalFormPage extends ConsumerStatefulWidget {
  final int? editalId;
  const EditalFormPage({super.key, this.editalId});

  @override
  ConsumerState<EditalFormPage> createState() => _EditalFormPageState();
}

class _EditalFormPageState extends ConsumerState<EditalFormPage> {
  final _formKey = GlobalKey<FormState>();

  // ── Carregamento ──────────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  bool _isSent = false;
  bool _importingGemini = false;
  bool _updatingStatus = false;
  int? _loadedId;
  ApiLog? _lastSendLog;

  // ── Descritor ────────────────────────────────────────────────────────────
  final _codigoEditalCtrl = TextEditingController();
  DateTime? _dataDoc;
  bool _retificacao = false;

  // ── Publicidade ──────────────────────────────────────────────────────────
  bool _houvePublicacao = true;
  List<Map<String, dynamic>> _publicacoes = [];

  // ── Dados Gerais ─────────────────────────────────────────────────────────
  final _codigoUnidadeCtrl = TextEditingController();
  int? _tipoInstrumento;
  int? _modalidade;
  int? _modoDisputa;
  int? _criterioJulgamentoId;
  final _numeroCompraCtrl = TextEditingController();
  final _anoCompraCtrl = TextEditingController();
  final _numeroProcessoCtrl = TextEditingController();
  final _objetoCompraCtrl = TextEditingController();
  final _infComplementarCtrl = TextEditingController();
  bool _srp = false;
  DateTime? _dataAbertura;
  DateTime? _dataEncerramento;
  final _amparoLegalCtrl = TextEditingController();
  final _linkSistemaCtrl = TextEditingController();
  final _justificativaCtrl = TextEditingController();

  // ── Itens de Compra ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _itens = [];

  // ── PDF ──────────────────────────────────────────────────────────────────
  String? _pdfPath;

  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadIfEditing();
  }

  @override
  void dispose() {
    _codigoEditalCtrl.dispose();
    _codigoUnidadeCtrl.dispose();
    _numeroCompraCtrl.dispose();
    _anoCompraCtrl.dispose();
    _numeroProcessoCtrl.dispose();
    _objetoCompraCtrl.dispose();
    _infComplementarCtrl.dispose();
    _amparoLegalCtrl.dispose();
    _linkSistemaCtrl.dispose();
    _justificativaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIfEditing() async {
    if (widget.editalId == null) {
      setState(() => _loading = false);
      return;
    }
    final dao = ref.read(editaisDaoProvider);
    final edital = await dao.findById(widget.editalId!);
    if (edital == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _loadedId = edital.id;
    _isSent = edital.status == 'sent';
    _pdfPath = edital.pdfPath;

    // Parse JSON
    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(edital.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    final publicidade = doc['publicidade'] as Map<String, dynamic>? ?? {};

    _codigoEditalCtrl.text = PcnpInputFormatter.applyMask(
      descritor['codigoEdital'] as String? ?? edital.codigoEdital,
    );
    _dataDoc = DateTime.tryParse(descritor['dataDocumento'] as String? ?? '');
    _retificacao = descritor['retificacao'] as bool? ?? edital.retificacao;

    _houvePublicacao = publicidade['houvePublicacao'] as bool? ?? false;
    _publicacoes = (publicidade['publicacoes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    _codigoUnidadeCtrl.text = doc['codigoUnidadeCompradora'] as String? ?? '';
    _tipoInstrumento = doc['tipoInstrumentoConvocatorioId'] as int?;
    _modalidade = doc['modalidadeId'] as int?;
    _modoDisputa = doc['modoDisputaId'] as int?;
    final itensCompra = doc['itensCompra'] as List<dynamic>?;
    _criterioJulgamentoId =
        doc['criterioJulgamentoId'] as int? ??
        (itensCompra?.isNotEmpty == true
            ? itensCompra!.first['criterioJulgamentoId'] as int?
            : null);
    _numeroCompraCtrl.text = doc['numeroCompra'] as String? ?? '';
    _anoCompraCtrl.text = doc['anoCompra']?.toString() ?? '';
    _numeroProcessoCtrl.text = doc['numeroProcesso'] as String? ?? '';
    _objetoCompraCtrl.text = doc['objetoCompra'] as String? ?? '';
    _infComplementarCtrl.text = doc['informacaoComplementar'] as String? ?? '';
    _srp = doc['srp'] as bool? ?? false;
    _dataAbertura = DateTime.tryParse(
      doc['dataAberturaProposta'] as String? ?? '',
    );
    _dataEncerramento = DateTime.tryParse(
      doc['dataEncerramentoProposta'] as String? ?? '',
    );
    _amparoLegalCtrl.text = doc['amparoLegalId']?.toString() ?? '';
    _linkSistemaCtrl.text = doc['linkSistemaOrigem'] as String? ?? '';
    _justificativaCtrl.text = doc['justificativaPresencial'] as String? ?? '';
    _itens = (doc['itensCompra'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    if (_isSent) {
      _lastSendLog = await ref
          .read(apiLogsDaoProvider)
          .findLatestEditalSendLog(
            municipio: edital.municipio,
            entidade: edital.entidade,
            codigoEdital: edital.codigoEdital,
            retificacao: edital.retificacao,
          );
    }

    if (mounted) setState(() => _loading = false);
  }

  // ── Build JSON ────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final municipio = int.tryParse(ref.read(codigoMunicipioProvider)) ?? 0;
    final entidade = int.tryParse(ref.read(codigoEntidadeProvider)) ?? 0;
    final map = <String, dynamic>{
      'descritor': {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': AudespPncpField.stripMask(_codigoEditalCtrl.text),
        'dataDocumento': _dataDoc != null
            ? DateFormat('yyyy-MM-dd').format(_dataDoc!)
            : '',
        'retificacao': _retificacao,
      },
      'publicidade': {
        'houvePublicacao': _houvePublicacao,
        if (_houvePublicacao && _publicacoes.isNotEmpty)
          'publicacoes': _publicacoes,
      },
      'tipoInstrumentoConvocatorioId': _tipoInstrumento,
      'modalidadeId': _modalidade,
      'modoDisputaId': _modoDisputa,
      'criterioJulgamentoId': _criterioJulgamentoId,
      'numeroCompra': _numeroCompraCtrl.text.trim(),
      'anoCompra': int.tryParse(_anoCompraCtrl.text.trim()) ?? 0,
      'numeroProcesso': _numeroProcessoCtrl.text.trim(),
      'objetoCompra': _objetoCompraCtrl.text.trim(),
      'srp': _srp,
      'amparoLegalId': int.tryParse(_amparoLegalCtrl.text.trim()),
      'itensCompra': _itens.toList(),
    };

    if (_codigoUnidadeCtrl.text.trim().isNotEmpty) {
      map['codigoUnidadeCompradora'] = _codigoUnidadeCtrl.text.trim();
    }
    if (_infComplementarCtrl.text.trim().isNotEmpty) {
      map['informacaoComplementar'] = _infComplementarCtrl.text.trim();
    }
    if (_dataAbertura != null) {
      map['dataAberturaProposta'] = DateFormat(
        "yyyy-MM-dd'T'HH:mm:ss",
      ).format(_dataAbertura!);
    }
    if (_dataEncerramento != null) {
      map['dataEncerramentoProposta'] = DateFormat(
        "yyyy-MM-dd'T'HH:mm:ss",
      ).format(_dataEncerramento!);
    }
    if (_linkSistemaCtrl.text.trim().isNotEmpty) {
      map['linkSistemaOrigem'] = _linkSistemaCtrl.text.trim();
    }
    if (_justificativaCtrl.text.trim().isNotEmpty) {
      map['justificativaPresencial'] = _justificativaCtrl.text.trim();
    }

    return map;
  }

  // ── Salvar rascunho ───────────────────────────────────────────────────────

  bool _validateDraft() {
    if (_codigoEditalCtrl.text.trim().isEmpty) {
      _showError('Informe o ID de Contratação PNCP para salvar o rascunho.');
      return false;
    }
    if (_dataDoc == null) {
      _showError('Informe a Data do Documento para salvar o rascunho.');
      return false;
    }
    return true;
  }

  Future<void> _saveDraft() async {
    if (!_validateDraft()) return;
    setState(() => _saving = true);
    try {
      final doc = _buildJson();
      final jsonStr = jsonEncode(doc);
      final dao = ref.read(editaisDaoProvider);
      final municipio = ref.read(codigoMunicipioProvider);
      final entidade = ref.read(codigoEntidadeProvider);

      if (_loadedId == null) {
        final id = await dao.insertEdital(
          municipio: municipio,
          entidade: entidade,
          codigoEdital: AudespPncpField.stripMask(_codigoEditalCtrl.text),
          retificacao: _retificacao,
          status: 'draft',
          pdfPath: _pdfPath,
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
        _loadedId = id;
      } else {
        await dao.updateEdital(
          id: _loadedId!,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: AudespPncpField.stripMask(_codigoEditalCtrl.text),
          retificacao: _retificacao,
          status: 'draft',
          pdfPath: _pdfPath,
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
      }
      ref.invalidate(editaisDraftProvider);
      ref.invalidate(editaisEnviadosProvider);

      if (mounted) {
        AudespSnackBar.success(context, 'Rascunho salvo com sucesso.');
      }
    } catch (e) {
      _showError('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Enviar para o AUDESP ──────────────────────────────────────────────────

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itens.isEmpty) {
      _showError('Adicione pelo menos um item de compra.');
      return;
    }

    // Garante que o rascunho mais recente está salvo
    await _saveDraft();
    if (!mounted || _loadedId == null) return;

    final user = ref.read(localSessionProvider);

    await showAudespAuthDialog(
      context,
      ref,
      onConfirm: (token) async {
        final doc = _buildJson();
        if (_criterioJulgamentoId != null) {
          final itens = (doc['itensCompra'] as List<dynamic>)
              .map(
                (item) => <String, dynamic>{
                  ...(item as Map<String, dynamic>),
                  'criterioJulgamentoId': _criterioJulgamentoId,
                },
              )
              .toList();
          doc['itensCompra'] = itens;
        }
        final jsonStr = jsonEncode(doc);
        final service = ref.read(editalServiceProvider);

        final msg = await service.enviarEdital(
          editalId: _loadedId!,
          documentoJson: jsonStr,
          pdfPath: _pdfPath,
          userId: user?.id,
        );

        setState(() => _isSent = true);
        if (mounted) {
          AudespSnackBar.success(context, msg);
          context.go('/edital');
        }
      },
    );
  }

  // ── PDF picker ────────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pdfPath = result.files.single.path);
    }
  }

  // ── Importação via Gemini ─────────────────────────────────────────────────

  Future<void> _importFromDocument() async {
    final geminiService = ref.read(geminiServiceProvider);
    final prompt = geminiService.generatePromptFromFields(kEditalGeminiFields);

    final result = await showAudespAiImportDialog(
      context,
      title: 'Importar Edital via IA',
      promptText: prompt,
    );

    if (result == null || !mounted) return;

    setState(() => _importingGemini = true);
    try {
      final currentValues = <String, String>{
        'codigoEdital': _codigoEditalCtrl.text.trim(),
        'dataDocumento': _dataDoc != null
            ? DateFormat('dd/MM/yyyy').format(_dataDoc!)
            : '',
        'tipoInstrumentoConvocatorioId': _tipoInstrumento?.toString() ?? '',
        'modalidadeId': _modalidade?.toString() ?? '',
        'modoDisputaId': _modoDisputa?.toString() ?? '',
        'criterioJulgamentoId': _criterioJulgamentoId?.toString() ?? '',
        'numeroCompra': _numeroCompraCtrl.text.trim(),
        'anoCompra': _anoCompraCtrl.text.trim(),
        'numeroProcesso': _numeroProcessoCtrl.text.trim(),
        'objetoCompra': _objetoCompraCtrl.text.trim(),
        'srp': _srp.toString(),
        'amparoLegalId': _amparoLegalCtrl.text.trim(),
        'dataAberturaProposta': _dataAbertura != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(_dataAbertura!)
            : '',
        'dataEncerramentoProposta': _dataEncerramento != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(_dataEncerramento!)
            : '',
      };

      Map<String, String>? accepted;

      if (result.mode == AiImportMode.manual) {
        if (result.jsonResponse == null || result.jsonResponse!.isEmpty) return;
        final parsed = geminiService.parseResult(
          result.jsonResponse!,
          kEditalGeminiFields,
        );
        accepted = await showGeminiReviewDialog(
          context: context,
          currentValues: currentValues,
          suggestedValues: parsed,
        );
      } else {
        if (result.filePath == null) return;
        accepted = await showGeminiImportDialog(
          context: context,
          ref: ref,
          pdfPath: result.filePath!,
          currentValues: currentValues,
        );
      }

      if (!mounted || accepted == null || accepted.isEmpty) return;

      final finalAccepted = accepted;
      setState(() {
        if (finalAccepted.containsKey('dataDocumento')) {
          try {
            _dataDoc = DateFormat(
              'dd/MM/yyyy',
            ).parse(finalAccepted['dataDocumento']!);
          } catch (_) {}
        }
        if (finalAccepted.containsKey('tipoInstrumentoConvocatorioId')) {
          _tipoInstrumento = int.tryParse(
            finalAccepted['tipoInstrumentoConvocatorioId']!,
          );
        }
        if (finalAccepted.containsKey('modalidadeId')) {
          _modalidade = int.tryParse(finalAccepted['modalidadeId']!);
        }
        if (finalAccepted.containsKey('modoDisputaId')) {
          _modoDisputa = int.tryParse(finalAccepted['modoDisputaId']!);
        }
        if (finalAccepted.containsKey('numeroCompra')) {
          var v = finalAccepted['numeroCompra']!;
          if (v.contains('/')) v = v.split('/').first;
          _numeroCompraCtrl.text = v;
        }
        if (finalAccepted.containsKey('anoCompra')) {
          _anoCompraCtrl.text = finalAccepted['anoCompra']!;
        }
        if (finalAccepted.containsKey('numeroProcesso')) {
          _numeroProcessoCtrl.text = finalAccepted['numeroProcesso']!;
        }
        if (finalAccepted.containsKey('objetoCompra')) {
          _objetoCompraCtrl.text = finalAccepted['objetoCompra']!;
        }
        if (finalAccepted.containsKey('srp')) {
          _srp = ['true', 'sim'].contains(finalAccepted['srp']?.toLowerCase());
        }
        if (finalAccepted.containsKey('amparoLegalId')) {
          _amparoLegalCtrl.text = _sanitizeAmparoLegal(
            finalAccepted['amparoLegalId']!,
          );
        }
        if (finalAccepted.containsKey('criterioJulgamentoId')) {
          _criterioJulgamentoId = _sanitizeCriterioJulgamento(
            finalAccepted['criterioJulgamentoId']!,
          );
        }
        if (finalAccepted.containsKey('dataAberturaProposta') &&
            finalAccepted['dataAberturaProposta']!.isNotEmpty) {
          try {
            _dataAbertura = DateFormat(
              'dd/MM/yyyy HH:mm',
            ).parse(finalAccepted['dataAberturaProposta']!);
          } catch (_) {}
        }
        if (finalAccepted.containsKey('dataEncerramentoProposta') &&
            finalAccepted['dataEncerramentoProposta']!.isNotEmpty) {
          try {
            _dataEncerramento = DateFormat(
              'dd/MM/yyyy HH:mm',
            ).parse(finalAccepted['dataEncerramentoProposta']!);
          } catch (_) {}
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${finalAccepted.length} campo(s) preenchido(s) pelo Gemini.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importingGemini = false);
    }
  }

  /// Tenta converter o valor bruto do Gemini em código numérico do amparo legal.
  /// Ex.: "Lei 14.133/2021, Art. 28, I - Pregão" → "1"
  static String _sanitizeAmparoLegal(String raw) {
    final trimmed = raw.trim();

    // Já é numérico
    if (int.tryParse(trimmed) != null) return trimmed;

    // Busca por correspondência textual no mapa de amparos legais
    final found = kAmparosLegais.entries.where(
      (e) => e.value.toLowerCase().contains(trimmed.toLowerCase()),
    );
    if (found.length == 1) return found.first.key.toString();

    // Tenta extrair o primeiro número inteiro do texto
    final match = RegExp(r'\d+').firstMatch(trimmed);
    if (match != null) return match.group(0)!;

    return trimmed;
  }

  /// Tenta converter o valor bruto do Gemini em código numérico do critério de julgamento.
  /// Ex.: "Menor preço" → 1, "4" → 4, "Técnica e preço" → 4
  static int? _sanitizeCriterioJulgamento(String raw) {
    final trimmed = raw.trim();

    // Tenta parse numérico direto
    final asInt = int.tryParse(trimmed);
    if (asInt != null) return asInt;

    // Match textual via EditalComplementoCsvMapper
    final fromMapper = EditalComplementoCsvMapper.criterioJulgamentoId(trimmed);
    if (fromMapper != null) return fromMapper;

    // Busca por correspondência parcial no mapa de domínio
    final normalized = trimmed.toLowerCase();
    for (final entry in kCriterioJulgamento.entries) {
      if (entry.value.toLowerCase().contains(normalized)) return entry.key;
    }

    // Tenta extrair o primeiro número inteiro do texto
    final match = RegExp(r'\d+').firstMatch(trimmed);
    if (match != null) return int.tryParse(match.group(0)!);

    return null;
  }

  // ── Date/datetime helpers ─────────────────────────────────────────────────

  /// `yyyy-MM-dd` → `dd/MM/yyyy` (para exibição ao usuário).
  static String _toDisplayDate(String apiDate) {
    if (apiDate.isEmpty) return '';
    try {
      return DateFormat(
        'dd/MM/yyyy',
      ).format(DateFormat('yyyy-MM-dd').parse(apiDate));
    } catch (_) {
      return apiDate;
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    AudespSnackBar.error(context, msg);
  }

  bool _isRejectedStatus(String? status) {
    return status?.toLowerCase().contains('rejeitado') ?? false;
  }

  bool _isProtocoloUpdatable(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    if (s.contains('rejeitado') ||
        s.contains('arquivado') ||
        s.contains('exclu') ||
        s.contains('armazenado') ||
        s.contains('substitu')) {
      return false;
    }
    return true;
  }

  Future<void> _reloadLatestSendLog() async {
    if (_loadedId == null) return;
    final edital = await ref.read(editaisDaoProvider).findById(_loadedId!);
    if (edital == null) return;
    final log = await ref
        .read(apiLogsDaoProvider)
        .findLatestEditalSendLog(
          municipio: edital.municipio,
          entidade: edital.entidade,
          codigoEdital: edital.codigoEdital,
          retificacao: edital.retificacao,
        );
    if (mounted) setState(() => _lastSendLog = log);
  }

  Future<void> _updateProtocoloStatus() async {
    final log = _lastSendLog;
    if (log?.protocolo == null) return;

    await showAudespAuthDialog(
      context,
      ref,
      actionLabel: 'Autenticar e Atualizar',
      onConfirm: (token) async {
        setState(() => _updatingStatus = true);
        try {
          final jsonRetorno = await ref
              .read(consultaServiceProvider)
              .consultarStatus(log!.protocolo!);
          final json = jsonDecode(jsonRetorno);
          final novoStatus = json['status']?.toString() ?? 'Desconhecido';

          await ref
              .read(apiLogsDaoProvider)
              .updateProtocoloInfo(log.id, novoStatus, jsonRetorno);
          await _reloadLatestSendLog();

          if (mounted) {
            AudespSnackBar.success(
              context,
              'Status atualizado para: $novoStatus',
            );
          }
        } catch (e) {
          _showError('Erro ao atualizar status: $e');
        } finally {
          if (mounted) setState(() => _updatingStatus = false);
        }
      },
    );
  }

  Future<void> _returnToDraft() async {
    if (_loadedId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Retornar para rascunho?'),
        content: const Text(
          'O edital voltara para edicao local. Os logs e o protocolo AUDESP serao mantidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.edit_note),
            label: const Text('Retornar para rascunho'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(editaisDaoProvider).markAsDraft(_loadedId!);
      ref.invalidate(editaisDraftProvider);
      ref.invalidate(editaisEnviadosProvider);
      if (mounted) {
        setState(() {
          _isSent = false;
          _lastSendLog = null;
        });
        AudespSnackBar.success(context, 'Edital retornado para rascunho.');
      }
    } catch (e) {
      _showError('Erro ao retornar para rascunho: $e');
    }
  }

  Widget _buildSentHeaderActions() {
    final status = _lastSendLog?.statusProtocolo;
    final rejected = _isRejectedStatus(status);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_lastSendLog?.protocolo != null &&
            _isProtocoloUpdatable(status)) ...[
          IconButton(
            tooltip: 'Atualizar status',
            onPressed: _updatingStatus ? null : _updateProtocoloStatus,
            icon: _updatingStatus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
        if (rejected) ...[
          TextButton.icon(
            onPressed: _returnToDraft,
            icon: const Icon(Icons.edit_note),
            label: const Text('Retornar para rascunho'),
          ),
          const SizedBox(width: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: StatusChip(
            label: status?.isNotEmpty == true ? status! : 'Enviado',
            color: rejected ? scheme.error : null,
            backgroundColor: rejected ? scheme.errorContainer : null,
            borderColor: rejected ? scheme.error.withAlpha(80) : null,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final readOnly = _isSent;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/edital')),
        title: Text(
          _loadedId == null
              ? 'Novo Edital'
              : _isSent
              ? 'Edital'
              : 'Editar Edital',
        ),
        actions: [
          if (!_isSent) ...[
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              TextButton.icon(
                onPressed: _importingGemini ? null : _importFromDocument,
                icon: _importingGemini
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Importar via IA'),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _saveDraft,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar Rascunho'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _enviar,
                icon: const Icon(Icons.send),
                label: const Text('Enviar à AUDESP'),
              ),
              const SizedBox(width: 8),
            ],
          ],
          if (_isSent) _buildSentHeaderActions(),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDescritorSection(readOnly),
              const SizedBox(height: 16),
              _buildPublicidadeSection(readOnly),
              const SizedBox(height: 16),
              _buildDadosGeraisSection(readOnly),
              const SizedBox(height: 16),
              _buildItensSection(readOnly),
              const SizedBox(height: 16),
              _buildPdfSection(readOnly),
            ],
          ),
        ),
      ),
    );
  }

  // ── Seção: Descritor ──────────────────────────────────────────────────────

  Widget _buildDescritorSection(bool readOnly) {
    final municipio = ref.watch(codigoMunicipioProvider);
    final entidade = ref.watch(codigoEntidadeProvider);
    return SectionCard(
      title: 'Descritor',
      children: [
        if (municipio.isNotEmpty || entidade.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Município: $municipio   |   Entidade: $entidade',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: AudespPncpField(
                label: 'ID de Contratação PNCP *',
                controller: _codigoEditalCtrl,
                enabled: !readOnly && !_retificacao,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: AudespDatePickerField(
                label: 'Data do Edital *',
                value: _dataDoc,
                readOnly: readOnly,
                onChanged: (d) => setState(() => _dataDoc = d),
                validator: (d) => d == null ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: AudespCheckbox(
                label: 'Retificação',
                value: _retificacao,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _retificacao = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Seção: Publicidade ────────────────────────────────────────────────────

  Widget _buildPublicidadeSection(bool readOnly) {
    return SectionCard(
      title: 'Publicidade',
      children: [
        AudespCheckbox(
          label: 'Houve Publicação',
          value: _houvePublicacao,
          readOnly: readOnly,
          onChanged: (v) => setState(() {
            _houvePublicacao = v;
            if (!(_houvePublicacao)) _publicacoes.clear();
          }),
        ),
        if (_houvePublicacao) ...[
          const SizedBox(height: 8),
          _buildPublicacoesList(readOnly),
          if (!readOnly)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addPublicacao,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Publicação'),
              ),
            ),
          if (_houvePublicacao && _publicacoes.isEmpty)
            Text(
              'Adicione ao menos uma publicação.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ],
    );
  }

  Widget _buildPublicacoesList(bool readOnly) {
    if (_publicacoes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (int i = 0; i < _publicacoes.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(
                kVeiculosPublicacao[_publicacoes[i]['veiculoPublicacao']] ??
                    'Veículo ${_publicacoes[i]['veiculoPublicacao']}',
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _toDisplayDate(
                      _publicacoes[i]['dataPublicacao'] as String? ?? '',
                    ),
                  ),
                  if (_publicacoes[i]['veiculoPublicacao'] == 5 &&
                      (_publicacoes[i]['idContratacaoPNCP'] as String? ?? '')
                          .isNotEmpty)
                    Text(
                      'ID PNCP: ${PcnpInputFormatter.applyMask(_publicacoes[i]['idContratacaoPNCP'])}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (_publicacoes[i]['veiculoPublicacao'] == 10 &&
                      (_publicacoes[i]['veiculoPublicacaoNome'] as String? ??
                              '')
                          .isNotEmpty)
                    Text(
                      'Veículo: ${_publicacoes[i]['veiculoPublicacaoNome']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              trailing: readOnly
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AudespIconButton(
                          icon: Icons.edit,
                          tooltip: 'Editar publicação',
                          onPressed: () => _editPublicacao(i),
                        ),
                        AudespIconButton(
                          icon: Icons.delete,
                          tooltip: 'Excluir publicação',
                          onPressed: () =>
                              setState(() => _publicacoes.removeAt(i)),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Future<void> _addPublicacao() async {
    final result = await showPublicacaoDialog(context);
    if (result != null) setState(() => _publicacoes.add(result));
  }

  Future<void> _editPublicacao(int index) async {
    final result = await showPublicacaoDialog(
      context,
      initial: _publicacoes[index],
    );
    if (result != null) setState(() => _publicacoes[index] = result);
  }

  // ── Seção: Dados Gerais ───────────────────────────────────────────────────

  Widget _buildDadosGeraisSection(bool readOnly) {
    return SectionCard(
      title: 'Dados Gerais',
      children: [
        // Tipo de Instrumento Convocatório
        AudespDropdown<int>(
          label: 'Tipo de Instrumento Convocatório *',
          value: _tipoInstrumento,
          items: kTipoInstrumento,
          readOnly: readOnly,
          onChanged: (v) => setState(() => _tipoInstrumento = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        // Modalidade
        AudespDropdown<int>(
          label: 'Modalidade de Contratação *',
          value: _modalidade,
          items: kModalidades,
          readOnly: readOnly,
          onChanged: (v) => setState(() => _modalidade = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        // Modo de Disputa
        AudespDropdown<int>(
          label: 'Modo de Disputa *',
          value: _modoDisputa,
          items: kModoDisputa,
          readOnly: readOnly,
          onChanged: (v) => setState(() => _modoDisputa = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        // Critério de Julgamento
        AudespDropdown<int>(
          label: 'Critério de Julgamento *',
          value: _criterioJulgamentoId,
          items: kCriterioJulgamento,
          readOnly: readOnly,
          onChanged: (v) => setState(() => _criterioJulgamentoId = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              flex: 2,
              child: AudespNumberField(
                label: 'Número da Compra *',
                controller: _numeroCompraCtrl,
                enabled: !readOnly,
                hintText: 'Ex.: 14',
                maxLength: 50,
                decimals: false,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
            ),
            AudespFieldRowItem(
              width: 200,
              child: AudespNumberField(
                label: 'Ano da Compra *',
                controller: _anoCompraCtrl,
                enabled: !readOnly,
                hintText: 'Ex.: 2024',
                maxLength: 4,
                decimals: false,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final n = int.tryParse(v);
                  if (n == null || n < 1970 || n > 2099) return '1970–2099';
                  return null;
                },
              ),
            ),
          ],
        ),
        AudespSpacing.verticalMd,
        AudespTextField(
          label: 'Número do Processo *',
          controller: _numeroProcessoCtrl,
          enabled: !readOnly,
          maxLength: 50,
          validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
        ),
        AudespSpacing.verticalMd,
        AudespTextField(
          label: 'Objeto da Contratação *',
          controller: _objetoCompraCtrl,
          enabled: !readOnly,
          maxLength: 5120,
          maxLines: 4,
          validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        AudespTextField(
          label: 'Informações Complementares',
          controller: _infComplementarCtrl,
          enabled: !readOnly,
          maxLength: 5120,
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        AudespCheckbox(
          label: 'SRP – Sistema de Registro de Preços',
          value: _srp,
          readOnly: readOnly,
          onChanged: (v) => setState(() => _srp = v),
        ),
        const SizedBox(height: 12),
        // Datas de propostas
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespDateTimePickerField(
                label: 'Abertura de Propostas *',
                value: _dataAbertura,
                readOnly: readOnly,
                onChanged: (d) => setState(() => _dataAbertura = d),
                validator: (d) {
                  if ((_tipoInstrumento == 1 || _tipoInstrumento == 2) &&
                      d == null) {
                    return 'Obrigatório para instrumento tipo 1 ou 2';
                  }
                  return null;
                },
              ),
            ),
            AudespFieldRowItem(
              child: AudespDateTimePickerField(
                label: 'Encerramento de Propostas *',
                value: _dataEncerramento,
                readOnly: readOnly,
                onChanged: (d) => setState(() => _dataEncerramento = d),
                validator: (d) {
                  if ((_tipoInstrumento == 1 || _tipoInstrumento == 2) &&
                      d == null) {
                    return 'Obrigatório para instrumento tipo 1 ou 2';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Amparo Legal
        _AmparoLegalField(controller: _amparoLegalCtrl, enabled: !readOnly),
        const SizedBox(height: 12),
        /*
        TextFormField(
          controller: _linkSistemaCtrl,
          enabled: !readOnly,
          decoration: const InputDecoration(
            labelText: 'Link do Sistema de Origem',
            hintText: 'https://',
            counterText: '',
          ),
          maxLength: 500,
        ),
        const SizedBox(height: 12),
        */
        AudespTextField(
          label: 'Justificativa para Modalidade Presencial',
          controller: _justificativaCtrl,
          enabled: !readOnly,
          maxLength: 500,
          maxLines: 2,
        ),
      ],
    );
  }

  // ── Importação via CSV ────────────────────────────────────────────────────

  Future<void> _importItemsFromCsv() async {
    final imported = await showEditalImportCsvDialog(
      context,
      existingCount: _itens.length,
    );
    if (imported == null || imported.isEmpty) return;
    setState(() => _itens = imported);
    if (mounted) {
      AudespSnackBar.success(
        context,
        '${imported.length} item(s) importado(s) com sucesso.',
      );
    }
  }

  // ── Seção: Itens de Compra ────────────────────────────────────────────────

  Widget _buildItensSection(bool readOnly) {
    return SectionCard(
      title: 'Itens de Compra',
      titleActions: [
        if (!readOnly) ...[
          TextButton.icon(
            onPressed: _importItemsFromCsv,
            icon: const Icon(Icons.download),
            label: const Text('Importar'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Item'),
          ),
        ],
      ],
      children: [
        if (_itens.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhum item adicionado.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        for (int i = 0; i < _itens.length; i++) _buildItemTile(i, readOnly),
      ],
    );
  }

  Widget _buildItemTile(int index, bool readOnly) {
    final item = _itens[index];
    final beneficio =
        kTipoBeneficio[item['tipoBeneficioId'] as int? ?? 1] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
        ),
        title: Text(
          item['descricao'] as String? ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item['materialOuServico'] == 'M' ? 'Material' : 'Serviço'}  |  '
          '$beneficio  |  '
          'Qtd: ${formatNumberBR((item['quantidade'] as num?)?.toDouble())}  |  '
          'VU: ${formatBRL((item['valorUnitarioEstimado'] as num?)?.toDouble())}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: readOnly
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AudespIconButton(
                    icon: Icons.edit,
                    tooltip: 'Editar item',
                    onPressed: () => _editItem(index),
                  ),
                  AudespIconButton(
                    icon: Icons.delete,
                    tooltip: 'Excluir item',
                    onPressed: () {
                      setState(() {
                        _itens.removeAt(index);
                        for (int j = 0; j < _itens.length; j++) {
                          _itens[j]['numeroItem'] = j + 1;
                        }
                      });
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _addItem() async {
    final numero = _itens.length + 1;
    final result = await showItemCompraDialog(context, numero: numero);
    if (result != null) setState(() => _itens.add(result));
  }

  Future<void> _editItem(int index) async {
    final result = await showItemCompraDialog(
      context,
      numero: index + 1,
      initial: _itens[index],
    );
    if (result != null) setState(() => _itens[index] = result);
  }

  // ── Seção: PDF ────────────────────────────────────────────────────────────

  Widget _buildPdfSection(bool readOnly) {
    return SectionCard(
      title: 'Arquivo PDF',
      titleActions: [
        if (!readOnly) ...[
          TextButton.icon(
            onPressed: _pickPdf,
            icon: const Icon(Icons.upload_file),
            label: Text(_pdfPath == null ? 'Selecionar PDF' : 'Substituir PDF'),
          ),
        ],
      ],
      children: [
        if (_pdfPath != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
              size: 32,
            ),
            title: Text(
              _pdfPath!.split(RegExp(r'[/\\]')).last,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _pdfPath!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: readOnly
                ? null
                : AudespIconButton(
                    icon: Icons.clear,
                    tooltip: 'Remover PDF',
                    onPressed: () => setState(() => _pdfPath = null),
                  ),
          )
        else
          Text(
            'Nenhum PDF selecionado.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
      ],
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

/// Campo de seleção para Amparo Legal.
class _AmparoLegalField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _AmparoLegalField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final selectedCode = int.tryParse(controller.text);

    return AudespDropdown<int>(
      label: 'Amparo Legal *',
      value: kAmparosLegaisValidos.contains(selectedCode) ? selectedCode : null,
      items: kAmparosLegais.map((key, value) => MapEntry(key, value)),
      enabled: enabled,
      onChanged: (value) {
        if (value != null) {
          controller.text = value.toString();
        }
      },
      validator: (value) => value == null ? 'Obrigatório' : null,
    );
  }
}
