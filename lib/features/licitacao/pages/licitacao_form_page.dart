import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../shared/widgets/section_card.dart';
import '../csv/csv.dart';
import '../domain/licitacao_domain.dart';
import '../services/licitacao_service.dart';
import '../widgets/item_licitacao_dialog.dart';
import '../widgets/portal_import_dialog.dart';
import '../widgets/ajuste_me_epp_dialog.dart';

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
  final _formKey = GlobalKey<FormState>();

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
    final municipio = int.tryParse(ref.read(codigoMunicipioProvider)) ?? 0;
    final entidade = int.tryParse(ref.read(codigoEntidadeProvider)) ?? 0;

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

  bool _validateDraft() {
    if (_editalId == null) {
      _showError('Selecione o Edital vinculado para salvar o rascunho.');
      return false;
    }
    if (_codigoEditalCtrl.text.trim().isEmpty) {
      _showError('Informe o Código do Edital para salvar o rascunho.');
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
      final dao = ref.read(licitacoesDaoProvider);
      final municipio = ref.read(codigoMunicipioProvider);
      final entidade = ref.read(codigoEntidadeProvider);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rascunho salvo com sucesso.')),
        );
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
    if (!_formKey.currentState!.validate()) return;
    if (_fontesRecurso.isEmpty) {
      _showError('Selecione ao menos uma fonte de recurso.');
      return;
    }
    if (_contratacaoConduzida && _cpfsCondutores.isEmpty) {
      _showError('Informe ao menos um CPF condutor quando a contratação for conduzida.');
      return;
    }
    if (_exigenciaIndicesEconomicos == 1 && _indicesEconomicos.isEmpty) {
      _showError('Adicione ao menos um índice econômico quando exigência for marcada como "Sim".');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          context.go('/licitacao');
        }
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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
        builder: (ctx, setS) => AlertDialog(
          title:
              Text(editIndex == null ? 'Adicionar Índice' : 'Editar Índice'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: tipoIndice,
                  decoration: const InputDecoration(labelText: 'Tipo *'),
                  items: kTipoIndice.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setS(() => tipoIndice = v),
                ),
                const SizedBox(height: 12),
                if (tipoIndice == 8)
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nome do Índice (3–50 caracteres)'),
                    maxLength: 50,
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: valorCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Valor *'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
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

  // ── Importação de CSV ─────────────────────────────────────────────────

  Future<void> _openPortalImportDialog() async {
    if (_itens.isNotEmpty) {
      final limpar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Substituir itens?'),
          content: const Text(
            'Já existem itens no formulário. Deseja substituí-los pelos itens importados?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Substituir'),
            ),
          ],
        ),
      );
      if (limpar != true) return;
    }

    if (!mounted) return;
    final csvItens = await showPortalImportDialog(context);
    if (csvItens == null || !mounted) return;

    setState(() => _itens = csvItens.map(_csvItemToMap).toList());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Itens importados com sucesso! Verifique os enquadramentos de '
          'ME/EPP dos licitantes, pois os portais não os diferenciam.',
        ),
        duration: Duration(seconds: 8),
      ),
    );
  }

  static Map<String, dynamic> _csvItemToMap(LicitacaoItemCsvModel item) {
    final map = <String, dynamic>{
      'numeroItem': item.numeroItem,
      'situacaoCompraItemId': item.situacaoCompraItemId,
      'licitantes': item.licitantes.map(_csvLicitanteToMap).toList(),
    };
    if (item.tipoOrcamento != null) map['tipoOrcamento'] = item.tipoOrcamento;
    if (item.valorEstimado != null) map['valor'] = item.valorEstimado;
    if (item.dataOrcamento != null) map['dataOrcamento'] = item.dataOrcamento;
    if (item.dataSituacao != null) map['dataSituacaoItem'] = item.dataSituacao;
    if (item.tipoValor != null) map['tipoValor'] = item.tipoValor;
    if (item.tipoProposta != null) map['tipoProposta'] = item.tipoProposta;
    return map;
  }

  static Map<String, dynamic> _csvLicitanteToMap(LicitanteCsvModel l) {
    final map = <String, dynamic>{
      'tipoPessoaId': l.tipoPessoaId,
      'niPessoa': l.niPessoa,
      'declaracaoMEouEPP': l.declaracaoMEouEPP,
      'resultadoHabilitacao': l.resultadoHabilitacao,
    };
    if (l.nomeRazaoSocial.isNotEmpty) map['nomeRazaoSocial'] = l.nomeRazaoSocial;
    if (l.valorProposta != 0) map['valor'] = l.valorProposta;
    return map;
  }

  // ── CPFs condutores ────────────────────────────────────────────────────

  // ── Ajuste ME/EPP em lote ─────────────────────────────────────────────

  bool get _temLicitante => _itens.any(
        (item) =>
            (item['licitantes'] as List<dynamic>? ?? []).isNotEmpty,
      );

  Future<void> _abrirAjusteMeEpp() async {
    // Extrai licitantes únicos (por niPessoa), preservando status atual.
    final unicos = <String, Map<String, dynamic>>{};
    for (final item in _itens) {
      for (final l
          in (item['licitantes'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()) {
        final ni = l['niPessoa'] as String? ?? '';
        if (ni.isEmpty) continue;
        unicos.putIfAbsent(ni, () => Map<String, dynamic>.from(l));
      }
    }

    if (unicos.isEmpty || !mounted) return;

    final resultado = await showAjusteMeEppDialog(context, unicos);
    if (resultado == null || !mounted) return;

    // Aplica o status atualizado em cascata em todos os itens/licitantes.
    setState(() {
      _itens = _itens.map((item) {
        final licitantes =
            (item['licitantes'] as List<dynamic>? ?? [])
                .whereType<Map<String, dynamic>>()
                .map((l) {
          final ni = l['niPessoa'] as String? ?? '';
          final novoStatus = resultado[ni];
          if (novoStatus == null) return l;
          return {...l, 'declaracaoMEouEPP': novoStatus};
        }).toList();
        return {...item, 'licitantes': licitantes};
      }).toList();
    });
  }

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isNew = widget.licitacaoId == null;
    final readonly = _isSent;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/licitacao')),
        title: Text(isNew ? 'Nova Licitação' : 'Editar Licitação'),
        actions: [
          if (!_isSent) ...[
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
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
              child: Chip(
                label: const Text('Enviada'),
                avatar: const Icon(Icons.check_circle, size: 16),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
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
      ),
    );
  }

  // ── Seções ─────────────────────────────────────────────────────────────

  Widget _buildEditalSection(bool readonly) {
    return SectionCard(
      title: 'Edital Vinculado',
      children: [
        DropdownButtonFormField<int>(
          initialValue: _editalId,
          decoration: const InputDecoration(labelText: 'Edital *'),
          isExpanded: true,
          items: _editais
              .map((e) => DropdownMenuItem(
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
          validator: (v) => v == null ? 'Selecione o edital vinculado' : null,
        ),
      ],
    );
  }

  Widget _buildDescritorSection(bool readonly) {
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
              child: TextFormField(
                controller: _codigoEditalCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Código do Edital',
                  helperText: 'Preenchido automaticamente pelo Edital vinculado',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SwitchListTile(
                value: _retificacao,
                onChanged: readonly ? null : (v) => setState(() => _retificacao = v),
                title: const Text('Retificação'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBidSection(bool readonly) {
    return SectionCard(
      title: 'Recursos BID',
      children: [
        _DropdownField(
          label: 'Recurso BID *',
          value: _recursoBID,
          items: kRecursoBID,
          onChanged: readonly ? null : (v) => setState(() => _recursoBID = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        if (_recursoBID == 1) ...[
          const SizedBox(height: 12),
          const Text('Fases BID (preencha conforme aplicável):',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _DropdownField(
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
              child: _DropdownField(
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
              child: _DropdownField(
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
              child: _DropdownField(
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
              child: _DropdownField(
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
              child: _DropdownField(
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
    return SectionCard(
      title: 'Dados Gerais',
      children: [
        Row(children: [
          Expanded(
            child: _DropdownField(
              label: 'Tipo de Natureza *',
              value: _tipoNatureza,
              items: kTipoNatureza,
              onChanged: readonly ? null : (v) => setState(() => _tipoNatureza = v),
              validator: (v) => v == null ? 'Obrigatório' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DropdownField(
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
            child: _DropdownField(
              label: 'Interposição de Recurso *',
              value: _interposicaoRecurso,
              items: kTriState,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _interposicaoRecurso = v),
              validator: (v) => v == null ? 'Obrigatório' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DropdownField(
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
            child: _DropdownField(
              label: 'Exigência de Amostra',
              value: _exigenciaAmostra,
              items: kExigenciaAmostra,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaAmostra = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DropdownField(
              label: 'Exigência de Visita Técnica',
              value: _exigenciaVisitaTecnica,
              items: kExigenciaVisitaTecnica,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaVisitaTecnica = v),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: CheckboxListTile(
              value: _exigenciaCurriculo ?? false,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaCurriculo = v),
              title: const Text('Exige Currículo'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: CheckboxListTile(
              value: _exigenciaVistoCREA ?? false,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaVistoCREA = v),
              title: const Text('Exige Visto CREA'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: CheckboxListTile(
              value: _declaracaoRecursos ?? false,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _declaracaoRecursos = v),
              title: const Text('Declaração de Recursos'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildGarantiaSection(bool readonly) {
    return SectionCard(
      title: 'Garantia de Licitantes',
      children: [
        Row(children: [
          Expanded(
            child: _DropdownField(
              label: 'Exigência de Garantia *',
              value: _exigenciaGarantiaLicitantes,
              items: kTriState,
              onChanged: readonly
                  ? null
                  : (v) => setState(() => _exigenciaGarantiaLicitantes = v),
              validator: (v) => v == null ? 'Obrigatório' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _percentualValorCtrl,
              enabled: !readonly && _exigenciaGarantiaLicitantes == 1,
              decoration: const InputDecoration(
                labelText: 'Percentual (%)',
                hintText: '0 a 100',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              validator: (v) {
                if (_exigenciaGarantiaLicitantes != 1) return null;
                if (v == null || v.trim().isEmpty) return null;
                final d = double.tryParse(v.trim().replaceAll(',', '.'));
                if (d == null || d < 0 || d > 100) return 'Valor entre 0 e 100';
                return null;
              },
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildQuitacaoSection(bool readonly) {
    return SectionCard(
      title: 'Quitação de Tributos',
      children: [
        Row(children: [
          Expanded(
            child: CheckboxListTile(
              value: _quitacaoFederal ?? false,
              onChanged:
                  readonly ? null : (v) => setState(() => _quitacaoFederal = v),
              title: const Text('Tributos Federais'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: CheckboxListTile(
              value: _quitacaoEstadual ?? false,
              onChanged:
                  readonly ? null : (v) => setState(() => _quitacaoEstadual = v),
              title: const Text('Tributos Estaduais'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: CheckboxListTile(
              value: _quitacaoMunicipal ?? false,
              onChanged:
                  readonly ? null : (v) => setState(() => _quitacaoMunicipal = v),
              title: const Text('Tributos Municipais'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildFontesRecursoSection(bool readonly) {
    return SectionCard(
      title: 'Fontes de Recurso',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: kFonteRecurso.entries.map((e) {
            final selected = _fontesRecurso.contains(e.key);
            return FilterChip(
              label: Text(e.value, style: const TextStyle(fontSize: 11)),
              selected: selected,
              onSelected: readonly
                  ? null
                  : (v) => setState(() {
                        if (v) {
                          _fontesRecurso.add(e.key);
                        } else {
                          _fontesRecurso.remove(e.key);
                        }
                      }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContratacaoConduzidaSection(bool readonly) {
    return SectionCard(
      title: 'Contratação Conduzida',
      children: [
        SwitchListTile(
          value: _contratacaoConduzida,
          onChanged:
              readonly ? null : (v) => setState(() => _contratacaoConduzida = v),
          title: const Text('Contratação Conduzida por Órgão Externo *'),
          contentPadding: EdgeInsets.zero,
        ),
        if (_contratacaoConduzida) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cpfCondutorCtrl,
                  enabled: !readonly,
                  decoration: const InputDecoration(
                    labelText: 'CPF do Condutor (11 dígitos)',
                    hintText: '00000000000',
                    counterText: '',
                  ),
                  maxLength: 11,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              if (!readonly)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addCpf,
                  tooltip: 'Adicionar CPF',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _cpfsCondutores
                .map((cpf) => Chip(
                      label: Text(cpf),
                      onDeleted:
                          readonly ? null : () => setState(() => _cpfsCondutores.remove(cpf)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildIndicesEconomicosSection(bool readonly) {
    return SectionCard(
      title: 'Índices Econômicos',
      children: [
        _DropdownField(
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
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (!readonly)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar'),
                  onPressed: _addIndice,
                ),
            ],
          ),
          ..._indicesEconomicos.asMap().entries.map((entry) {
            final i = entry.key;
            final idx = entry.value;
            return Card(
              margin: const EdgeInsets.only(top: 4),
              child: ListTile(
                dense: true,
                title: Text(kTipoIndice[idx['tipoIndice']] ?? ''),
                subtitle: Text(
                  '${idx['nomeIndice'] != null ? '${idx['nomeIndice']}  ' : ''}Valor: ${idx['valorIndice']}',
                ),
                trailing: readonly
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            onPressed: () => _showIndiceDialog(i),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            onPressed: () =>
                                setState(() => _indicesEconomicos.removeAt(i)),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildItensSection(bool readonly) {
    return SectionCard(
      title: 'Itens de Licitação *',
      children: [
        if (!readonly)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _openPortalImportDialog,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Importar do Portal'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: (_itens.isNotEmpty && _temLicitante)
                    ? _abrirAjusteMeEpp
                    : null,
                icon: const Icon(Icons.tune_outlined, size: 18),
                label: const Text('Ajustar ME/EPP'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () async {
                  final result = await showItemLicitacaoDialog(context);
                  if (result != null) setState(() => _itens.add(result));
                },
                child: const Text('Adicionar Item'),
              ),
            ],
          ),
        const SizedBox(height: 8),
        if (_itens.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            return Card(
              margin: const EdgeInsets.only(top: 4),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  child: Text('$numItem'),
                ),
                title: Text('Item $numItem'),
                subtitle: Text(
                  '$situacao  |  $numLicitantes licitante(s)',
                ),
                trailing: readonly
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Editar',
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
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remover',
                            onPressed: () =>
                                setState(() => _itens.removeAt(i)),
                          ),
                        ],
                      ),
              ),
            );
          }),
      ],
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String label;
  final int? value;
  final Map<int, String> items;
  final ValueChanged<int?>? onChanged;
  final FormFieldValidator<int>? validator;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: items.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
