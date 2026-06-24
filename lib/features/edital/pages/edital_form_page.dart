import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/auth_providers.dart';
import '../edital_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_field_row.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_pncp_field.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_spacing.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
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
  int? _loadedId;

  // ── Descritor ────────────────────────────────────────────────────────────
  final _codigoEditalCtrl = TextEditingController();
  DateTime? _dataDoc;
  bool _retificacao = false;

  // ── Publicidade ──────────────────────────────────────────────────────────
  bool _houvePublicacao = false;
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
  final _dataAberturaCtrl = TextEditingController();
  final _dataEncerramentoCtrl = TextEditingController();
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
    _dataAberturaCtrl.dispose();
    _dataEncerramentoCtrl.dispose();
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
    _dataAberturaCtrl.text = _toDisplayDateTime(
      doc['dataAberturaProposta'] as String? ?? '',
    );
    _dataEncerramentoCtrl.text = _toDisplayDateTime(
      doc['dataEncerramentoProposta'] as String? ?? '',
    );
    _amparoLegalCtrl.text = doc['amparoLegalId']?.toString() ?? '';
    _linkSistemaCtrl.text = doc['linkSistemaOrigem'] as String? ?? '';
    _justificativaCtrl.text = doc['justificativaPresencial'] as String? ?? '';
    _itens = (doc['itensCompra'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

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
      'numeroCompra': _numeroCompraCtrl.text.trim(),
      'anoCompra': int.tryParse(_anoCompraCtrl.text.trim()) ?? 0,
      'numeroProcesso': _numeroProcessoCtrl.text.trim(),
      'objetoCompra': _objetoCompraCtrl.text.trim(),
      'srp': _srp,
      'amparoLegalId': int.tryParse(_amparoLegalCtrl.text.trim()),
      'itensCompra': _itens.map((item) {
        if (_criterioJulgamentoId != null) {
          return <String, dynamic>{
            ...item,
            'criterioJulgamentoId': _criterioJulgamentoId,
          };
        }
        return item;
      }).toList(),
    };

    if (_codigoUnidadeCtrl.text.trim().isNotEmpty) {
      map['codigoUnidadeCompradora'] = _codigoUnidadeCtrl.text.trim();
    }
    if (_infComplementarCtrl.text.trim().isNotEmpty) {
      map['informacaoComplementar'] = _infComplementarCtrl.text.trim();
    }
    if (_dataAberturaCtrl.text.trim().isNotEmpty) {
      map['dataAberturaProposta'] = _fromDisplayDateTime(
        _dataAberturaCtrl.text.trim(),
      );
    }
    if (_dataEncerramentoCtrl.text.trim().isNotEmpty) {
      map['dataEncerramentoProposta'] = _fromDisplayDateTime(
        _dataEncerramentoCtrl.text.trim(),
      );
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

  Future<void> _importFromPdf() async {
    // Seleciona o PDF para análise
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

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
        'numeroCompra': _numeroCompraCtrl.text.trim(),
        'anoCompra': _anoCompraCtrl.text.trim(),
        'numeroProcesso': _numeroProcessoCtrl.text.trim(),
        'objetoCompra': _objetoCompraCtrl.text.trim(),
        'srp': _srp.toString(),
        'amparoLegalId': _amparoLegalCtrl.text.trim(),
        'dataAberturaProposta': _dataAberturaCtrl.text.trim(),
        'dataEncerramentoProposta': _dataEncerramentoCtrl.text.trim(),
      };

      final accepted = await showGeminiImportDialog(
        context: context,
        ref: ref,
        pdfPath: result.files.single.path!,
        currentValues: currentValues,
      );

      if (!mounted || accepted == null || accepted.isEmpty) return;

      setState(() {
        if (accepted.containsKey('dataDocumento')) {
          try {
            _dataDoc = DateFormat(
              'dd/MM/yyyy',
            ).parse(accepted['dataDocumento']!);
          } catch (_) {}
        }
        if (accepted.containsKey('tipoInstrumentoConvocatorioId')) {
          _tipoInstrumento = int.tryParse(
            accepted['tipoInstrumentoConvocatorioId']!,
          );
        }
        if (accepted.containsKey('modalidadeId')) {
          _modalidade = int.tryParse(accepted['modalidadeId']!);
        }
        if (accepted.containsKey('modoDisputaId')) {
          _modoDisputa = int.tryParse(accepted['modoDisputaId']!);
        }
        if (accepted.containsKey('numeroCompra')) {
          var v = accepted['numeroCompra']!;
          if (v.contains('/')) v = v.split('/').first;
          _numeroCompraCtrl.text = v;
        }
        if (accepted.containsKey('anoCompra')) {
          _anoCompraCtrl.text = accepted['anoCompra']!;
        }
        if (accepted.containsKey('numeroProcesso')) {
          _numeroProcessoCtrl.text = accepted['numeroProcesso']!;
        }
        if (accepted.containsKey('objetoCompra')) {
          _objetoCompraCtrl.text = accepted['objetoCompra']!;
        }
        if (accepted.containsKey('srp')) {
          _srp = ['true', 'sim'].contains(accepted['srp']?.toLowerCase());
        }
        if (accepted.containsKey('amparoLegalId')) {
          _amparoLegalCtrl.text = _sanitizeAmparoLegal(
            accepted['amparoLegalId']!,
          );
        }
        if (accepted.containsKey('dataAberturaProposta')) {
          _dataAberturaCtrl.text = accepted['dataAberturaProposta']!;
        }
        if (accepted.containsKey('dataEncerramentoProposta')) {
          _dataEncerramentoCtrl.text = accepted['dataEncerramentoProposta']!;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${accepted.length} campo(s) preenchido(s) pelo Gemini.',
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

  /// `yyyy-MM-ddTHH:mm:ss` → `dd/MM/yyyy HH:mm`.
  static String _toDisplayDateTime(String apiDt) {
    if (apiDt.isEmpty) return '';
    try {
      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(apiDt));
    } catch (_) {
      return apiDt;
    }
  }

  /// `dd/MM/yyyy HH:mm` → `yyyy-MM-ddTHH:mm:ss`.
  static String _fromDisplayDateTime(String display) {
    if (display.isEmpty) return '';
    try {
      final d = DateFormat('dd/MM/yyyy HH:mm').parse(display);
      return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);
    } catch (_) {
      return display;
    }
  }

  Future<void> _pickDateTime(TextEditingController ctrl) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(
      () => ctrl.text =
          '${DateFormat('dd/MM/yyyy').format(date)} '
          '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}',
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    AudespSnackBar.error(context, msg);
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
                onPressed: _importingGemini ? null : _importFromPdf,
                icon: _importingGemini
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Importar do PDF'),
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
          if (_isSent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StatusChip.document('sent'),
            ),
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
                onChanged: (v) => setState(() => _retificacao = v ?? false),
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
            _houvePublicacao = v ?? false;
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
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editPublicacao(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
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
          onChanged: readOnly
              ? null
              : (v) => setState(() => _tipoInstrumento = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        // Modalidade
        AudespDropdown<int>(
          label: 'Modalidade de Contratação *',
          value: _modalidade,
          items: kModalidades,
          onChanged: readOnly ? null : (v) => setState(() => _modalidade = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        // Modo de Disputa
        AudespDropdown<int>(
          label: 'Modo de Disputa *',
          value: _modoDisputa,
          items: kModoDisputa,
          onChanged: readOnly ? null : (v) => setState(() => _modoDisputa = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        // Critério de Julgamento
        AudespDropdown<int>(
          label: 'Critério de Julgamento *',
          value: _criterioJulgamentoId,
          items: kCriterioJulgamento,
          onChanged: readOnly
              ? null
              : (v) => setState(() => _criterioJulgamentoId = v),
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
          onChanged: (v) => setState(() => _srp = v ?? false),
        ),
        const SizedBox(height: 12),
        // Datas de propostas
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespTextField(
                label: 'Abertura de Propostas *',
                controller: _dataAberturaCtrl,
                readOnly: true,
                enabled: !readOnly,
                hintText: 'dd/MM/yyyy HH:mm',
                suffixIcon: const Icon(Icons.event),
                helperText: 'Obrigatório para instrumento tipo 1 ou 2',
                onTap: readOnly ? null : () => _pickDateTime(_dataAberturaCtrl),
                validator: (v) {
                  if ((_tipoInstrumento == 1 || _tipoInstrumento == 2) &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Obrigatório para instrumento tipo 1 ou 2';
                  }
                  return null;
                },
              ),
            ),
            AudespFieldRowItem(
              child: AudespTextField(
                label: 'Encerramento de Propostas *',
                controller: _dataEncerramentoCtrl,
                readOnly: true,
                enabled: !readOnly,
                hintText: 'dd/MM/yyyy HH:mm',
                suffixIcon: const Icon(Icons.event),
                helperText: 'Obrigatório para instrumento tipo 1 ou 2',
                onTap: readOnly
                    ? null
                    : () => _pickDateTime(_dataEncerramentoCtrl),
                validator: (v) {
                  if ((_tipoInstrumento == 1 || _tipoInstrumento == 2) &&
                      (v == null || v.trim().isEmpty)) {
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
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editItem(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () {
                      setState(() {
                        _itens.removeAt(index);
                        // Renumera
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
                : IconButton(
                    icon: const Icon(Icons.clear),
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
