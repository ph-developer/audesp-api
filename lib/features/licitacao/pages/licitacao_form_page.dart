import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../domain/licitacao_domain.dart';
import '../services/licitacao_service.dart';
import '../widgets/item_licitacao_dialog.dart';

/// Formulário de criação/edição de Licitação (Fase 5 – Módulo 2).
///
/// [licitacaoId] null → criar novo; não-null → editar existente.
class LicitacaoFormPage extends ConsumerStatefulWidget {
  final int? licitacaoId;
  final int? preselectedEditalId;
  const LicitacaoFormPage({super.key, this.licitacaoId, this.preselectedEditalId});

  @override
  ConsumerState<LicitacaoFormPage> createState() => _LicitacaoFormPageState();
}

class _LicitacaoFormPageState extends ConsumerState<LicitacaoFormPage> {
  bool _loading = true;
  bool _saving = false;
  bool _isSent = false;
  int? _loadedId;

  // ── Vínculo com Edital ─────────────────────────────────────────────────
  int? _editalId;
  List<Editai> _editais = [];

  // ── Descritor ─────────────────────────────────────────────────────────
  final _codigoEditalCtrl = TextEditingController();
  bool _retificacao = false;

  // ── Seção BID ──────────────────────────────────────────────────────────
  int? _recursoBID;
  int? _aberturaPreQualificacaoBID;
  int? _editalPreQualificacaoBID;
  int? _julgamentoPreQualificacaoBID;
  int? _edital2FaseBID;
  int? _julgamentoPropostasBID;
  int? _julgamentoNegociacaoBID;

  // ── Dados Gerais ───────────────────────────────────────────────────────
  int? _tipoNatureza;
  int? _viabilidadeContratacao;
  int? _interposicaoRecurso;
  int? _audienciaPublica;
  int? _exigenciaGarantiaLicitantes;
  final _percentualValorCtrl = TextEditingController();
  int? _exigenciaAmostra;

  // Quitação de tributos
  bool? _quitacaoFederal;
  bool? _quitacaoEstadual;
  bool? _quitacaoMunicipal;

  int? _exigenciaVisitaTecnica;
  bool? _exigenciaCurriculo;
  bool? _exigenciaVistoCREA;
  bool? _declaracaoRecursos;

  // Fontes de recurso (multi-select)
  Set<int> _fontesRecurso = {};

  // Contratação conduzida por órgão externo
  bool _contratacaoConduzida = false;
  List<String> _cpfsCondutores = [];
  final _cpfCondutorCtrl = TextEditingController();

  // Índices econômicos
  int? _exigenciaIndicesEconomicos;
  List<Map<String, dynamic>> _indicesEconomicos = [];

  // ── Itens ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _itens = [];

  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _codigoEditalCtrl.dispose();
    _percentualValorCtrl.dispose();
    _cpfCondutorCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Carrega editais disponíveis
    final editaisDao = ref.read(editaisDaoProvider);
    _editais = await editaisDao.watchAll().first;

    if (widget.preselectedEditalId != null) {
      _editalId = widget.preselectedEditalId;
      _fillEditalDescriptor();
    }

