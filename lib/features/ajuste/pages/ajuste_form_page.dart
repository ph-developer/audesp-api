import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/text_validation.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../features/logs/services/consulta_service.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_currency_field.dart';
import '../../../shared/widgets/audesp_cpf_cnpj_field.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_ai_import_dialog.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_pncp_field.dart';
import '../../../shared/widgets/audesp_segmented_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_warning_message.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../../licitacao/domain/licitacao_referencia.dart';
import '../../licitacao/domain/licitacao_resultado.dart';
import '../../processo/domain/processo.dart';
import '../../processo/domain/processo_rules.dart';
import '../../processo/processo_providers.dart';
import '../domain/ajuste_domain.dart';
import '../domain/ajuste_rules.dart';
import '../ajuste_providers.dart';
import '../services/ajuste_service.dart';
import '../widgets/gemini_ajuste_import_dialog.dart';

/// Formulário de criação/edição de Ajuste (Fase 7 – Módulo 4).
///
/// [ajusteId] null → criar novo; não-null → editar existente.
class AjusteFormPage extends ConsumerStatefulWidget {
  final int? ajusteId;
  final int? preselectedEditalId;

  const AjusteFormPage({super.key, this.ajusteId, this.preselectedEditalId});

  @override
  ConsumerState<AjusteFormPage> createState() => _AjusteFormPageState();
}

