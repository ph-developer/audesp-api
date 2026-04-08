import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../domain/edital_domain.dart';
import '../services/edital_service.dart';
import '../widgets/item_compra_dialog.dart';
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
  // ── Carregamento ──────────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  bool _isSent = false;
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
  final List<Map<String, dynamic>> _itens = [];

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

    _codigoEditalCtrl.text = descritor['codigoEdital'] as String? ?? edital.codigoEdital;
    final dataDocStr = descritor['dataDocumento'] as String? ?? '';
    if (dataDocStr.isNotEmpty) {
      try {
        _dataDoc = DateFormat('yyyy-MM-dd').parse(dataDocStr);
      } catch (_) {}
    }
    _retificacao = descritor['retificacao'] as bool? ?? edital.retificacao;

    _houvePublicacao = publicidade['houvePublicacao'] as bool? ?? false;
    _publicacoes =
        (publicidade['publicacoes'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

    _codigoUnidadeCtrl.text = doc['codigoUnidadeCompradora'] as String? ?? '';
    _tipoInstrumento = doc['tipoInstrumentoConvocatorioId'] as int?;
    _modalidade = doc['modalidadeId'] as int?;
    _modoDisputa = doc['modoDisputaId'] as int?;
    _numeroCompraCtrl.text = doc['numeroCompra'] as String? ?? '';
    _anoCompraCtrl.text = doc['anoCompra']?.toString() ?? '';
    _numeroProcessoCtrl.text = doc['numeroProcesso'] as String? ?? '';
    _objetoCompraCtrl.text = doc['objetoCompra'] as String? ?? '';
    _infComplementarCtrl.text = doc['informacaoComplementar'] as String? ?? '';
    _srp = doc['srp'] as bool? ?? false;
    _amparoLegalCtrl.text = doc['amparoLegalId']?.toString() ?? '';
    _linkSistemaCtrl.text = doc['linkSistemaOrigem'] as String? ?? '';
    _justificativaCtrl.text = doc['justificativaPresencial'] as String? ?? '';
    final dataAberturaStr = doc['dataAberturaProposta'] as String? ?? '';
    if (dataAberturaStr.isNotEmpty) {
      try {
        _dataAbertura =
            DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(dataAberturaStr);
      } catch (_) {}
    }
    final dataEncerramentoStr =
        doc['dataEncerramentoProposta'] as String? ?? '';
    if (dataEncerramentoStr.isNotEmpty) {
      try {
        _dataEncerramento =
            DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(dataEncerramentoStr);
      } catch (_) {}
    }

    if (mounted) setState(() => _loading = false);
  }

  // ── Build JSON ────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final sessionUser = ref.read(localSessionProvider);
    final municipio = int.tryParse(sessionUser?.municipio ?? '') ?? 0;
    final entidade = int.tryParse(sessionUser?.entidade ?? '') ?? 0;
    final map = <String, dynamic>{
      'descritor': {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': _codigoEditalCtrl.text.trim(),
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
      'itensCompra': _itens,
    };

    if (_codigoUnidadeCtrl.text.trim().isNotEmpty) {
      map['codigoUnidadeCompradora'] = _codigoUnidadeCtrl.text.trim();
    }
    if (_infComplementarCtrl.text.trim().isNotEmpty) {
      map['informacaoComplementar'] = _infComplementarCtrl.text.trim();
    }
    if (_dataAbertura != null) {
      map['dataAberturaProposta'] =
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_dataAbertura!);
    }
    if (_dataEncerramento != null) {
      map['dataEncerramentoProposta'] =
          DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(_dataEncerramento!);
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

  Future<void> _saveDraft() async {
    final err = _validateForm();
    if (err != null) {
      _showError(err);
      return;
    }
    if (_itens.isEmpty) {
      _showError('Adicione pelo menos um item de compra.');
      return;
    }
    setState(() => _saving = true);
    try {
      final doc = _buildJson();
      final jsonStr = jsonEncode(doc);
      final dao = ref.read(editaisDaoProvider);
      final sessionUser = ref.read(localSessionProvider);
      final municipio = sessionUser?.municipio ?? '';
      final entidade = sessionUser?.entidade ?? '';

      if (_loadedId == null) {
        final id = await dao.insertEdital(
          EditaisCompanion(
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoEdital: Value(_codigoEditalCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            pdfPath: Value(_pdfPath),
            documentoJson: Value(jsonStr),
            updatedAt: Value(DateTime.now()),
          ),
        );
        _loadedId = id;
      } else {
        await dao.updateEdital(
          EditaisCompanion(
            id: Value(_loadedId!),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoEdital: Value(_codigoEditalCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            pdfPath: Value(_pdfPath),
            documentoJson: Value(jsonStr),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      if (mounted) {
        displayInfoBar(context,
            builder: (ctx, close) => const InfoBar(
                title: Text('Rascunho salvo com sucesso.'),
                severity: InfoBarSeverity.success));
      }
    } catch (e) {
      _showError('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Enviar para o AUDESP ──────────────────────────────────────────────────

  Future<void> _enviar() async {
    final err = _validateForm();
    if (err != null) {
      _showError(err);
      return;
    }
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
          displayInfoBar(context,
              builder: (ctx, close) =>
                  InfoBar(title: Text(msg), severity: InfoBarSeverity.success));
          context.go('/edital');
        }
      },
    );
  }

  // ── PDF picker ────────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pdfPath = result.files.single.path);
    }
  }

  // ── Validação manual ─────────────────────────────────────────────────────

  String? _validateForm() {
    if (_codigoEditalCtrl.text.trim().isEmpty) {
      return 'Código do Edital é obrigatório.';
    }
    if (_dataDoc == null) return 'Data do Edital é obrigatória.';
    if (_tipoInstrumento == null) return 'Tipo de Instrumento é obrigatório.';
    if (_modalidade == null) return 'Modalidade é obrigatória.';
    if (_modoDisputa == null) return 'Modo de Disputa é obrigatório.';
    if (_numeroCompraCtrl.text.trim().isEmpty) {
      return 'Número da Compra é obrigatório.';
    }
    final ano = int.tryParse(_anoCompraCtrl.text.trim());
    if (ano == null || ano < 1970 || ano > 2099) {
      return 'Ano da Compra inválido (1970–2099).';
    }
    if (_numeroProcessoCtrl.text.trim().isEmpty) {
      return 'Número do Processo é obrigatório.';
    }
    if (_objetoCompraCtrl.text.trim().isEmpty) {
      return 'Objeto da Contratação é obrigatório.';
    }
    final amparoId = int.tryParse(_amparoLegalCtrl.text.trim());
    if (amparoId == null) return 'Amparo Legal é obrigatório.';
    if (!kAmparosLegaisValidos.contains(amparoId)) {
      return 'Código de Amparo Legal inválido.';
    }
    return null;
  }

  // ── Data helper ──────────────────────────────────────────────────────────

  /// `yyyy-MM-dd` → `dd/MM/yyyy` (para exibição nas publicações).
  static String _toDisplayDate(String apiDate) {
    if (apiDate.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy')
          .format(DateFormat('yyyy-MM-dd').parse(apiDate));
    } catch (_) {
      return apiDate;
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    displayInfoBar(context,
        builder: (ctx, close) =>
            InfoBar(title: Text(msg), severity: InfoBarSeverity.error));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ScaffoldPage(content: Center(child: ProgressRing()));
    }

    final isNew = widget.editalId == null;
    final readonly = _isSent;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/edital'),
        ),
        title: Text(isNew ? 'Novo Edital' : 'Editar Edital'),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isSent) ...(_saving
                ? [
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: ProgressRing(strokeWidth: 2))
                  ]
                : [
                    Button(
                      onPressed: _saveDraft,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_outlined),
                          SizedBox(width: 6),
                          Text('Salvar Rascunho'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _enviar,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 6),
                          Text('Enviar à AUDESP'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ]),
            if (_isSent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context)
                      .accentColor
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 16,
                        color: FluentTheme.of(context).accentColor),
                    const SizedBox(width: 4),
                    Text('Enviado',
                        style: TextStyle(
                            color: FluentTheme.of(context).accentColor)),
                  ],
                ),
              ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDescritorSection(readonly),
            const SizedBox(height: 16),
            _buildPublicidadeSection(readonly),
            const SizedBox(height: 16),
            _buildDadosGeraisSection(readonly),
            const SizedBox(height: 16),
            _buildItensSection(readonly),
            const SizedBox(height: 16),
            _buildPdfSection(readonly),
          ],
        ),
      ),
    );
  }

  // ── Seção: Descritor ──────────────────────────────────────────────────────

  Widget _buildDescritorSection(bool readonly) {
    final sessionUser = ref.read(localSessionProvider);
    return _SectionCard(
      title: 'Descritor',
      children: [
        if (sessionUser != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Município: ${sessionUser.municipio}   |   Entidade: ${sessionUser.entidade}',
              style: FluentTheme.of(context).typography.caption,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: InfoLabel(
                label: 'Código do Edital *',
                child: TextBox(
                  controller: _codigoEditalCtrl,
                  enabled: !readonly && !_retificacao,
                  placeholder: 'Até 25 caracteres',
                  maxLength: 25,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoLabel(
                label: 'Data do Edital *',
                child: DatePicker(
                  selected: _dataDoc,
                  onChanged:
                      readonly ? null : (v) => setState(() => _dataDoc = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ToggleSwitch(
          checked: _retificacao,
          onChanged:
              readonly ? null : (v) => setState(() => _retificacao = v),
          content: const Text(
              'Retificação – marque se este documento corrige uma prestação já enviada'),
        ),
      ],
    );
  }

  // ── Seção: Publicidade ────────────────────────────────────────────────────

  Widget _buildPublicidadeSection(bool readonly) {
    return _SectionCard(
      title: 'Publicidade',
      children: [
        ToggleSwitch(
          checked: _houvePublicacao,
          onChanged: readonly
              ? null
              : (v) => setState(() {
                    _houvePublicacao = v;
                    if (!v) _publicacoes.clear();
                  }),
          content: const Text('Houve Publicação *'),
        ),
        if (_houvePublicacao) ...[
          const SizedBox(height: 8),
          _buildPublicacoesList(readonly),
          if (!readonly)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Button(
                onPressed: _addPublicacao,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 6),
                    Text('Adicionar Publicação'),
                  ],
                ),
              ),
            ),
          if (_houvePublicacao && _publicacoes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Adicione ao menos uma publicação.',
                style: TextStyle(
                    color: Colors.red.toAccentColor().defaultBrushFor(
                        FluentTheme.of(context).brightness)),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPublicacoesList(bool readonly) {
    if (_publicacoes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (int i = 0; i < _publicacoes.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: FluentTheme.of(context)
                          .resources
                          .controlFillColorDefault,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kVeiculosPublicacao[
                                  _publicacoes[i]['veiculoPublicacao']] ??
                              'Veículo ${_publicacoes[i]['veiculoPublicacao']}',
                        ),
                        Text(_toDisplayDate(_publicacoes[i]['dataPublicacao']
                                as String? ??
                            '')),
                      ],
                    ),
                  ),
                  if (!readonly)
                    Row(
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
    final result =
        await showPublicacaoDialog(context, initial: _publicacoes[index]);
    if (result != null) setState(() => _publicacoes[index] = result);
  }

  // ── Seção: Dados Gerais ───────────────────────────────────────────────────

  Widget _buildDadosGeraisSection(bool readonly) {
    return _SectionCard(
      title: 'Dados Gerais',
      children: [
        // Código da Unidade Compradora (facultativo)
        InfoLabel(
          label: 'Código da Unidade Compradora (PNCP) – facultativo',
          child: TextBox(
            controller: _codigoUnidadeCtrl,
            enabled: !readonly,
            maxLength: 20,
          ),
        ),
        const SizedBox(height: 12),
        // Tipo de Instrumento Convocatório
        InfoLabel(
          label: 'Tipo de Instrumento Convocatório *',
          child: ComboBox<int>(
            value: _tipoInstrumento,
            placeholder: const Text('Selecione...'),
            isExpanded: true,
            items: kTipoInstrumento.entries
                .map((e) => ComboBoxItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged:
                readonly ? null : (v) => setState(() => _tipoInstrumento = v),
          ),
        ),
        const SizedBox(height: 12),
        // Modalidade
        InfoLabel(
          label: 'Modalidade de Contratação *',
          child: ComboBox<int>(
            value: _modalidade,
            placeholder: const Text('Selecione...'),
            isExpanded: true,
            items: kModalidades.entries
                .map((e) => ComboBoxItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged:
                readonly ? null : (v) => setState(() => _modalidade = v),
          ),
        ),
        const SizedBox(height: 12),
        // Modo de Disputa
        InfoLabel(
          label: 'Modo de Disputa *',
          child: ComboBox<int>(
            value: _modoDisputa,
            placeholder: const Text('Selecione...'),
            isExpanded: true,
            items: kModoDisputa.entries
                .map((e) => ComboBoxItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged:
                readonly ? null : (v) => setState(() => _modoDisputa = v),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: InfoLabel(
                label: 'Número da Compra *',
                child: TextBox(
                  controller: _numeroCompraCtrl,
                  enabled: !readonly,
                  placeholder: 'Ex.: 14',
                  maxLength: 50,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoLabel(
                label: 'Ano da Compra *',
                child: TextBox(
                  controller: _anoCompraCtrl,
                  enabled: !readonly,
                  placeholder: 'Ex.: 2024',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InfoLabel(
          label: 'Número do Processo *',
          child: TextBox(
            controller: _numeroProcessoCtrl,
            enabled: !readonly,
            maxLength: 50,
          ),
        ),
        const SizedBox(height: 12),
        InfoLabel(
          label: 'Objeto da Contratação *',
          child: TextBox(
            controller: _objetoCompraCtrl,
            enabled: !readonly,
            maxLength: 5120,
            maxLines: 4,
          ),
        ),
        const SizedBox(height: 12),
        InfoLabel(
          label: 'Informações Complementares – facultativo',
          child: TextBox(
            controller: _infComplementarCtrl,
            enabled: !readonly,
            maxLength: 5120,
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 8),
        ToggleSwitch(
          checked: _srp,
          onChanged: readonly ? null : (v) => setState(() => _srp = v),
          content: const Text('SRP – Sistema de Registro de Preços'),
        ),
        const SizedBox(height: 12),
        // Datas de propostas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InfoLabel(
                label: 'Abertura de Propostas',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DatePicker(
                      selected: _dataAbertura,
                      onChanged: readonly
                          ? null
                          : (date) => setState(() {
                                final prev = _dataAbertura;
                                _dataAbertura = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    prev?.hour ?? 0,
                                    prev?.minute ?? 0);
                              }),
                    ),
                    const SizedBox(height: 4),
                    TimePicker(
                      selected: _dataAbertura,
                      onChanged: readonly
                          ? null
                          : (time) => setState(() {
                                final base =
                                    _dataAbertura ?? DateTime.now();
                                _dataAbertura = DateTime(base.year,
                                    base.month, base.day, time.hour,
                                    time.minute);
                              }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoLabel(
                label: 'Encerramento de Propostas',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DatePicker(
                      selected: _dataEncerramento,
                      onChanged: readonly
                          ? null
                          : (date) => setState(() {
                                final prev = _dataEncerramento;
                                _dataEncerramento = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    prev?.hour ?? 0,
                                    prev?.minute ?? 0);
                              }),
                    ),
                    const SizedBox(height: 4),
                    TimePicker(
                      selected: _dataEncerramento,
                      onChanged: readonly
                          ? null
                          : (time) => setState(() {
                                final base =
                                    _dataEncerramento ?? DateTime.now();
                                _dataEncerramento = DateTime(base.year,
                                    base.month, base.day, time.hour,
                                    time.minute);
                              }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Amparo Legal
        _AmparoLegalField(
          controller: _amparoLegalCtrl,
          enabled: !readonly,
        ),
        const SizedBox(height: 12),
        InfoLabel(
          label: 'Link do Sistema de Origem – facultativo',
          child: TextBox(
            controller: _linkSistemaCtrl,
            enabled: !readonly,
            placeholder: 'https://',
            maxLength: 500,
          ),
        ),
        const SizedBox(height: 12),
        InfoLabel(
          label:
              'Justificativa para Modalidade Presencial – facultativo',
          child: TextBox(
            controller: _justificativaCtrl,
            enabled: !readonly,
            maxLength: 500,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
  // ── Seção: Itens de Compra ────────────────────────────────────────────────

  Widget _buildItensSection(bool readonly) {
    return _SectionCard(
      title: 'Itens de Compra',
      children: [
        if (_itens.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhum item adicionado.',
              style: TextStyle(color: FluentTheme.of(context).inactiveColor),
            ),
          ),
        for (int i = 0; i < _itens.length; i++) _buildItemTile(i, readonly),
        if (!readonly)
          Button(
            onPressed: _addItem,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 6),
                Text('Adicionar Item'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemTile(int index, bool readonly) {
    final item = _itens[index];
    final beneficio =
        kTipoBeneficio[item['tipoBeneficioId'] as int? ?? 1] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: FluentTheme.of(context)
                    .resources
                    .controlFillColorDefault,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child:
                  Text('${index + 1}', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['descricao'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item['materialOuServico'] == 'M' ? 'Material' : 'Serviço'}  |  '
                    '$beneficio  |  '
                    'Qtd: ${item['quantidade']}  |  '
                    'VU: R\$ ${item['valorUnitarioEstimado']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!readonly)
              Row(
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
                        for (int j = 0; j < _itens.length; j++) {
                          _itens[j]['numeroItem'] = j + 1;
                        }
                      });
                    },
                  ),
                ],
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

  Widget _buildPdfSection(bool readonly) {
    return _SectionCard(
      title: 'Arquivo PDF',
      children: [
        if (_pdfPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pdfPath!.split(RegExp(r'[/\\]')).last,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _pdfPath!,
                        overflow: TextOverflow.ellipsis,
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ],
                  ),
                ),
                if (!readonly)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _pdfPath = null),
                  ),
              ],
            ),
          )
        else
          Text(
            'Nenhum PDF selecionado.',
            style:
                TextStyle(color: FluentTheme.of(context).inactiveColor),
          ),
        if (!readonly) ...[
          const SizedBox(height: 8),
          Button(
            onPressed: _pickPdf,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.upload_file),
                const SizedBox(width: 6),
                Text(_pdfPath == null ? 'Selecionar PDF' : 'Substituir PDF'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'O PDF será enviado junto com os dados ao AUDESP.',
            style: FluentTheme.of(context).typography.caption,
          ),
        ],
      ],
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: FluentTheme.of(context)
                  .typography
                  .bodyStrong
                  ?.copyWith(
                    color: FluentTheme.of(context).accentColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Campo de autocomplete para Amparo Legal (100+ valores).
class _AmparoLegalField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  const _AmparoLegalField({required this.controller, required this.enabled});

  @override
  State<_AmparoLegalField> createState() => _AmparoLegalFieldState();
}

class _AmparoLegalFieldState extends State<_AmparoLegalField> {
  late final TextEditingController _displayCtrl;

  @override
  void initState() {
    super.initState();
    _displayCtrl = TextEditingController();
    final code = int.tryParse(widget.controller.text);
    if (code != null && kAmparosLegais.containsKey(code)) {
      _displayCtrl.text = '$code – ${kAmparosLegais[code]}';
    }
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = kAmparosLegais.entries
        .map((e) => AutoSuggestBoxItem<int>(
              value: e.key,
              label: '${e.key} – ${e.value}',
            ))
        .toList();
    return InfoLabel(
      label: 'Amparo Legal *',
      child: AutoSuggestBox<int>(
        controller: _displayCtrl,
        enabled: widget.enabled,
        placeholder: 'Digite o código ou pesquise a descrição',
        items: items,
        onSelected: (item) {
          widget.controller.text = item.value!.toString();
        },
      ),
    );
  }
}