    if (widget.licitacaoId != null) {
      await _loadExisting(widget.licitacaoId!);
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillEditalDescriptor() {
    if (_editalId == null) return;
    final edital = _editais.where((e) => e.id == _editalId).firstOrNull;
    if (edital != null && _codigoEditalCtrl.text.isEmpty) {
      _codigoEditalCtrl.text = edital.codigoEdital;
      _retificacao = edital.retificacao;
    }
  }

  Future<void> _loadExisting(int id) async {
    final dao = ref.read(licitacoesDaoProvider);
    final licitacao = await dao.findById(id);
    if (licitacao == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _loadedId = licitacao.id;
    _isSent = licitacao.status == 'sent';
    _editalId = licitacao.editalId;

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(licitacao.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    _codigoEditalCtrl.text =
        descritor['codigoEdital'] as String? ?? licitacao.codigoEdital;
    _retificacao = descritor['retificacao'] as bool? ?? licitacao.retificacao;

    _recursoBID = doc['recursoBID'] as int?;
    _aberturaPreQualificacaoBID = doc['aberturaPreQualificacaoBID'] as int?;
    _editalPreQualificacaoBID = doc['editalPreQualificacaoBID'] as int?;
    _julgamentoPreQualificacaoBID = doc['julgamentoPreQualificacaoBID'] as int?;
    _edital2FaseBID = doc['edital2FaseBID'] as int?;
    _julgamentoPropostasBID = doc['julgamentoPropostasBID'] as int?;
    _julgamentoNegociacaoBID = doc['julgamentoNegociacaoBID'] as int?;

    _tipoNatureza = doc['tipoNatureza'] as int?;
    _viabilidadeContratacao = doc['viabilidadeContratacao'] as int?;
    _interposicaoRecurso = doc['interposicaoRecurso'] as int?;
    _audienciaPublica = doc['audienciaPublica'] as int?;
    _exigenciaGarantiaLicitantes = doc['exigenciaGarantiaLicitantes'] as int?;
    _percentualValorCtrl.text =
        doc['percentualValor']?.toString() ?? '';
    _exigenciaAmostra = doc['exigenciaAmostra'] as int?;
    _quitacaoFederal = doc['quitacaoTributosFederais'] as bool?;
    _quitacaoEstadual = doc['quitacaoTributosEstaduais'] as bool?;
    _quitacaoMunicipal = doc['quitacaoTributosMunicipais'] as bool?;
    _exigenciaVisitaTecnica = doc['exigenciaVisitaTecnica'] as int?;
    _exigenciaCurriculo = doc['exigenciaCurriculo'] as bool?;
    _exigenciaVistoCREA = doc['exigenciaVistoCREA'] as bool?;
    _declaracaoRecursos = doc['declaracaoRecursosContratacao'] as bool?;

    final fontes = doc['fonteRecursosContratacao'] as List<dynamic>? ?? [];
    _fontesRecurso = fontes.map((e) => (e as num).toInt()).toSet();

    _contratacaoConduzida = doc['contratacaoConduzida'] as bool? ?? false;
    _cpfsCondutores = (doc['cpfsCondutores'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['cpfCondutor'] as String)
        .toList();

    _exigenciaIndicesEconomicos = doc['exigenciaIndicesEconomicos'] as int?;
    _indicesEconomicos =
        (doc['indicesEconomicos'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    _itens = (doc['itens'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (mounted) setState(() => _loading = false);
  }

  // ── JSON builder ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final sessionUser = ref.read(localSessionProvider);
    final municipio = int.tryParse(sessionUser?.municipio ?? '') ?? 0;
    final entidade = int.tryParse(sessionUser?.entidade ?? '') ?? 0;

    final map = <String, dynamic>{
      'descritor': {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': _codigoEditalCtrl.text.trim(),
        'retificacao': _retificacao,
      },
      'recursoBID': _recursoBID,
      'tipoNatureza': _tipoNatureza,
      'interposicaoRecurso': _interposicaoRecurso,
      'exigenciaGarantiaLicitantes': _exigenciaGarantiaLicitantes,
      'contratacaoConduzida': _contratacaoConduzida,
      'itens': _itens,
    };

    // Campos de BID (somente quando recursoBID == 1)
    if (_recursoBID == 1) {
      _setIfNonNull(map, 'aberturaPreQualificacaoBID', _aberturaPreQualificacaoBID);
      _setIfNonNull(map, 'editalPreQualificacaoBID', _editalPreQualificacaoBID);
      _setIfNonNull(
          map, 'julgamentoPreQualificacaoBID', _julgamentoPreQualificacaoBID);
      _setIfNonNull(map, 'edital2FaseBID', _edital2FaseBID);
      _setIfNonNull(map, 'julgamentoPropostasBID', _julgamentoPropostasBID);
      _setIfNonNull(map, 'julgamentoNegociacaoBID', _julgamentoNegociacaoBID);
    }

    _setIfNonNull(map, 'viabilidadeContratacao', _viabilidadeContratacao);
    _setIfNonNull(map, 'audienciaPublica', _audienciaPublica);
    _setIfNonNull(map, 'exigenciaAmostra', _exigenciaAmostra);
    _setIfNonNull(map, 'exigenciaVisitaTecnica', _exigenciaVisitaTecnica);
    _setIfNonNull(map, 'exigenciaIndicesEconomicos', _exigenciaIndicesEconomicos);

    final percentual =
        double.tryParse(_percentualValorCtrl.text.trim().replaceAll(',', '.'));
    if (percentual != null && _exigenciaGarantiaLicitantes == 1) {
      map['percentualValor'] = percentual;
    }

    if (_quitacaoFederal != null) map['quitacaoTributosFederais'] = _quitacaoFederal;
    if (_quitacaoEstadual != null) map['quitacaoTributosEstaduais'] = _quitacaoEstadual;
    if (_quitacaoMunicipal != null) map['quitacaoTributosMunicipais'] = _quitacaoMunicipal;
    if (_exigenciaCurriculo != null) map['exigenciaCurriculo'] = _exigenciaCurriculo;
    if (_exigenciaVistoCREA != null) map['exigenciaVistoCREA'] = _exigenciaVistoCREA;
    if (_declaracaoRecursos != null) {
      map['declaracaoRecursosContratacao'] = _declaracaoRecursos;
    }

    if (_fontesRecurso.isNotEmpty) {
      map['fonteRecursosContratacao'] = _fontesRecurso.toList()..sort();
    }

    if (_contratacaoConduzida && _cpfsCondutores.isNotEmpty) {
      map['cpfsCondutores'] =
          _cpfsCondutores.map((c) => {'cpfCondutor': c}).toList();
    }

    if (_indicesEconomicos.isNotEmpty) {
      map['indicesEconomicos'] = _indicesEconomicos;
    }

    return map;
  }

  static void _setIfNonNull(Map<String, dynamic> map, String key, dynamic val) {
    if (val != null) map[key] = val;
  }

  // ── Salvar rascunho ───────────────────────────────────────────────────

  Future<void> _saveDraft() async {
    if (_editalId == null) {
      _showError('Selecione o Edital vinculado.');
      return;
    }
    final formError = _validateForm();
    if (formError != null) {
      _showError(formError);
      return;
    }
    if (_itens.isEmpty) {
      _showError('Adicione pelo menos um item.');
      return;
    }

    setState(() => _saving = true);
    try {
      final doc = _buildJson();
      final jsonStr = jsonEncode(doc);
      final dao = ref.read(licitacoesDaoProvider);
      final sessionUser = ref.read(localSessionProvider);
      final municipio = sessionUser?.municipio ?? '';
      final entidade = sessionUser?.entidade ?? '';

      if (_loadedId == null) {
        final id = await dao.insertLicitacao(
          LicitacoesCompanion(
            editalId: Value(_editalId!),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoEdital: Value(_codigoEditalCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            documentoJson: Value(jsonStr),
            updatedAt: Value(DateTime.now()),
          ),
        );
        _loadedId = id;
      } else {
        await dao.updateLicitacao(
          LicitacoesCompanion(
            id: Value(_loadedId!),
            editalId: Value(_editalId!),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoEdital: Value(_codigoEditalCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            documentoJson: Value(jsonStr),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      if (mounted) {
        displayInfoBar(context,
            builder: (ctx, close) => const InfoBar(
                  title: Text('Rascunho salvo com sucesso.'),
                  severity: InfoBarSeverity.success,
                ));
      }
    } catch (e) {
      _showError('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Enviar para o AUDESP ──────────────────────────────────────────────

  Future<void> _enviar() async {
    if (_editalId == null) {
      _showError('Selecione o Edital vinculado.');
      return;
    }
    final formError = _validateForm();
    if (formError != null) {
      _showError(formError);
      return;
    }
    if (_itens.isEmpty) {
      _showError('Adicione pelo menos um item.');
      return;
    }

    await _saveDraft();
    if (!mounted || _loadedId == null) return;

    final user = ref.read(localSessionProvider);

    await showAudespAuthDialog(
      context,
      ref,
      onConfirm: (token) async {
        final doc = _buildJson();
        final jsonStr = jsonEncode(doc);
        final service = ref.read(licitacaoServiceProvider);

        final msg = await service.enviarLicitacao(
          licitacaoId: _loadedId!,
          documentoJson: jsonStr,
          userId: user?.id,
        );

        setState(() => _isSent = true);
        if (mounted) {
          displayInfoBar(context,
              builder: (ctx, close) => InfoBar(
                    title: Text(msg),
                    severity: InfoBarSeverity.success,
                  ));
          context.go('/licitacao');
        }
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    displayInfoBar(context,
        builder: (ctx, close) => InfoBar(
              title: Text(msg),
              severity: InfoBarSeverity.error,
            ));
  }

  String? _validateForm() {
    if (_codigoEditalCtrl.text.trim().isEmpty) return 'Código do Edital obrigatório';
    if (_recursoBID == null) return 'Recurso BID obrigatório';
    if (_tipoNatureza == null) return 'Tipo de Natureza obrigatório';
    if (_interposicaoRecurso == null) return 'Interposição de Recurso obrigatória';
    if (_exigenciaGarantiaLicitantes == null) return 'Exigência de Garantia obrigatória';
    if (_exigenciaGarantiaLicitantes == 1) {
      final pct = _percentualValorCtrl.text.trim();
      if (pct.isNotEmpty) {
        final d = double.tryParse(pct.replaceAll(',', '.'));
        if (d == null || d < 0 || d > 100) return 'Percentual deve ser entre 0 e 100';
      }
    }
    return null;
  }

  // ── Índices econômicos ────────────────────────────────────────────────

  void _addIndice() {
    _showIndiceDialog(null);
  }

  Future<void> _showIndiceDialog(int? editIndex) async {
    final initial = editIndex != null ? _indicesEconomicos[editIndex] : null;
    int? tipoIndice = initial?['tipoIndice'] as int?;
    final nomeCtrl = TextEditingController(
        text: initial?['nomeIndice'] as String? ?? '');
    final valorCtrl = TextEditingController(
        text: initial?['valorIndice']?.toString() ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => ContentDialog(
          constraints: const BoxConstraints(maxWidth: 440),
          title:
              Text(editIndex == null ? 'Adicionar Índice' : 'Editar Índice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoLabel(
                label: 'Tipo *',
                child: ComboBox<int>(
                  value: tipoIndice,
                  isExpanded: true,
                  placeholder: const Text('Selecione'),
                  items: kTipoIndice.entries
                      .map((e) =>
                          ComboBoxItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setS(() => tipoIndice = v),
                ),
              ),
              const SizedBox(height: 12),
              if (tipoIndice == 8)
                InfoLabel(
                  label: 'Nome do Índice (3–50 caracteres)',
                  child: TextBox(
                    controller: nomeCtrl,
                    maxLength: 50,
                  ),
                ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Valor *',
                child: TextBox(
                  controller: valorCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Button(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (confirmed == true && tipoIndice != null) {
      final valor =
          double.tryParse(valorCtrl.text.trim().replaceAll(',', '.'));
      if (valor == null) return;
      final entry = <String, dynamic>{
        'tipoIndice': tipoIndice,
        'valorIndice': valor,
      };
      if (tipoIndice == 8 && nomeCtrl.text.trim().length >= 3) {
        entry['nomeIndice'] = nomeCtrl.text.trim();
      }
      setState(() {
        if (editIndex == null) {
          _indicesEconomicos.add(entry);
        } else {
          _indicesEconomicos[editIndex] = entry;
        }
      });
    }

    nomeCtrl.dispose();
    valorCtrl.dispose();
  }

  // ── CPFs condutores ────────────────────────────────────────────────────

  void _addCpf() {
    final cpf = _cpfCondutorCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) {
      _showError('CPF deve conter 11 dígitos.');
      return;
    }
    if (_cpfsCondutores.contains(cpf)) {
      _showError('CPF já adicionado.');
      return;
    }
    setState(() {
      _cpfsCondutores.add(cpf);
      _cpfCondutorCtrl.clear();
    });
  }

  // ──────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ScaffoldPage(
          content: Center(child: ProgressRing()));
    }

    final isNew = widget.licitacaoId == null;
    final readonly = _isSent;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.go('/licitacao'),
        ),
        title: Text(isNew ? 'Nova Licitação' : 'Editar Licitação'),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isSent) ...[
              if (_saving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: ProgressRing(strokeWidth: 2),
                )
              else ...[
                Button(
                  onPressed: _saveDraft,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_outlined, size: 16),
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
                      Icon(Icons.send, size: 16),
                      SizedBox(width: 6),
                      Text('Enviar à AUDESP'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
            if (_isSent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.lighter,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14),
                    SizedBox(width: 4),
                    Text('Enviada'),
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
            _buildEditalSection(readonly),
            const SizedBox(height: 16),
            _buildDescritorSection(readonly),
            const SizedBox(height: 16),
            _buildBidSection(readonly),
            const SizedBox(height: 16),
            _buildDadosGeraisSection(readonly),
            const SizedBox(height: 16),
            _buildGarantiaSection(readonly),
            const SizedBox(height: 16),
            _buildQuitacaoSection(readonly),
            const SizedBox(height: 16),
            _buildFontesRecursoSection(readonly),
            const SizedBox(height: 16),
            _buildContratacaoConduzidaSection(readonly),
            const SizedBox(height: 16),
            _buildIndicesEconomicosSection(readonly),
            const SizedBox(height: 16),
            _buildItensSection(readonly),
          ],
        ),
      ),
    );
  }

  // ── Seções ─────────────────────────────────────────────────────────────

  Widget _buildEditalSection(bool readonly) {
    return _SectionCard(
      title: 'Edital Vinculado',
      children: [
        InfoLabel(
          label: 'Edital *',
          child: ComboBox<int>(
            value: _editalId,
            isExpanded: true,
            placeholder: const Text('Selecione o edital'),
            items: _editais
                .map((e) => ComboBoxItem(
                      value: e.id,
                      child: Text(
                        '${e.codigoEdital}  (${e.municipio} / ${e.entidade})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: readonly
                ? null
                : (v) {
                    setState(() {
                      _editalId = v;
                      _fillEditalDescriptor();
                    });
                  },
          ),
        ),
      ],
    );
  }

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
          children: [
            Expanded(
              flex: 2,
              child: InfoLabel(
                label: 'Código do Edital *',
                child: TextBox(
                  controller: _codigoEditalCtrl,
                  enabled: !readonly,
                  placeholder: 'Até 25 caracteres',
                  maxLength: 25,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ToggleSwitch(
                checked: _retificacao,
                onChanged: readonly ? null : (v) => setState(() => _retificacao = v),
                content: const Text('Retificação'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBidSection(bool readonly) {
    return _SectionCard(
      title: 'Recursos BID',
      children: [
        _ComboField(
          label: 'Recurso BID *',
          value: _recursoBID,
          items: kRecursoBID,
          onChanged: readonly ? null : (v) => setState(() => _recursoBID = v),
        ),
        if (_recursoBID == 1) ...[
          const SizedBox(height: 12),
          const Text('Fases BID (preencha conforme aplicável):',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _ComboField(
                label: 'Abertura Pré-Qualificação',
                value: _aberturaPreQualificacaoBID,
                items: kTriState,
                onChanged: readonly
                    ? null
                    : (v) => setState(() => _aberturaPreQualificacaoBID = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComboField(
                label: 'Edital Pré-Qualificação',
                value: _editalPreQualificacaoBID,
                items: kTriState,
                onChanged: readonly
                    ? null
                    : (v) => setState(() => _editalPreQualificacaoBID = v),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _ComboField(
                label: 'Julgamento Pré-Qualificação',
                value: _julgamentoPreQualificacaoBID,
                items: kTriState,
                onChanged: readonly
                    ? null
                    : (v) => setState(() => _julgamentoPreQualificacaoBID = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComboField(
                label: 'Edital 2ª Fase',
                value: _edital2FaseBID,
                items: kTriState,
                onChanged: readonly
                    ? null
                    : (v) => setState(() => _edital2FaseBID = v),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _ComboField(
                label: 'Julgamento de Propostas',
                value: _julgamentoPropostasBID,
                items: kTriState,
                onChanged: readonly
                    ? null
                    : (v) => setState(() => _julgamentoPropostasBID = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComboField(
                label: 'Julgamento/Negociação',
                value: _julgamentoNegociacaoBID,
                items: kTriState,
                onChanged: readonly
                    ? null
                    : (v) => setState(() => _julgamentoNegociacaoBID = v),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildDadosGeraisSection(bool readonly) {
    return _SectionCard(
      title: 'Dados Gerais',
      children: [
        Row(children: [
          Expanded(
            child: _ComboField(
              label: 'Tipo de Natureza *',
              value: _tipoNatureza,
              items: kTipoNatureza,
              onChanged: readonly ? null : (v) => setState(() => _tipoNatureza = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ComboField(
              label: 'Viabilidade de Contratação',
              value: _viabilidadeContratacao,
              items: kTriState,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _viabilidadeContratacao = v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _ComboField(
              label: 'Interposição de Recurso *',
              value: _interposicaoRecurso,
              items: kTriState,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _interposicaoRecurso = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ComboField(
              label: 'Audiência Pública',
              value: _audienciaPublica,
              items: kTriState,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _audienciaPublica = v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _ComboField(
              label: 'Exigência de Amostra',
              value: _exigenciaAmostra,
              items: kTriState,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaAmostra = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ComboField(
              label: 'Exigência de Visita Técnica',
              value: _exigenciaVisitaTecnica,
              items: kTriState,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaVisitaTecnica = v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Checkbox(
              checked: _exigenciaCurriculo ?? false,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaCurriculo = v),
              content: const Text('Exige Currículo'),
            ),
          ),
          Expanded(
            child: Checkbox(
              checked: _exigenciaVistoCREA ?? false,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaVistoCREA = v),
              content: const Text('Exige Visto CREA'),
            ),
          ),
          Expanded(
            child: Checkbox(
              checked: _declaracaoRecursos ?? false,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _declaracaoRecursos = v),
              content: const Text('Declaração de Recursos'),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildGarantiaSection(bool readonly) {
    return _SectionCard(
      title: 'Garantia de Licitantes',
      children: [
        Row(children: [
          Expanded(
            child: _ComboField(
              label: 'Exigência de Garantia *',
              value: _exigenciaGarantiaLicitantes,
              items: kTriState,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaGarantiaLicitantes = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InfoLabel(
              label: 'Percentual (%)',
              child: TextBox(
                controller: _percentualValorCtrl,
                enabled: !readonly && _exigenciaGarantiaLicitantes == 1,
                placeholder: '0 a 100',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildQuitacaoSection(bool readonly) {
    return _SectionCard(
      title: 'Quitação de Tributos',
      children: [
        Row(children: [
          Expanded(
            child: Checkbox(
              checked: _quitacaoFederal ?? false,
              onChanged:
                  readonly ? null : (v) => setState(() => _quitacaoFederal = v),
              content: const Text('Tributos Federais'),
            ),
          ),
          Expanded(
            child: Checkbox(
              checked: _quitacaoEstadual ?? false,
              onChanged:
                  readonly ? null : (v) => setState(() => _quitacaoEstadual = v),
              content: const Text('Tributos Estaduais'),
            ),
          ),
          Expanded(
            child: Checkbox(
              checked: _quitacaoMunicipal ?? false,
              onChanged:
                  readonly ? null : (v) => setState(() => _quitacaoMunicipal = v),
              content: const Text('Tributos Municipais'),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildFontesRecursoSection(bool readonly) {
    return _SectionCard(
      title: 'Fontes de Recurso',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: kFonteRecurso.entries.map((e) {
            final selected = _fontesRecurso.contains(e.key);
            return Checkbox(
              checked: selected,
              onChanged: readonly
                  ? null
                  : (v) => setState(() {
                        if (v == true) {
                          _fontesRecurso.add(e.key);
                        } else {
                          _fontesRecurso.remove(e.key);
                        }
                      }),
              content: Text(e.value, style: const TextStyle(fontSize: 11)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContratacaoConduzidaSection(bool readonly) {
    return _SectionCard(
      title: 'Contratação Conduzida',
      children: [
        ToggleSwitch(
          checked: _contratacaoConduzida,
          onChanged:
              readonly ? null : (v) => setState(() => _contratacaoConduzida = v),
          content: const Text('Contratação Conduzida por Órgão Externo *'),
        ),
        if (_contratacaoConduzida) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InfoLabel(
                  label: 'CPF do Condutor (11 dígitos)',
                  child: TextBox(
                    controller: _cpfCondutorCtrl,
                    enabled: !readonly,
                    placeholder: '00000000000',
                    maxLength: 11,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!readonly)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: IconButton(
                    icon: const Icon(FluentIcons.add),
                    onPressed: _addCpf,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _cpfsCondutores
                .map((cpf) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context)
                            .resources
                            .controlFillColorDefault,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cpf),
                          if (!readonly) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _cpfsCondutores.remove(cpf)),
                              child: const Icon(FluentIcons.cancel,
                                  size: 10),
                            ),
                          ],
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildIndicesEconomicosSection(bool readonly) {
    return _SectionCard(
      title: 'Índices Econômicos',
      children: [
        _ComboField(
          label: 'Exigência de Índices Econômicos',
          value: _exigenciaIndicesEconomicos,
          items: kTriState,
          onChanged: readonly
              ? null
              : (v) => setState(() => _exigenciaIndicesEconomicos = v),
        ),
        if (_exigenciaIndicesEconomicos == 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Índices (${_indicesEconomicos.length})',
                style: FluentTheme.of(context).typography.bodyStrong,
              ),
              if (!readonly)
                Button(
                  onPressed: _addIndice,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.add, size: 12),
                      SizedBox(width: 6),
                      Text('Adicionar'),
                    ],
                  ),
                ),
            ],
          ),
          ..._indicesEconomicos.asMap().entries.map((entry) {
            final i = entry.key;
            final idx = entry.value;
            return Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    FluentTheme.of(context).resources.controlFillColorDefault,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kTipoIndice[idx['tipoIndice']] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        Text(
                          '${idx['nomeIndice'] != null ? '${idx['nomeIndice']}  ' : ''}Valor: ${idx['valorIndice']}',
                          style:
                              FluentTheme.of(context).typography.caption,
                        ),
                      ],
                    ),
                  ),
                  if (!readonly) ...[
                    IconButton(
                      icon: const Icon(FluentIcons.edit, size: 14),
                      onPressed: () => _showIndiceDialog(i),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.delete, size: 14),
                      onPressed: () =>
                          setState(() => _indicesEconomicos.removeAt(i)),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildItensSection(bool readonly) {
    return _SectionCard(
      title: 'Itens de Licitação *',
      children: [
        if (!readonly)
          Align(
            alignment: Alignment.centerRight,
            child: Button(
              onPressed: () async {
                final result = await showItemLicitacaoDialog(context);
                if (result != null) setState(() => _itens.add(result));
              },
              child: const Text('Adicionar Item'),
            ),
          ),
        const SizedBox(height: 8),
        if (_itens.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).resources.controlFillColorDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Nenhum item adicionado.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...List.generate(_itens.length, (i) {
            final item = _itens[i];
            final numItem = item['numeroItem'];
            final situacao = item['situacaoCompraItemId'] != null
                ? kSituacaoCompraItem[
                        (item['situacaoCompraItemId'] as num).toInt()] ??
                    ''
                : '';
            final numLicitantes =
                (item['licitantes'] as List<dynamic>? ?? []).length;
            return Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    FluentTheme.of(context).resources.controlFillColorDefault,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FluentTheme.of(context).accentColor.lighter,
                    ),
                    alignment: Alignment.center,
                    child: Text('$numItem',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Item $numItem',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('$situacao  |  $numLicitantes licitante(s)',
                            style:
                                FluentTheme.of(context).typography.caption),
                      ],
                    ),
                  ),
                  if (!readonly) ...[
                    IconButton(
                      icon: const Icon(FluentIcons.edit, size: 14),
                      onPressed: () async {
                        final result = await showItemLicitacaoDialog(
                          context,
                          initial: item,
                        );
                        if (result != null) {
                          setState(() => _itens[i] = result);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.delete, size: 14),
                      onPressed: () =>
                          setState(() => _itens.removeAt(i)),
                    ),
                  ],
                ],
              ),
            );
          }),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: FluentTheme.of(context).typography.subtitle),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ComboField extends StatelessWidget {
  final String label;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int?>? onChanged;

  const _ComboField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InfoLabel(
      label: label,
      child: ComboBox<int>(
        value: value,
        isExpanded: true,
        placeholder: const Text('Selecione'),
        items: items.entries
            .map((e) => ComboBoxItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