class _AjusteFormPageState extends ConsumerState<AjusteFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  bool _validacaoSolicitada = false;
  bool _isSent = false;
  bool _importingGemini = false;
  bool _preenchendoLicitacao = false;
  bool _updatingStatus = false;
  int? _loadedId;
  ApiLog? _lastSendLog;

  // ── Vínculo com Edital ────────────────────────────────────────────────
  int? _editalId;
  // Vínculo legado: preservado ao salvar, sem seleção de ata local.
  int? _ataIdOriginal;
  List<OpcaoEdital> _opcoesEdital = [];
  Set<int>? _itensLicitacao;

  Iterable<OpcaoEdital> get _opcoesVisiveis => _opcoesEdital.where(
    (o) => o.liberado || o.processo.edital.id == _editalId,
  );

  Iterable<Edital> get _editais =>
      _opcoesVisiveis.map((o) => o.processo.edital);

  String? get _motivoBloqueioEdital {
    if (_adesaoParticipacao || _editalId == null) return null;
    final opcao = _opcoesEdital
        .where((o) => o.processo.edital.id == _editalId)
        .firstOrNull;
    return opcao == null
        ? 'O edital vinculado não foi encontrado.'
        : opcao.motivoBloqueio ?? _motivoBloqueioAta;
  }

  String? get _motivoBloqueioAta =>
      _ataIdOriginal != null && !_adesaoParticipacao
      ? 'Ajuste vinculado a ata não pode ser enviado.'
      : null;

  Edital? get _editalSelecionado =>
      _editais.where((e) => e.id == _editalId).firstOrNull;

  bool get _podePreencherPelaLicitacao =>
      !_isSent &&
      !_adesaoParticipacao &&
      _editalId != null &&
      _motivoBloqueioEdital == null;

  bool get _exigeEditalLocal =>
      AjusteRules.exigeEditalLocal(adesaoParticipacao: _adesaoParticipacao);

  bool get _editalSemPncp => _editalSelecionado?.semPncp ?? false;

  bool get _referenciasSemPncp => !_adesaoParticipacao && _editalSemPncp;

  String get _codigoEdital => _adesaoParticipacao
      ? PcnpInputFormatter.stripMask(_codigoEditalCtrl.text)
      : _codigoEditalCtrl.text.trim();

  String get _codigoAta => _referenciasSemPncp
      ? _codigoAtaCtrl.text.trim()
      : PcnpInputFormatter.stripMask(_codigoAtaCtrl.text);

  Map<int, String> get _objetosPermitidos => {
    for (final objeto in kTipoObjetoContrato.entries)
      if (AjusteRules.objetosPorCategoria[_categoriaProcessoId]?.contains(
            objeto.key,
          ) ??
          false)
        objeto.key: objeto.value,
  };

  // ── Descritor ─────────────────────────────────────────────────────────
  final _codigoEditalCtrl = TextEditingController();
  final _codigoAtaCtrl = TextEditingController();
  final _codigoContratoCtrl = TextEditingController();
  bool _retificacao = false;
  bool _adesaoParticipacao = false;
  bool _gerenciadoraJurisdicionada = false;
  final _cnpjGerenciadoraCtrl = TextEditingController();
  final _municipioGerenciadorCtrl = TextEditingController();
  final _entidadeGerenciadoraCtrl = TextEditingController();

  // ── Dados Gerais ──────────────────────────────────────────────────────
  Set<int> _fontesRecurso = {};
  List<int> _itens = [];
  final _itemCtrl = TextEditingController();
  final _itemFocusNode = FocusNode();
  int? _tipoContratoId;
  final _numeroContratoEmpenhoCtrl = TextEditingController();
  final _anoContratoCtrl = TextEditingController();
  final _processoCtrl = TextEditingController();
  int? _categoriaProcessoId;
  bool _receita = false;
  List<String> _despesas = [];
  final _despesaCtrl = TextEditingController();
  final _despesaFocusNode = FocusNode();
  final _codigoUnidadeCtrl = TextEditingController();

  // ── Fornecedor ────────────────────────────────────────────────────────
  final _niFornecedorCtrl = TextEditingController();
  String? _tipoPessoaFornecedor;
  final _nomeRazaoSocialFornecedorCtrl = TextEditingController();
  final _niFornecedorSubCtrl = TextEditingController();
  String? _tipoPessoaFornecedorSub;
  final _nomeRazaoSocialFornecedorSubCtrl = TextEditingController();

  // ── Objeto e Valores ──────────────────────────────────────────────────
  final _objetoContratoCtrl = TextEditingController();
  final _infComplementarCtrl = TextEditingController();
  final _valorInicialCtrl = TextEditingController();
  final _numeroParcelasCtrl = TextEditingController();
  final _valorParcelaCtrl = TextEditingController();
  final _valorGlobalCtrl = TextEditingController();
  final _valorAcumuladoCtrl = TextEditingController();

  // ── Datas ─────────────────────────────────────────────────────────────
  DateTime? _dataAssinatura;
  DateTime? _dataVigenciaInicio;
  DateTime? _dataVigenciaFim;
  final _vigenciaMesesCtrl = TextEditingController();

  int? get _codigoTipoOrgao => int.tryParse(ref.read(codigoTipoOrgaoProvider));

  bool get _exigeFonteRecursos => AjusteRules.exigeFonteRecursos(
    codigoTipoOrgao: _codigoTipoOrgao,
    receita: _receita,
  );

  bool get _exigeDespesas => AjusteRules.exigeDespesas(
    codigoTipoOrgao: _codigoTipoOrgao,
    tipoContratoId: _tipoContratoId,
    receita: _receita,
  );

  bool get _exigeDataVigenciaInicio => AjusteRules.exigeDataVigenciaInicio(
    tipoContratoId: _tipoContratoId,
    vigenciaMesesInformada: _vigenciaMesesCtrl.text.trim().isNotEmpty,
  );

  bool get _exigeVigenciaMeses => AjusteRules.exigeVigenciaMeses(
    tipoContratoId: _tipoContratoId,
    dataVigenciaInicioInformada: _dataVigenciaInicio != null,
  );

  bool get _exigeDataVigenciaFim => AjusteRules.exigeDataVigenciaFim(
    dataVigenciaInicioInformada: _dataVigenciaInicio != null,
  );

  String? _validarDataVigenciaInicio(DateTime? data) {
    if (_exigeDataVigenciaInicio && data == null) {
      return 'Informe o início da vigência ou a vigência em meses.';
    }
    return null;
  }

  String? _validarDataVigenciaFim(DateTime? data) {
    if (_exigeDataVigenciaFim && data == null) {
      return 'Informe o fim da vigência quando houver início.';
    }
    if (data != null &&
        _dataVigenciaInicio != null &&
        data.isBefore(_dataVigenciaInicio!)) {
      return 'O fim da vigência não pode ser anterior ao início.';
    }
    return null;
  }

  String? _validarVigenciaMeses(String? value) {
    final texto = value?.trim() ?? '';
    if (texto.isEmpty) {
      return _exigeVigenciaMeses
          ? 'Informe a vigência em meses ou o início da vigência.'
          : null;
    }
    final meses = int.tryParse(texto);
    if (meses == null || meses < 1) {
      return 'Informe um número inteiro de meses maior ou igual a 1.';
    }
    return null;
  }

  int? _prazoVigenciaDias;

  // ── Objeto do Contrato ────────────────────────────────────────────────
  int? _tipoObjetoContrato;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _codigoEditalCtrl.dispose();
    _codigoAtaCtrl.dispose();
    _codigoContratoCtrl.dispose();
    _cnpjGerenciadoraCtrl.dispose();
    _municipioGerenciadorCtrl.dispose();
    _entidadeGerenciadoraCtrl.dispose();
    _itemCtrl.dispose();
    _itemFocusNode.dispose();
    _numeroContratoEmpenhoCtrl.dispose();
    _anoContratoCtrl.dispose();
    _processoCtrl.dispose();
    _despesaCtrl.dispose();
    _despesaFocusNode.dispose();
    _codigoUnidadeCtrl.dispose();
    _niFornecedorCtrl.dispose();
    _nomeRazaoSocialFornecedorCtrl.dispose();
    _niFornecedorSubCtrl.dispose();
    _nomeRazaoSocialFornecedorSubCtrl.dispose();
    _objetoContratoCtrl.dispose();
    _infComplementarCtrl.dispose();
    _valorInicialCtrl.dispose();
    _numeroParcelasCtrl.dispose();
    _valorParcelaCtrl.dispose();
    _valorGlobalCtrl.dispose();
    _valorAcumuladoCtrl.dispose();
    _vigenciaMesesCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.ajusteId != null) {
      await _loadExisting(widget.ajusteId!);
    } else {
      await _carregarOpcoesEdital();
      if (!mounted) return;
      await _selectPreselectedEdital(widget.preselectedEditalId);
    }
    if (!mounted) return;
    await _carregarItensLicitacao();
    if (mounted) setState(() => _loading = false);
  }

  Future<List<Processo>> _carregarOpcoesEdital() async {
    final adesao = _adesaoParticipacao;
    final processos = await ref.refresh(processosProvider.future);
    if (!mounted || adesao != _adesaoParticipacao) return processos;
    final opcoes = ProcessoRules.opcoesAjuste(
      processos,
      adesaoParticipacao: adesao,
    );
    final editalId = _editalId;
    if (editalId != null &&
        !opcoes.any((o) => o.processo.edital.id == editalId)) {
      final edital = await ref.read(editaisDaoProvider).findById(editalId);
      if (!mounted || editalId != _editalId || adesao != _adesaoParticipacao) {
        return processos;
      }
      if (edital != null) {
        final processo =
            processos.where((p) => p.edital.id == editalId).firstOrNull ??
            Processo(edital: edital, licitacoes: [], atas: [], ajustes: []);
        opcoes.add(
          OpcaoEdital(
            processo: processo,
            motivoBloqueio: ProcessoRules.motivoBloqueioAjuste(
              processo,
              adesaoParticipacao: adesao,
            ),
          ),
        );
      }
    }
    setState(() => _opcoesEdital = opcoes);
    return processos;
  }

  Future<void> _carregarItensLicitacao() async {
    final editalId = _editalId;
    final adesao = _adesaoParticipacao;
    Set<int>? numeros;
    if (editalId != null && !adesao) {
      try {
        final licitacoes = await ref
            .read(licitacoesDaoProvider)
            .watchByEdital(editalId);
        numeros = LicitacaoReferencia.numerosItens(licitacoes);
      } catch (_) {
        // Sem referência legível, o rascunho pode ser salvo, mas não enviado.
      }
    }
    if (!mounted || editalId != _editalId || adesao != _adesaoParticipacao) {
      return;
    }
    setState(() => _itensLicitacao = numeros);
  }

  void _fillEditalDescriptor() {
    if (_adesaoParticipacao) return;
    final edital = _editalSelecionado;
    if (edital != null) {
      _codigoEditalCtrl.text = edital.codigoEdital;
    }
  }

  void _alterarCategoriaProcesso(int? categoria) {
    setState(() {
      _categoriaProcessoId = categoria;
      if (AjusteRules.validarTipoObjetoContrato(
            categoriaProcessoId: categoria,
            tipoObjetoContrato: _tipoObjetoContrato,
          ) !=
          null) {
        _tipoObjetoContrato = null;
      }
    });
  }

  Future<void> _alterarAdesao(bool adesao) async {
    setState(() {
      _adesaoParticipacao = adesao;
      _itensLicitacao = null;
      if (adesao) {
        if (_editalSelecionado?.semPncp ?? false) {
          _codigoEditalCtrl.clear();
          _codigoAtaCtrl.clear();
        } else {
          _codigoEditalCtrl.text = PcnpInputFormatter.applyMask(
            _codigoEditalCtrl.text,
          );
          _codigoAtaCtrl.text = PcnpInputFormatter.applyMask(
            _codigoAtaCtrl.text,
          );
        }
      } else {
        _codigoAtaCtrl.clear();
        _fillEditalDescriptor();
      }
    });
    await _carregarOpcoesEdital();
    if (!mounted || adesao != _adesaoParticipacao) return;
    await _carregarItensLicitacao();
  }

  Future<void> _selectPreselectedEdital(int? editalId) async {
    if (editalId == null) return;
    final opcao = _opcoesEdital
        .where((o) => o.processo.edital.id == editalId)
        .firstOrNull;
    if (opcao == null) {
      final edital = await ref.read(editaisDaoProvider).findById(editalId);
      if (!mounted) return;
      _showError(
        edital == null
            ? 'O edital informado não foi encontrado.'
            : ProcessoRules.motivoBloqueioAjuste(
                    Processo(
                      edital: edital,
                      licitacoes: [],
                      atas: [],
                      ajustes: [],
                    ),
                    adesaoParticipacao: _adesaoParticipacao,
                  ) ??
                  'O edital não está disponível para criar ajuste.',
      );
      return;
    }
    if (!opcao.liberado) {
      _showError(opcao.motivoBloqueio!);
      return;
    }
    final edital = opcao.processo.edital;
    _editalId = edital.id;
    _codigoEditalCtrl.text = edital.codigoEdital;
  }

  Future<void> _loadExisting(int id) async {
    final dao = ref.read(ajustesDaoProvider);
    final ajuste = await dao.findById(id);
    if (ajuste == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _loadedId = ajuste.id;
    _isSent = ajuste.status == 'sent';
    _editalId = ajuste.editalId;
    _ataIdOriginal = ajuste.ataId;

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(ajuste.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    _adesaoParticipacao = descritor['adesaoParticipacao'] as bool? ?? false;
    await _carregarOpcoesEdital();
    if (!mounted) return;
    _codigoEditalCtrl.text =
        descritor['codigoEdital'] as String? ?? ajuste.codigoEdital;
    if (_adesaoParticipacao) {
      _codigoEditalCtrl.text = PcnpInputFormatter.applyMask(
        _codigoEditalCtrl.text,
      );
    }
    final codigoAta =
        descritor['codigoAta'] as String? ?? ajuste.codigoAta ?? '';
    _codigoAtaCtrl.text = _referenciasSemPncp
        ? codigoAta
        : PcnpInputFormatter.applyMask(codigoAta);
    final codigoContrato =
        descritor['codigoContrato'] as String? ?? ajuste.codigoContrato;
    _codigoContratoCtrl.text = _editalSemPncp
        ? codigoContrato
        : PcnpInputFormatter.applyMask(codigoContrato);
    _retificacao = descritor['retificacao'] as bool? ?? ajuste.retificacao;
    _gerenciadoraJurisdicionada =
        descritor['gerenciadoraJurisdicionada'] as bool? ?? false;
    _cnpjGerenciadoraCtrl.text = descritor['cnpjGerenciadora'] as String? ?? '';
    _municipioGerenciadorCtrl.text =
        (descritor['municipioGerenciador'] as int?)?.toString() ?? '';
    _entidadeGerenciadoraCtrl.text =
        (descritor['entidadeGerenciadora'] as int?)?.toString() ?? '';

    _fontesRecurso = ((doc['fonteRecursosContratacao'] as List<dynamic>?) ?? [])
        .map((e) => (e as num).toInt())
        .toSet();
    _itens = ((doc['itens'] as List<dynamic>?) ?? [])
        .map((e) => (e as num).toInt())
        .toList();

    _tipoContratoId = doc['tipoContratoId'] as int?;
    _numeroContratoEmpenhoCtrl.text =
        doc['numeroContratoEmpenho'] as String? ?? '';
    _anoContratoCtrl.text = (doc['anoContrato'] as num?)?.toString() ?? '';
    _processoCtrl.text = doc['processo'] as String? ?? '';
    _categoriaProcessoId = doc['categoriaProcessoId'] as int?;
    _receita = doc['receita'] as bool? ?? false;
    _despesas = ((doc['despesas'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .toList();
    _codigoUnidadeCtrl.text = doc['codigoUnidade'] as String? ?? '';

    _niFornecedorCtrl.text = doc['niFornecedor'] as String? ?? '';
    _tipoPessoaFornecedor = doc['tipoPessoaFornecedor'] as String?;
    _nomeRazaoSocialFornecedorCtrl.text =
        doc['nomeRazaoSocialFornecedor'] as String? ?? '';
    _niFornecedorSubCtrl.text =
        doc['niFornecedorSubContratado'] as String? ?? '';
    _tipoPessoaFornecedorSub =
        doc['tipoPessoaFornecedorSubContratado'] as String?;
    _nomeRazaoSocialFornecedorSubCtrl.text =
        doc['nomeRazaoSocialFornecedorSubContratado'] as String? ?? '';

    _objetoContratoCtrl.text = doc['objetoContrato'] as String? ?? '';
    _infComplementarCtrl.text = doc['informacaoComplementar'] as String? ?? '';
    _valorInicialCtrl.text = doubleToBrString(doc['valorInicial']);
    _numeroParcelasCtrl.text =
        (doc['numeroParcelas'] as num?)?.toString() ?? '';
    _valorParcelaCtrl.text = doubleToBrString(doc['valorParcela']);
    _valorGlobalCtrl.text = doubleToBrString(doc['valorGlobal']);
    _valorAcumuladoCtrl.text = doubleToBrString(doc['valorAcumulado']);

    final assinatura = doc['dataAssinatura'] as String?;
    if (assinatura != null) _dataAssinatura = DateTime.tryParse(assinatura);
    final vigInicio = doc['dataVigenciaInicio'] as String?;
    if (vigInicio != null) {
      _dataVigenciaInicio = DateTime.tryParse(vigInicio);
    }
    final vigFim = doc['dataVigenciaFim'] as String?;
    if (vigFim != null) _dataVigenciaFim = DateTime.tryParse(vigFim);
    _vigenciaMesesCtrl.text = (doc['vigenciaMeses'] as num?)?.toString() ?? '';

    _tipoObjetoContrato = doc['tipoObjetoContrato'] as int?;

    if (_isSent) {
      _lastSendLog = await ref
          .read(apiLogsDaoProvider)
          .findLatestAjusteSendLog(
            municipio: ajuste.municipio,
            entidade: ajuste.entidade,
            codigoEdital: ajuste.codigoEdital,
            codigoAta: ajuste.codigoAta,
            codigoContrato: ajuste.codigoContrato,
            retificacao: ajuste.retificacao,
          );
    }
  }

  // ── JSON builder ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final municipio = int.tryParse(ref.read(codigoMunicipioProvider)) ?? 0;
    final entidade = int.tryParse(ref.read(codigoEntidadeProvider)) ?? 0;
    final isoFmt = DateFormat('yyyy-MM-dd');

    final descritor = <String, dynamic>{
      'municipio': municipio,
      'entidade': entidade,
      'adesaoParticipacao': _adesaoParticipacao,
      'codigoEdital': _codigoEdital,
      'codigoContrato': _editalSemPncp
          ? _codigoContratoCtrl.text.trim()
          : PcnpInputFormatter.stripMask(_codigoContratoCtrl.text),
      'retificacao': _retificacao,
    };
    if (_adesaoParticipacao) {
      descritor['gerenciadoraJurisdicionada'] = _gerenciadoraJurisdicionada;
      if (!_gerenciadoraJurisdicionada &&
          _cnpjGerenciadoraCtrl.text.trim().isNotEmpty) {
        descritor['cnpjGerenciadora'] = _cnpjGerenciadoraCtrl.text.trim();
      }
      if (_gerenciadoraJurisdicionada) {
        final mun = int.tryParse(_municipioGerenciadorCtrl.text.trim());
        final ent = int.tryParse(_entidadeGerenciadoraCtrl.text.trim());
        if (mun != null) descritor['municipioGerenciador'] = mun;
        if (ent != null) descritor['entidadeGerenciadora'] = ent;
      }
    }
    if (_codigoAtaCtrl.text.trim().isNotEmpty) {
      descritor['codigoAta'] = _codigoAta;
    }

    final map = <String, dynamic>{
      'descritor': descritor,
      'itens': _itens,
      'tipoContratoId': _tipoContratoId,
      'numeroContratoEmpenho': _numeroContratoEmpenhoCtrl.text.trim(),
      'anoContrato': int.tryParse(_anoContratoCtrl.text.trim()) ?? 0,
      'categoriaProcessoId': _categoriaProcessoId,
      'receita': _receita,
      'niFornecedor': _niFornecedorCtrl.text.trim(),
      'tipoPessoaFornecedor': _tipoPessoaFornecedor,
      'nomeRazaoSocialFornecedor': _nomeRazaoSocialFornecedorCtrl.text.trim(),
      'objetoContrato': _objetoContratoCtrl.text.trim(),
      'valorInicial': double.parse(
        parseBrCurrency(_valorInicialCtrl.text.trim()).toStringAsFixed(4),
      ),
      'dataAssinatura': _dataAssinatura != null
          ? isoFmt.format(_dataAssinatura!)
          : '',
      'tipoObjetoContrato': _tipoObjetoContrato,
    };

    if (_dataVigenciaInicio != null) {
      map['dataVigenciaInicio'] = isoFmt.format(_dataVigenciaInicio!);
    }
    if (_dataVigenciaFim != null) {
      map['dataVigenciaFim'] = isoFmt.format(_dataVigenciaFim!);
    }
    if (_fontesRecurso.isNotEmpty) {
      map['fonteRecursosContratacao'] = _fontesRecurso.toList()..sort();
    }
    if (_processoCtrl.text.trim().isNotEmpty) {
      map['processo'] = _processoCtrl.text.trim();
    }
    if (_despesas.isNotEmpty) {
      map['despesas'] = _despesas;
    }
    if (_codigoUnidadeCtrl.text.trim().isNotEmpty) {
      map['codigoUnidade'] = _codigoUnidadeCtrl.text.trim();
    }
    if (_niFornecedorSubCtrl.text.trim().isNotEmpty) {
      map['niFornecedorSubContratado'] = _niFornecedorSubCtrl.text.trim();
    }
    if (_tipoPessoaFornecedorSub != null) {
      map['tipoPessoaFornecedorSubContratado'] = _tipoPessoaFornecedorSub;
    }
    if (_nomeRazaoSocialFornecedorSubCtrl.text.trim().isNotEmpty) {
      map['nomeRazaoSocialFornecedorSubContratado'] =
          _nomeRazaoSocialFornecedorSubCtrl.text.trim();
    }
    if (_infComplementarCtrl.text.trim().isNotEmpty) {
      map['informacaoComplementar'] = _infComplementarCtrl.text.trim();
    }
    if (_numeroParcelasCtrl.text.trim().isNotEmpty) {
      map['numeroParcelas'] = int.tryParse(_numeroParcelasCtrl.text.trim());
    }
    if (_valorParcelaCtrl.text.trim().isNotEmpty) {
      map['valorParcela'] = double.parse(
        parseBrCurrency(_valorParcelaCtrl.text.trim()).toStringAsFixed(4),
      );
    }
    if (_valorGlobalCtrl.text.trim().isNotEmpty) {
      map['valorGlobal'] = double.parse(
        parseBrCurrency(_valorGlobalCtrl.text.trim()).toStringAsFixed(4),
      );
    }
    if (_valorAcumuladoCtrl.text.trim().isNotEmpty) {
      map['valorAcumulado'] = double.parse(
        parseBrCurrency(_valorAcumuladoCtrl.text.trim()).toStringAsFixed(4),
      );
    }
    if (_vigenciaMesesCtrl.text.trim().isNotEmpty) {
      map['vigenciaMeses'] = int.tryParse(_vigenciaMesesCtrl.text.trim());
    }

    return map;
  }

  // ── Salvar rascunho ───────────────────────────────────────────────────

  bool _validateDraft() {
    if (_exigeEditalLocal && _editalId == null) {
      _showError('Selecione o Edital vinculado para salvar o rascunho.');
      return false;
    }
    if (_codigoEditalCtrl.text.trim().isEmpty) {
      _showError('Informe o Código do Edital para salvar o rascunho.');
      return false;
    }
    final contratoError = _editalSemPncp
        ? AjusteRules.validarCodigoContratoSemPncp(_codigoContratoCtrl.text)
        : AjusteRules.validarCodigoContrato(_codigoContratoCtrl.text);
    if (contratoError != null) {
      _showError(contratoError);
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
      final dao = ref.read(ajustesDaoProvider);
      final municipio = ref.read(codigoMunicipioProvider);
      final entidade = ref.read(codigoEntidadeProvider);
      final codigoAta = _codigoAta;
      final codigoContrato = _editalSemPncp
          ? _codigoContratoCtrl.text.trim()
          : PcnpInputFormatter.stripMask(_codigoContratoCtrl.text);

      if (_loadedId == null) {
        final id = await dao.insertAjuste(
          editalId: _editalId,
          ataId: null,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: _codigoEdital,
          codigoAta: codigoAta.isNotEmpty ? codigoAta : null,
          codigoContrato: codigoContrato,
          retificacao: _retificacao,
          status: 'draft',
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
        _loadedId = id;
      } else {
        await dao.updateAjuste(
          id: _loadedId!,
          editalId: _editalId,
          ataId: _ataIdOriginal,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: _codigoEdital,
          codigoAta: codigoAta.isNotEmpty ? codigoAta : null,
          codigoContrato: codigoContrato,
          retificacao: _retificacao,
          status: 'draft',
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
      }
      ref.invalidate(ajustesDraftProvider);
      ref.invalidate(ajustesEnviadosProvider);
      ref.invalidate(processosProvider);

      if (mounted) {
        setState(() {});
        AudespSnackBar.success(context, 'Rascunho salvo com sucesso.');
      }
    } catch (e) {
      _showError('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Enviar ────────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    if (_exigeEditalLocal && _editalId == null) {
      _showError('Selecione o Edital vinculado.');
      return;
    }
    final editalId = _editalId;
    final adesao = _adesaoParticipacao;
    if (!adesao) {
      try {
        final processos = await _carregarOpcoesEdital();
        if (!mounted ||
            editalId != _editalId ||
            adesao != _adesaoParticipacao) {
          return;
        }
        final processo = processos
            .where((p) => p.edital.id == editalId)
            .firstOrNull;
        final motivo = processo == null
            ? 'O edital vinculado não foi encontrado.'
            : ProcessoRules.motivoBloqueioAjuste(processo) ??
                  _motivoBloqueioAta;
        if (motivo != null) {
          _showError(motivo);
          return;
        }
      } catch (e) {
        _showError('Não foi possível conferir as dependências do edital: $e');
        return;
      }
    }
    await _carregarItensLicitacao();
    if (!mounted || editalId != _editalId || adesao != _adesaoParticipacao) {
      return;
    }
    if (!adesao && editalId != null && _itensLicitacao == null) {
      _showError(
        'Não foi possível conferir os itens: a licitação enviada do edital não possui itens legíveis.',
      );
      return;
    }
    if (_codigoTipoOrgao == null) {
      _showError(
        'Configure o Código do Tipo de Órgão na Administração antes de enviar.',
      );
      return;
    }
    setState(() => _validacaoSolicitada = true);
    if (!_formKey.currentState!.validate()) return;
    if (_exigeFonteRecursos && _fontesRecurso.isEmpty) {
      _showError(
        'Selecione ao menos uma fonte de recurso para este tipo de órgão e processo de despesa.',
      );
      return;
    }
    if (_itens.isEmpty) {
      _showError('Informe ao menos um item contratado.');
      return;
    }
    final erroEnvio = AjusteRules.validarEnvio(
      _buildJson(),
      numerosLicitacao: _itensLicitacao,
    );
    if (erroEnvio != null) {
      _showError(erroEnvio);
      return;
    }
    final isEmpenho = _tipoContratoId == 7;

    if (_exigeDespesas && _despesas.isEmpty) {
      _showError(
        'A classificação de despesa é obrigatória para este tipo de órgão e ajuste.',
      );
      return;
    }
    if (isEmpenho && _despesas.length > 1) {
      _showError(
        'Para empenho (tipo 7), informe apenas uma classificação de despesa.',
      );
      return;
    }
    if (_dataAssinatura == null) {
      _showError('Informe a data de assinatura.');
      return;
    }
    final erroVigencia =
        _validarDataVigenciaInicio(_dataVigenciaInicio) ??
        _validarVigenciaMeses(_vigenciaMesesCtrl.text) ??
        _validarDataVigenciaFim(_dataVigenciaFim);
    if (erroVigencia != null) {
      _showError(erroVigencia);
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
        final service = ref.read(ajusteServiceProvider);
        final msg = await service.enviarAjuste(
          ajusteId: _loadedId!,
          documentoJson: jsonStr,
          userId: user?.id,
        );
        if (!mounted) return;
        ref.invalidate(processosProvider);
        setState(() => _isSent = true);
        if (mounted) {
          AudespSnackBar.success(context, msg);
          context.go('/ajuste');
        }
      },
    );
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
    final ajuste = await ref.read(ajustesDaoProvider).findById(_loadedId!);
    if (ajuste == null) return;
    final log = await ref
        .read(apiLogsDaoProvider)
        .findLatestAjusteSendLog(
          municipio: ajuste.municipio,
          entidade: ajuste.entidade,
          codigoEdital: ajuste.codigoEdital,
          codigoAta: ajuste.codigoAta,
          codigoContrato: ajuste.codigoContrato,
          retificacao: ajuste.retificacao,
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
          'O ajuste voltara para edicao local. Os logs e o protocolo AUDESP serao mantidos.',
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
      await ref.read(ajustesDaoProvider).markAsDraft(_loadedId!);
      if (!mounted) return;
      ref.invalidate(ajustesDraftProvider);
      ref.invalidate(ajustesEnviadosProvider);
      ref.invalidate(processosProvider);
      if (mounted) {
        setState(() {
          _isSent = false;
          _lastSendLog = null;
        });
        AudespSnackBar.success(context, 'Ajuste retornado para rascunho.');
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

  Future<void> _addItem() async {
    final val = int.tryParse(_itemCtrl.text.trim());
    if (val == null || val < 1) {
      _showError('Informe um número de item válido.');
      _itemFocusNode.requestFocus();
      return;
    }
    final editalId = _editalId;
    final adesao = _adesaoParticipacao;
    await _carregarItensLicitacao();
    if (!mounted || editalId != _editalId || adesao != _adesaoParticipacao) {
      return;
    }
    if (_itens.contains(val)) {
      _showError('Item/Lote $val já adicionado.');
      _itemFocusNode.requestFocus();
      return;
    }
    final erro = AjusteRules.validarItens(
      [val],
      adesaoParticipacao: _adesaoParticipacao,
      numerosLicitacao: _itensLicitacao,
    );
    if (erro != null) {
      _showError(erro);
      _itemFocusNode.requestFocus();
      return;
    }
    setState(() {
      _itens.add(val);
      _itens.sort();
      _itemCtrl.clear();
    });
    _itemFocusNode.requestFocus();
  }

  void _addDespesa() {
    final val = _despesaCtrl.text.trim();
    if (val.length != 8) {
      _showError('A classificação de despesa deve ter exatamente 8 dígitos.');
      _despesaFocusNode.requestFocus();
      return;
    }
    if (_despesas.contains(val)) {
      _showError('Despesa $val já adicionada.');
      _despesaFocusNode.requestFocus();
      return;
    }
    setState(() {
      _despesas.add(val);
      _despesaCtrl.clear();
    });
    _despesaFocusNode.requestFocus();
  }

  Future<void> _preencherPelaLicitacao() async {
    if (!_podePreencherPelaLicitacao || _preenchendoLicitacao) return;
    final editalId = _editalId!;
    setState(() => _preenchendoLicitacao = true);
    try {
      final licitacoes = await ref
          .read(licitacoesDaoProvider)
          .watchByEdital(editalId);
      if (!mounted || editalId != _editalId || !_podePreencherPelaLicitacao) {
        return;
      }
      final licitacao = LicitacaoReferencia.selecionar(licitacoes);
      if (licitacao == null) {
        _showError('Não há licitação enviada para o edital selecionado.');
        return;
      }
      final edital = await ref.read(editaisDaoProvider).findById(editalId);
      if (!mounted || editalId != _editalId || !_podePreencherPelaLicitacao) {
        return;
      }
      if (edital == null) {
        _showError('O edital selecionado não foi encontrado.');
        return;
      }
      final fornecedores = LicitacaoResultado.fornecedoresVencedores(
        jsonDecode(licitacao.documentoJson) as Map<String, dynamic>,
        jsonDecode(edital.documentoJson) as Map<String, dynamic>,
      );
      if (fornecedores.isEmpty) {
        _showError(
          'A licitação enviada não tem vencedores em itens homologados.',
        );
        return;
      }
      final fornecedor = fornecedores.length == 1
          ? fornecedores.single
          : await _escolherFornecedorVencedor(fornecedores);
      if (!mounted ||
          fornecedor == null ||
          editalId != _editalId ||
          !_podePreencherPelaLicitacao) {
        return;
      }
      final sugestoes = <String, String>{
        'niFornecedor': fornecedor.niPessoa,
        'tipoPessoaFornecedor': fornecedor.tipoPessoaId,
        if (fornecedor.nomeRazaoSocial.isNotEmpty)
          'nomeRazaoSocialFornecedor': fornecedor.nomeRazaoSocial,
        'itens': fornecedor.itens.join(', '),
        if (fornecedor.valorSugerido != null)
          'valorInicial': doubleToBrString(fornecedor.valorSugerido),
      };
      final aceitos = await showGeminiReviewDialog(
        context: context,
        currentValues: _valoresAtuais(),
        suggestedValues: sugestoes,
        title: 'Preencher pela licitação',
        suggestionLabel: 'Licitação',
      );
      if (!mounted ||
          aceitos == null ||
          aceitos.isEmpty ||
          editalId != _editalId ||
          !_podePreencherPelaLicitacao) {
        return;
      }
      setState(() {
        final tipoAtual = _tipoPessoaFornecedor;
        _aplicarCamposAceitos(aceitos);
        // Na revisão local, o tipo só muda se sua sugestão foi aceita.
        if (!aceitos.containsKey('tipoPessoaFornecedor')) {
          _tipoPessoaFornecedor = tipoAtual;
        }
      });
      AudespSnackBar.success(
        context,
        '${aceitos.length} campo(s) preenchido(s) pela licitação.',
      );
    } catch (e) {
      if (mounted && editalId == _editalId) {
        _showError('Erro ao preencher pela licitação: $e');
      }
    } finally {
      if (mounted) setState(() => _preenchendoLicitacao = false);
    }
  }

  Future<FornecedorVencedor?> _escolherFornecedorVencedor(
    List<FornecedorVencedor> fornecedores,
  ) {
    return showAudespDialog<FornecedorVencedor>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Escolher fornecedor vencedor'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: fornecedores.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final fornecedor = fornecedores[index];
                final ni = fornecedor.tipoPessoaId == 'PE'
                    ? fornecedor.niPessoa
                    : AudespCpfCnpjField.formatDocument(fornecedor.niPessoa);
                return ListTile(
                  title: Text(
                    fornecedor.nomeRazaoSocial.isEmpty
                        ? ni
                        : fornecedor.nomeRazaoSocial,
                  ),
                  subtitle: Text(
                    '$ni\nItens: ${fornecedor.itens.join(', ')}\n'
                    '${fornecedor.valorSugerido == null ? 'sem sugestão de valor' : 'Valor sugerido: ${formatBRL(fornecedor.valorSugerido)}'}',
                  ),
                  onTap: () => Navigator.of(dialogContext).pop(fornecedor),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Map<String, String> _valoresAtuais() => {
    'tipoContratoId': _tipoContratoId?.toString() ?? '',
    'numeroContratoEmpenho': _numeroContratoEmpenhoCtrl.text.trim(),
    'anoContrato': _anoContratoCtrl.text.trim(),
    'processo': _processoCtrl.text.trim(),
    'categoriaProcessoId': _categoriaProcessoId?.toString() ?? '',
    'fonteRecursosContratacao': (_fontesRecurso.toList()..sort()).join(', '),
    'niFornecedor': _niFornecedorCtrl.text.trim(),
    'tipoPessoaFornecedor': _tipoPessoaFornecedor ?? '',
    'nomeRazaoSocialFornecedor': _nomeRazaoSocialFornecedorCtrl.text.trim(),
    'tipoObjetoContrato': _tipoObjetoContrato?.toString() ?? '',
    'objetoContrato': _objetoContratoCtrl.text.trim(),
    'valorInicial': _valorInicialCtrl.text.trim(),
    'itens': _itens.join(', '),
    'despesas': _despesas.join(', '),
    'dataAssinatura': _dataAssinatura != null
        ? DateFormat('dd/MM/yyyy').format(_dataAssinatura!)
        : '',
    'dataVigenciaInicio': _dataVigenciaInicio != null
        ? DateFormat('dd/MM/yyyy').format(_dataVigenciaInicio!)
        : '',
    'prazoVigenciaMeses': _vigenciaMesesCtrl.text.trim(),
    'prazoVigenciaDias': '',
    'dataVigenciaFim': _dataVigenciaFim != null
        ? DateFormat('dd/MM/yyyy').format(_dataVigenciaFim!)
        : '',
  };

  void _aplicarCamposAceitos(Map<String, String> aceitos) {
    if (aceitos.containsKey('tipoContratoId')) {
      final match = RegExp(r'\d+').firstMatch(aceitos['tipoContratoId']!);
      if (match != null) _tipoContratoId = int.tryParse(match.group(0)!);
    }
    if (aceitos.containsKey('numeroContratoEmpenho')) {
      _numeroContratoEmpenhoCtrl.text = aceitos['numeroContratoEmpenho']!;
    }
    if (aceitos.containsKey('anoContrato')) {
      _anoContratoCtrl.text = aceitos['anoContrato']!;
    }
    if (aceitos.containsKey('processo')) {
      _processoCtrl.text = aceitos['processo']!;
    }
    if (aceitos.containsKey('niFornecedor')) {
      final ni = aceitos['niFornecedor']!.replaceAll(RegExp(r'\D'), '');
      _niFornecedorCtrl.text = aceitos['niFornecedor']!;
      if (ni.length == 11) {
        _tipoPessoaFornecedor = 'PF';
      } else if (ni.length == 14) {
        _tipoPessoaFornecedor = 'PJ';
      } else if (ni.isNotEmpty) {
        _tipoPessoaFornecedor = 'PE';
      }
    }
    if (aceitos.containsKey('tipoPessoaFornecedor')) {
      _tipoPessoaFornecedor = aceitos['tipoPessoaFornecedor'];
    }
    if (aceitos.containsKey('itens')) {
      final itemsRaw = aceitos['itens']!;
      final regex = RegExp(r'\d+');
      _itens.clear();
      for (final match in regex.allMatches(itemsRaw)) {
        final val = int.tryParse(match.group(0)!);
        if (val != null && !_itens.contains(val)) {
          _itens.add(val);
        }
      }
      _itens.sort();
    }
    if (aceitos.containsKey('fonteRecursosContratacao')) {
      _fontesRecurso = _parseFontesRecurso(
        aceitos['fonteRecursosContratacao']!,
      );
    }
    if (aceitos.containsKey('despesas')) {
      _despesas = _parseDespesas(aceitos['despesas']!);
    }
    if (aceitos.containsKey('categoriaProcessoId')) {
      final match = RegExp(r'\d+').firstMatch(aceitos['categoriaProcessoId']!);
      if (match != null) {
        _categoriaProcessoId = int.tryParse(match.group(0)!);
      }
    }
    if (aceitos.containsKey('nomeRazaoSocialFornecedor')) {
      _nomeRazaoSocialFornecedorCtrl.text =
          aceitos['nomeRazaoSocialFornecedor']!;
    }
    if (aceitos.containsKey('tipoObjetoContrato')) {
      final match = RegExp(r'\d+').firstMatch(aceitos['tipoObjetoContrato']!);
      if (match != null) {
        _tipoObjetoContrato = int.tryParse(match.group(0)!);
      }
    }
    if (aceitos.containsKey('objetoContrato')) {
      _objetoContratoCtrl.text = aceitos['objetoContrato']!;
    }
    if (aceitos.containsKey('valorInicial')) {
      _valorInicialCtrl.text = aceitos['valorInicial']!;
    }
    if (aceitos.containsKey('dataAssinatura')) {
      try {
        _dataAssinatura = DateFormat(
          'dd/MM/yyyy',
        ).parse(aceitos['dataAssinatura']!);
      } catch (_) {}
    }
    if (aceitos.containsKey('dataVigenciaInicio')) {
      try {
        _dataVigenciaInicio = DateFormat(
          'dd/MM/yyyy',
        ).parse(aceitos['dataVigenciaInicio']!);
      } catch (_) {}
    }
    if (aceitos.containsKey('prazoVigenciaMeses')) {
      final raw = aceitos['prazoVigenciaMeses']!;
      if (raw.endsWith('d')) {
        final dias = _parseFirstInt(raw);
        if (dias != null) _vigenciaMesesCtrl.text = '';
        _prazoVigenciaDias = dias;
      } else {
        final meses = _parseFirstInt(raw);
        if (meses != null) _vigenciaMesesCtrl.text = meses.toString();
        _prazoVigenciaDias = null;
      }
    }
  }

  // ── Importação via Gemini ─────────────────────────────────────────────

  Future<void> _importFromDocument() async {
    final geminiService = ref.read(geminiServiceProvider);
    final prompt = geminiService.generatePromptFromFields(kAjusteGeminiFields);

    final result = await showAudespAiImportDialog(
      context,
      title: 'Importar Ajuste via IA',
      promptText: prompt,
    );

    if (result == null || !mounted) return;

    setState(() => _importingGemini = true);
    try {
      final currentValues = _valoresAtuais();

      Map<String, String>? accepted;

      if (result.mode == AiImportMode.manual) {
        if (result.jsonResponse == null || result.jsonResponse!.isEmpty) return;
        final parsed = geminiService.parseResult(
          result.jsonResponse!,
          kAjusteGeminiFields,
        );
        accepted = await showGeminiReviewDialog(
          context: context,
          currentValues: currentValues,
          suggestedValues: parsed,
        );
      } else {
        if (result.filePath == null) return;
        accepted = await showGeminiAjusteImportDialog(
          context: context,
          ref: ref,
          filePath: result.filePath!,
          currentValues: currentValues,
        );
      }

      if (!mounted || accepted == null || accepted.isEmpty) return;

      final aceitos = accepted;
      setState(() {
        _aplicarCamposAceitos(aceitos);
        _dataVigenciaFim = _calculateVigenciaFim(
          start: _dataVigenciaInicio,
          meses: _parseFirstInt(_vigenciaMesesCtrl.text),
          dias: _prazoVigenciaDias,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${aceitos.length} campo(s) preenchido(s) pelo Gemini.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importingGemini = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────

  static Set<int> _parseFontesRecurso(String raw) {
    final validCodes = kFonteRecursoAjuste.keys.toSet();
    final result = <int>{};
    for (final match in RegExp(r'\d+').allMatches(raw)) {
      final value = int.tryParse(match.group(0)!);
      if (value != null && validCodes.contains(value)) {
        result.add(value);
      }
    }
    return result;
  }

  static List<String> _parseDespesas(String raw) {
    final result = <String>[];

    void add(String value) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      final trimmed = digits.length > 8
          ? digits.substring(digits.length - 8)
          : digits;
      if (trimmed.length == 8 && !result.contains(trimmed)) {
        result.add(trimmed);
      }
    }

    final dottedPattern = RegExp(r'(\d)\.(\d)\.(\d{2})\.(\d{2})\.(\d{2})');
    for (final match in dottedPattern.allMatches(raw)) {
      add(
        '${match.group(1)!}${match.group(2)!}${match.group(3)!}${match.group(4)!}${match.group(5)!}',
      );
    }

    for (final match in RegExp(r'\d{8,}').allMatches(raw)) {
      add(match.group(0)!);
    }

    return result;
  }

  static int? _parseFirstInt(String raw) {
    final match = RegExp(r'\d+').firstMatch(raw);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static DateTime? _calculateVigenciaFim({
    required DateTime? start,
    required int? meses,
    required int? dias,
  }) {
    if (start == null) return null;
    if (meses != null && meses > 0) {
      return DateTime(start.year, start.month + meses, start.day);
    }
    if (dias != null && dias > 0) {
      return start.add(Duration(days: dias));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    ref.watch(codigoTipoOrgaoProvider);
    final readOnly = _isSent;
    final exigeFonteRecursos = _exigeFonteRecursos;
    final exigeDespesas = _exigeDespesas;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/ajuste')),
        title: Text(
          _loadedId == null
              ? 'Novo Ajuste'
              : _isSent
              ? 'Ajuste'
              : 'Editar Ajuste',
        ),
        actions: [
          if (!readOnly) ...[
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
                onPressed: _importingGemini || _preenchendoLicitacao
                    ? null
                    : _importFromDocument,
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
        autovalidateMode: _validacaoSolicitada
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vínculo com Edital ───────────────────────────────────
              SectionCard(
                title: 'Vínculo com Edital',
                children: [
                  AudespDropdown<int?>.items(
                    label: _adesaoParticipacao
                        ? 'Edital local (vínculo de cadastro)'
                        : 'Edital *',
                    value: _editais.any((e) => e.id == _editalId)
                        ? _editalId
                        : null,
                    items: [
                      if (_adesaoParticipacao)
                        const DropdownMenuItem(child: Text('— Nenhum —')),
                      for (final opcao in _opcoesVisiveis)
                        DropdownMenuItem(
                          value: opcao.processo.edital.id,
                          enabled: opcao.liberado,
                          child: Text(
                            '${opcao.processo.edital.dropdownLabel}${opcao.liberado ? '' : ' — bloqueado'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    readOnly: readOnly,
                    onChanged: (v) async {
                      setState(() {
                        _editalId = v;
                        _itensLicitacao = null;
                        _fillEditalDescriptor();
                      });
                      await _carregarItensLicitacao();
                    },
                    validator: _exigeEditalLocal
                        ? (v) =>
                              v == null ? 'Selecione o edital vinculado' : null
                        : null,
                  ),
                  if (_motivoBloqueioEdital case final motivo? when !_isSent)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AudespWarningMessage(
                        message:
                            '$motivo O rascunho pode ser salvo; o envio está bloqueado.',
                      ),
                    ),
                  if (_adesaoParticipacao) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Na adesão, o vínculo com um edital local é opcional e serve apenas para cadastro. Informe os códigos PNCP da entidade gerenciadora no descritor.',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Descritor ────────────────────────────────────────────
              SectionCard(
                title: 'Descritor',
                children: [
                  Builder(
                    builder: (context) {
                      final municipio = ref.watch(codigoMunicipioProvider);
                      final entidade = ref.watch(codigoEntidadeProvider);
                      if (municipio.isEmpty && entidade.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final codigoEdital = _codigoEditalCtrl.text.isEmpty
                          ? '-'
                          : _referenciasSemPncp
                          ? _codigoEditalCtrl.text
                          : PcnpInputFormatter.applyMask(
                              _codigoEditalCtrl.text,
                            );
                      final codigoAta = _codigoAtaCtrl.text.isEmpty
                          ? '-'
                          : _referenciasSemPncp
                          ? _codigoAtaCtrl.text
                          : PcnpInputFormatter.applyMask(_codigoAtaCtrl.text);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          [
                            'Município: $municipio',
                            'Entidade: $entidade',
                            'Código do Edital: $codigoEdital',
                            if (_adesaoParticipacao)
                              'Código da Ata: $codigoAta',
                          ].join('   |   '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _editalSemPncp
                            ? AudespTextField(
                                label: 'Código do Contrato (Sem PNCP) *',
                                controller: _codigoContratoCtrl,
                                readOnly: readOnly,
                                maxLength: 25,
                                validator:
                                    AjusteRules.validarCodigoContratoSemPncp,
                              )
                            : AudespPncpField(
                                label: 'ID do Contrato PNCP *',
                                controller: _codigoContratoCtrl,
                                readOnly: readOnly,
                                validator: AjusteRules.validarCodigoContrato,
                              ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: AudespCheckbox(
                          label: 'Retificação',
                          value: _retificacao,
                          onChanged: readOnly
                              ? null
                              : (v) => setState(() => _retificacao = v),
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 12),
                  // TextFormField(
                  //   controller: _codigoUnidadeCtrl,
                  //   decoration: const InputDecoration(
                  //       labelText: 'Código da Unidade (PNCP — opcional)'),
                  //   readOnly: readOnly,
                  // ),
                  const SizedBox(height: 4),
                  AudespCheckbox(
                    label: 'Adesão / Participação',
                    value: _adesaoParticipacao,
                    onChanged: readOnly ? null : _alterarAdesao,
                  ),
                  if (_adesaoParticipacao) ...[
                    const SizedBox(height: 12),
                    AudespPncpField(
                      label: 'ID de Contratação PNCP da Adesão *',
                      controller: _codigoEditalCtrl,
                      readOnly: readOnly,
                      validator: AjusteRules.validarCodigoEditalAdesao,
                    ),
                    const SizedBox(height: 12),
                    AudespPncpField(
                      label: 'ID da Ata PNCP da Adesão (opcional)',
                      controller: _codigoAtaCtrl,
                      readOnly: readOnly,
                      isAta: true,
                      validator: AjusteRules.validarCodigoAtaAdesao,
                    ),
                    const SizedBox(height: 12),
                    AudespCheckbox(
                      label: 'Gerenciadora Jurisdicionada',
                      value: _gerenciadoraJurisdicionada,
                      onChanged: readOnly
                          ? null
                          : (v) =>
                                setState(() => _gerenciadoraJurisdicionada = v),
                    ),
                    if (_gerenciadoraJurisdicionada) ...[
                      Row(
                        children: [
                          Expanded(
                            child: AudespNumberField(
                              label: 'Município Gerenciador *',
                              controller: _municipioGerenciadorCtrl,
                              readOnly: readOnly,
                              decimals: false,
                              validator: (v) =>
                                  _gerenciadoraJurisdicionada &&
                                      _adesaoParticipacao &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AudespNumberField(
                              label: 'Entidade Gerenciadora *',
                              controller: _entidadeGerenciadoraCtrl,
                              readOnly: readOnly,
                              decimals: false,
                              validator: (v) =>
                                  _gerenciadoraJurisdicionada &&
                                      _adesaoParticipacao &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      AudespNumberField(
                        label: 'CNPJ da Entidade Gerenciadora',
                        controller: _cnpjGerenciadoraCtrl,
                        readOnly: readOnly,
                        decimals: false,
                        maxLength: 14,
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Fontes de Recurso ─────────────────────────────────────
              SectionCard(
                title: 'Fontes de Recurso${exigeFonteRecursos ? ' *' : ''}',
                children: [
                  Text(
                    exigeFonteRecursos
                        ? 'Obrigatório para este tipo de órgão e processo de despesa.'
                        : 'Preenchimento opcional para este tipo de órgão e ajuste.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: kFonteRecursoAjuste.entries.map((e) {
                      final selected = _fontesRecurso.contains(e.key);
                      return FilterChip(
                        label: Text(
                          e.value,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: selected,
                        onSelected: readOnly
                            ? null
                            : (v) {
                                setState(() {
                                  if (v) {
                                    _fontesRecurso.add(e.key);
                                  } else {
                                    _fontesRecurso.remove(e.key);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Itens contratados ─────────────────────────────────────
              SectionCard(
                title: 'Itens/Lotes Contratados',
                children: [
                  if (!_adesaoParticipacao &&
                      _editalId != null &&
                      _itensLicitacao == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Aviso: os itens não puderam ser conferidos com uma licitação local para este edital.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ),
                  if (!readOnly)
                    AudespTextField(
                      label: 'Número do item/Lote',
                      controller: _itemCtrl,
                      focusNode: _itemFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      suffixIcon: AudespIconButton(
                        icon: Icons.add,
                        tooltip: 'Adicionar',
                        onPressed: _addItem,
                      ),
                      onFieldSubmitted: (_) => _addItem(),
                    ),
                  if (_itens.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum item/lote adicionado.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _itens
                          .map(
                            (n) => Chip(
                              label: Text('Item/Lote $n'),
                              deleteIcon: readOnly
                                  ? null
                                  : const Icon(Icons.close, size: 16),
                              onDeleted: readOnly
                                  ? null
                                  : () => setState(() => _itens.remove(n)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Dados do Contrato ─────────────────────────────────────
              SectionCard(
                title: 'Dados do Contrato',
                children: [
                  AudespDropdown<int>(
                    label: 'Tipo de Contrato *',
                    value: _tipoContratoId,
                    items: kTipoContrato,
                    readOnly: readOnly,
                    onChanged: (v) => setState(() => _tipoContratoId = v),
                    validator: (v) =>
                        v == null ? 'Selecione o tipo de contrato' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AudespTextField(
                          label: 'Número do Contrato/Empenho *',
                          controller: _numeroContratoEmpenhoCtrl,
                          readOnly: readOnly,
                          maxLength: 50,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : validarTamanhoMaximo(v, 50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: AudespNumberField(
                          label: 'Ano do Contrato *',
                          controller: _anoContratoCtrl,
                          readOnly: readOnly,
                          decimals: false,
                          maxLength: 4,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1970 || n > 2099) {
                              return 'Ano inválido (1970-2099)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AudespTextField(
                          label: 'Número do Processo *',
                          controller: _processoCtrl,
                          readOnly: readOnly,
                          maxLength: 50,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : validarTamanhoMaximo(v, 50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDropdown<int>(
                          label: 'Categoria do Processo *',
                          value: _categoriaProcessoId,
                          items: kCategoriaProcesso,
                          readOnly: readOnly,
                          onChanged: _alterarCategoriaProcesso,
                          validator: (v) => v == null
                              ? 'Selecione a categoria do processo'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ── Receita ou Despesa ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: AudespSegmentedButton<bool>(
                      label: 'Receita ou Despesa *',
                      segments: const {false: 'Despesa', true: 'Receita'},
                      icons: const {
                        false: Icons.arrow_circle_up_outlined,
                        true: Icons.arrow_circle_down_outlined,
                      },
                      selected: {_receita},
                      onSelectionChanged: readOnly
                          ? null
                          : (v) => setState(() => _receita = v.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Classificações de Despesa ─────────────────────────────
              SectionCard(
                title: 'Classificações de Despesa${exigeDespesas ? ' *' : ''}',
                children: [
                  Text(
                    exigeDespesas
                        ? 'Obrigatório para este tipo de órgão e ajuste.'
                        : 'Preenchimento opcional para este tipo de órgão e ajuste.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (!readOnly)
                    AudespTextField(
                      label: '8 dígitos (ex: 33903900)',
                      controller: _despesaCtrl,
                      focusNode: _despesaFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      suffixIcon: AudespIconButton(
                        icon: Icons.add,
                        tooltip: 'Adicionar',
                        onPressed: _addDespesa,
                      ),
                      onFieldSubmitted: (_) => _addDespesa(),
                    ),
                  if (_despesas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhuma despesa adicionada.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _despesas
                          .map(
                            (d) => Chip(
                              label: Text(d),
                              deleteIcon: readOnly
                                  ? null
                                  : const Icon(Icons.close, size: 16),
                              onDeleted: readOnly
                                  ? null
                                  : () => setState(() => _despesas.remove(d)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Fornecedor ────────────────────────────────────────────
              SectionCard(
                title: 'Fornecedor',
                titleActions: [
                  if (_podePreencherPelaLicitacao)
                    TextButton.icon(
                      onPressed:
                          _preenchendoLicitacao || _importingGemini || _saving
                          ? null
                          : _preencherPelaLicitacao,
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('Preencher pela licitação'),
                    ),
                ],
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AudespTextField(
                          label: 'NI do Fornecedor (CNPJ/CPF) *',
                          controller: _niFornecedorCtrl,
                          readOnly: readOnly,
                          maxLength: 50,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : validarTamanhoMaximo(v, 50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDropdown<String>(
                          label: 'Tipo de Pessoa *',
                          value: _tipoPessoaFornecedor,
                          items: kTipoPessoaFornecedor,
                          readOnly: readOnly,
                          onChanged: (v) =>
                              setState(() => _tipoPessoaFornecedor = v),
                          validator: (v) =>
                              v == null ? 'Selecione o tipo de pessoa' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AudespTextField(
                    label: 'Nome/Razão Social do Fornecedor *',
                    controller: _nomeRazaoSocialFornecedorCtrl,
                    readOnly: readOnly,
                    maxLength: 100,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Obrigatório'
                        : validarTamanhoMaximo(v, 100),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Subcontratado ─────────────────────────────────────────
              SectionCard(
                title: 'Subcontratado',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AudespTextField(
                          label: 'NI do Subcontratado',
                          controller: _niFornecedorSubCtrl,
                          readOnly: readOnly,
                          maxLength: 50,
                          validator: (v) => validarTamanhoMaximo(v, 50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDropdown<String?>(
                          label: 'Tipo de Pessoa',
                          value: _tipoPessoaFornecedorSub,
                          items: {
                            null: '— Nenhuma —',
                            for (final e in kTipoPessoaFornecedor.entries)
                              e.key: e.value,
                          },
                          readOnly: readOnly,
                          onChanged: (v) =>
                              setState(() => _tipoPessoaFornecedorSub = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AudespTextField(
                    label: 'Nome/Razão Social do Subcontratado',
                    controller: _nomeRazaoSocialFornecedorSubCtrl,
                    readOnly: readOnly,
                    maxLength: 100,
                    validator: (v) => validarTamanhoMaximo(v, 100),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Objeto e Valores ──────────────────────────────────────
              SectionCard(
                title: 'Objeto e Valores',
                children: [
                  AudespDropdown<int>(
                    key: ValueKey(_categoriaProcessoId),
                    label: 'Tipo de Objeto do Contrato *',
                    value: _objetosPermitidos.containsKey(_tipoObjetoContrato)
                        ? _tipoObjetoContrato
                        : null,
                    items: _objetosPermitidos,
                    readOnly: readOnly,
                    onChanged: (v) => setState(() => _tipoObjetoContrato = v),
                    validator: (v) => AjusteRules.validarTipoObjetoContrato(
                      categoriaProcessoId: _categoriaProcessoId,
                      tipoObjetoContrato: _tipoObjetoContrato,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AudespTextField(
                    label: 'Objeto do Contrato *',
                    controller: _objetoContratoCtrl,
                    readOnly: readOnly,
                    maxLength: 5120,
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Obrigatório'
                        : validarTamanhoMaximo(v, 5120),
                  ),
                  const SizedBox(height: 12),
                  AudespTextField(
                    label: 'Informações Complementares',
                    controller: _infComplementarCtrl,
                    readOnly: readOnly,
                    maxLength: 5120,
                    maxLines: 2,
                    validator: (v) => validarTamanhoMaximo(v, 5120),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AudespCurrencyField(
                          label: 'Valor Inicial *',
                          controller: _valorInicialCtrl,
                          readOnly: readOnly,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespCurrencyField(
                          label: 'Valor Global',
                          controller: _valorGlobalCtrl,
                          readOnly: readOnly,
                          validator: (_) => null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AudespNumberField(
                          label: 'Nº de Parcelas',
                          controller: _numeroParcelasCtrl,
                          readOnly: readOnly,
                          decimals: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespCurrencyField(
                          label: 'Valor da Parcela',
                          controller: _valorParcelaCtrl,
                          readOnly: readOnly,
                          validator: (_) => null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespCurrencyField(
                          label: 'Valor Acumulado',
                          controller: _valorAcumuladoCtrl,
                          readOnly: readOnly,
                          validator: (_) => null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Datas ────────────────────────────────────────────────
              SectionCard(
                title: 'Datas',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AudespDatePickerField(
                          label: 'Data de Assinatura *',
                          value: _dataAssinatura,
                          readOnly: readOnly,
                          onChanged: (d) => setState(() => _dataAssinatura = d),
                          validator: (d) => d == null ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDatePickerField(
                          label: _exigeDataVigenciaInicio
                              ? 'Início da Vigência *'
                              : 'Início da Vigência',
                          value: _dataVigenciaInicio,
                          readOnly: readOnly,
                          onChanged: (d) =>
                              setState(() => _dataVigenciaInicio = d),
                          validator: _validarDataVigenciaInicio,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDatePickerField(
                          label: _exigeDataVigenciaFim
                              ? 'Fim da Vigência *'
                              : 'Fim da Vigência',
                          value: _dataVigenciaFim,
                          readOnly: readOnly,
                          onChanged: (d) =>
                              setState(() => _dataVigenciaFim = d),
                          validator: _validarDataVigenciaFim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AudespNumberField(
                    label: _exigeVigenciaMeses
                        ? 'Vigência em Meses *'
                        : 'Vigência em Meses',
                    controller: _vigenciaMesesCtrl,
                    readOnly: readOnly,
                    decimals: false,
                    onChanged: (_) => setState(() {}),
                    validator: _validarVigenciaMeses,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
