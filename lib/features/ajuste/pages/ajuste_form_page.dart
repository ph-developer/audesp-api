import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../domain/ajuste_domain.dart';
import '../services/ajuste_service.dart';

/// Formulário de criação/edição de Ajuste (Fase 7 – Módulo 4).
///
/// [ajusteId] null → criar novo; não-null → editar existente.
class AjusteFormPage extends ConsumerStatefulWidget {
  final int? ajusteId;
  final int? preselectedEditalId;

  const AjusteFormPage({
    super.key,
    this.ajusteId,
    this.preselectedEditalId,
  });

  @override
  ConsumerState<AjusteFormPage> createState() => _AjusteFormPageState();
}

class _AjusteFormPageState extends ConsumerState<AjusteFormPage> {
  bool _loading = true;
  bool _saving = false;
  bool _isSent = false;
  int? _loadedId;

  // ── Vínculo com Edital e Ata ──────────────────────────────────────────
  int? _editalId;
  int? _ataId;
  List<Editai> _editais = [];
  List<Ata> _atas = [];

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
  int? _tipoContratoId;
  final _numeroContratoEmpenhoCtrl = TextEditingController();
  final _anoContratoCtrl = TextEditingController();
  final _processoCtrl = TextEditingController();
  int? _categoriaProcessoId;
  bool _receita = false;
  List<String> _despesas = [];
  final _despesaCtrl = TextEditingController();
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
    _numeroContratoEmpenhoCtrl.dispose();
    _anoContratoCtrl.dispose();
    _processoCtrl.dispose();
    _despesaCtrl.dispose();
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
    _editais = await ref.read(editaisDaoProvider).watchAll().first;
    _atas = await ref.read(atasDaoProvider).watchAll().first;

    if (widget.preselectedEditalId != null) {
      _editalId = widget.preselectedEditalId;
      _fillEditalDescriptor();
    }

    if (widget.ajusteId != null) {
      await _loadExisting(widget.ajusteId!);
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillEditalDescriptor() {
    if (_editalId == null) return;
    final edital = _editais.where((e) => e.id == _editalId).firstOrNull;
    if (edital != null && _codigoEditalCtrl.text.isEmpty) {
      _codigoEditalCtrl.text = edital.codigoEdital;
    }
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
    _ataId = ajuste.ataId;

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(ajuste.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    _codigoEditalCtrl.text =
        descritor['codigoEdital'] as String? ?? ajuste.codigoEdital;
    _codigoAtaCtrl.text =
        descritor['codigoAta'] as String? ?? ajuste.codigoAta ?? '';
    _codigoContratoCtrl.text =
        descritor['codigoContrato'] as String? ?? ajuste.codigoContrato;
    _retificacao = descritor['retificacao'] as bool? ?? ajuste.retificacao;
    _adesaoParticipacao =
        descritor['adesaoParticipacao'] as bool? ?? false;
    _gerenciadoraJurisdicionada =
        descritor['gerenciadoraJurisdicionada'] as bool? ?? false;
    _cnpjGerenciadoraCtrl.text =
        descritor['cnpjGerenciadora'] as String? ?? '';
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
    _valorInicialCtrl.text = (doc['valorInicial'] as num?)?.toString() ?? '';
    _numeroParcelasCtrl.text =
        (doc['numeroParcelas'] as num?)?.toString() ?? '';
    _valorParcelaCtrl.text = (doc['valorParcela'] as num?)?.toString() ?? '';
    _valorGlobalCtrl.text = (doc['valorGlobal'] as num?)?.toString() ?? '';
    _valorAcumuladoCtrl.text =
        (doc['valorAcumulado'] as num?)?.toString() ?? '';

    final assinatura = doc['dataAssinatura'] as String?;
    if (assinatura != null) _dataAssinatura = DateTime.tryParse(assinatura);
    final vigInicio = doc['dataVigenciaInicio'] as String?;
    if (vigInicio != null) {
      _dataVigenciaInicio = DateTime.tryParse(vigInicio);
    }
    final vigFim = doc['dataVigenciaFim'] as String?;
    if (vigFim != null) _dataVigenciaFim = DateTime.tryParse(vigFim);
    _vigenciaMesesCtrl.text =
        (doc['vigenciaMeses'] as num?)?.toString() ?? '';

    _tipoObjetoContrato = doc['tipoObjetoContrato'] as int?;

    if (mounted) setState(() => _loading = false);
  }

  // ── JSON builder ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final sessionUser = ref.read(localSessionProvider);
    final municipio = int.tryParse(sessionUser?.municipio ?? '') ?? 0;
    final entidade = int.tryParse(sessionUser?.entidade ?? '') ?? 0;
    final isoFmt = DateFormat('yyyy-MM-dd');

    final descritor = <String, dynamic>{
      'municipio': municipio,
      'entidade': entidade,
      'adesaoParticipacao': _adesaoParticipacao,
      'codigoEdital': _codigoEditalCtrl.text.trim(),
      'codigoContrato': _codigoContratoCtrl.text.trim(),
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
      descritor['codigoAta'] = _codigoAtaCtrl.text.trim();
    }

    final map = <String, dynamic>{
      'descritor': descritor,
      'fonteRecursosContratacao': _fontesRecurso.toList()..sort(),
      'itens': _itens,
      'tipoContratoId': _tipoContratoId,
      'numeroContratoEmpenho': _numeroContratoEmpenhoCtrl.text.trim(),
      'anoContrato': int.tryParse(_anoContratoCtrl.text.trim()) ?? 0,
      'categoriaProcessoId': _categoriaProcessoId,
      'receita': _receita,
      'niFornecedor': _niFornecedorCtrl.text.trim(),
      'tipoPessoaFornecedor': _tipoPessoaFornecedor,
      'nomeRazaoSocialFornecedor':
          _nomeRazaoSocialFornecedorCtrl.text.trim(),
      'objetoContrato': _objetoContratoCtrl.text.trim(),
      'valorInicial': double.tryParse(_valorInicialCtrl.text.trim()) ?? 0,
      'dataAssinatura': _dataAssinatura != null
          ? isoFmt.format(_dataAssinatura!)
          : '',
      'dataVigenciaInicio': _dataVigenciaInicio != null
          ? isoFmt.format(_dataVigenciaInicio!)
          : '',
      'dataVigenciaFim': _dataVigenciaFim != null
          ? isoFmt.format(_dataVigenciaFim!)
          : '',
      'tipoObjetoContrato': _tipoObjetoContrato,
    };

    if (_processoCtrl.text.trim().isNotEmpty) {
      map['processo'] = _processoCtrl.text.trim();
    }
    if (_despesas.isNotEmpty) map['despesas'] = _despesas;
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
      map['numeroParcelas'] =
          int.tryParse(_numeroParcelasCtrl.text.trim());
    }
    if (_valorParcelaCtrl.text.trim().isNotEmpty) {
      map['valorParcela'] =
          double.tryParse(_valorParcelaCtrl.text.trim());
    }
    if (_valorGlobalCtrl.text.trim().isNotEmpty) {
      map['valorGlobal'] = double.tryParse(_valorGlobalCtrl.text.trim());
    }
    if (_valorAcumuladoCtrl.text.trim().isNotEmpty) {
      map['valorAcumulado'] =
          double.tryParse(_valorAcumuladoCtrl.text.trim());
    }
    if (_vigenciaMesesCtrl.text.trim().isNotEmpty) {
      map['vigenciaMeses'] =
          int.tryParse(_vigenciaMesesCtrl.text.trim());
    }

    return map;
  }

  // ── Validation ────────────────────────────────────────────────────────

  String? _validateForm() {
    if (_editalId == null) return 'Selecione o Edital vinculado.';
    if (_codigoEditalCtrl.text.trim().isEmpty) return 'Informe o Código do Edital.';
    if (_codigoContratoCtrl.text.trim().isEmpty) return 'Informe o Código do Contrato.';
    if (_fontesRecurso.isEmpty) return 'Selecione ao menos uma fonte de recurso.';
    if (_itens.isEmpty) return 'Informe ao menos um item contratado.';
    if (_tipoContratoId == null) return 'Selecione o Tipo de Contrato.';
    if (_numeroContratoEmpenhoCtrl.text.trim().isEmpty) return 'Informe o Número do Contrato/Empenho.';
    if (_categoriaProcessoId == null) return 'Selecione a Categoria do Processo.';
    if (_niFornecedorCtrl.text.trim().isEmpty) return 'Informe o NI do Fornecedor.';
    if (_tipoPessoaFornecedor == null) return 'Selecione o Tipo de Pessoa do Fornecedor.';
    if (_nomeRazaoSocialFornecedorCtrl.text.trim().isEmpty) return 'Informe o Nome/Razão Social do Fornecedor.';
    if (_objetoContratoCtrl.text.trim().isEmpty) return 'Informe o Objeto do Contrato.';
    if (_valorInicialCtrl.text.trim().isEmpty) return 'Informe o Valor Inicial.';
    if (double.tryParse(_valorInicialCtrl.text.trim()) == null) return 'Valor Inicial inválido.';
    if (_dataAssinatura == null) return 'Informe a Data de Assinatura.';
    if (_dataVigenciaInicio == null) return 'Informe o Início da Vigência.';
    if (_dataVigenciaFim == null) return 'Informe o Fim da Vigência.';
    if (_tipoObjetoContrato == null) return 'Selecione o Tipo de Objeto do Contrato.';
    final ano = int.tryParse(_anoContratoCtrl.text.trim() );
    if (_anoContratoCtrl.text.trim().isNotEmpty && (ano == null || ano < 1970 || ano > 2099)) {
      return 'Ano do Contrato inválido (1970-2099).';
    }
    return null;
  }

  // ── Salvar rascunho ───────────────────────────────────────────────────

  Future<void> _saveDraft() async {
    if (_editalId == null) {
      _showError('Selecione o Edital vinculado.');
      return;
    }
    final err = _validateForm();
    if (err != null) { _showError(err); return; }

    setState(() => _saving = true);
    try {
      final doc = _buildJson();
      final jsonStr = jsonEncode(doc);
      final dao = ref.read(ajustesDaoProvider);
      final sessionUser = ref.read(localSessionProvider);
      final municipio = sessionUser?.municipio ?? '';
      final entidade = sessionUser?.entidade ?? '';

      if (_loadedId == null) {
        final id = await dao.insertAjuste(
          AjustesCompanion(
            editalId: Value(_editalId!),
            ataId: Value(_ataId),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoEdital: Value(_codigoEditalCtrl.text.trim()),
            codigoAta: Value(_codigoAtaCtrl.text.trim().isNotEmpty
                ? _codigoAtaCtrl.text.trim()
                : null),
            codigoContrato: Value(_codigoContratoCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            documentoJson: Value(jsonStr),
            updatedAt: Value(DateTime.now()),
          ),
        );
        _loadedId = id;
      } else {
        await dao.updateAjuste(
          AjustesCompanion(
            id: Value(_loadedId!),
            editalId: Value(_editalId!),
            ataId: Value(_ataId),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoEdital: Value(_codigoEditalCtrl.text.trim()),
            codigoAta: Value(_codigoAtaCtrl.text.trim().isNotEmpty
                ? _codigoAtaCtrl.text.trim()
                : null),
            codigoContrato: Value(_codigoContratoCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            documentoJson: Value(jsonStr),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      if (mounted) {
        setState(() {});
        displayInfoBar(context,
            builder: (ctx, close) => InfoBar(
                  title: const Text('Rascunho salvo com sucesso.'),
                  severity: InfoBarSeverity.success,
                ));
      }
    } catch (e) {
      _showError('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Enviar ────────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    final err = _validateForm();
    if (err != null) {
      _showError(err);
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
        setState(() => _isSent = true);
        if (mounted) {
          displayInfoBar(context,
              builder: (ctx, close) => InfoBar(
                    title: Text(msg),
                    severity: InfoBarSeverity.success,
                  ));
          context.go('/ajuste');
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

  // ─────────────────────────────────────────────────────────────────────

  void _addItem() {
    final val = int.tryParse(_itemCtrl.text.trim());
    if (val == null || val < 1) {
      _showError('Informe um número de item válido.');
      return;
    }
    if (_itens.contains(val)) {
      _showError('Item $val já adicionado.');
      return;
    }
    setState(() {
      _itens.add(val);
      _itens.sort();
      _itemCtrl.clear();
    });
  }

  void _addDespesa() {
    final val = _despesaCtrl.text.trim();
    if (val.length != 8) {
      _showError('A classificação de despesa deve ter exatamente 8 dígitos.');
      return;
    }
    if (_despesas.contains(val)) {
      _showError('Despesa $val já adicionada.');
      return;
    }
    setState(() {
      _despesas.add(val);
      _despesaCtrl.clear();
    });
  }

  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ScaffoldPage(
          content: Center(child: ProgressRing()));
    }

    final readOnly = _isSent;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.go('/ajuste'),
        ),
        title: Text(
          _loadedId == null
              ? 'Novo Ajuste'
              : _isSent
                  ? 'Ajuste (Enviado)'
                  : 'Editar Ajuste',
        ),
        commandBar: readOnly
            ? null
            : _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: ProgressRing(strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Button(
                        onPressed: _saveDraft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(FluentIcons.save, size: 16),
                            SizedBox(width: 6),
                            Text('Salvar Rascunho'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _enviar,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.send, size: 16),
                            SizedBox(width: 6),
                            Text('Enviar à AUDESP'),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // ── Vínculo com Edital ───────────────────────────────────
              SectionHeader(title: 'Vínculo com Edital'),
              InfoLabel(
                label: 'Edital *',
                child: ComboBox<int>(
                  value: _editalId,
                  placeholder: const Text('Selecione o edital vinculado'),
                  isExpanded: true,
                  items: _editais
                      .map((e) => ComboBoxItem(
                            value: e.id,
                            child: Text(
                              '${e.codigoEdital} — Mun.${e.municipio}/Ent.${e.entidade}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: readOnly
                      ? null
                      : (v) {
                          setState(() {
                            _editalId = v;
                            _fillEditalDescriptor();
                          });
                        },
                ),
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Ata (opcional — somente para SRP)',
                child: ComboBox<int?>(
                  value: _ataId,
                  placeholder: const Text('— Nenhuma —'),
                  isExpanded: true,
                  items: [
                    const ComboBoxItem<int?>(
                        value: null, child: Text('— Nenhuma —')),
                    ..._atas.map((a) => ComboBoxItem(
                          value: a.id,
                          child: Text(
                            '${a.codigoAta} — ${a.codigoEdital}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: readOnly
                      ? null
                      : (v) {
                          setState(() {
                            _ataId = v;
                            if (v != null) {
                              final ata =
                                  _atas.where((a) => a.id == v).firstOrNull;
                              if (ata != null) {
                                _codigoAtaCtrl.text = ata.codigoAta;
                              }
                            } else {
                              _codigoAtaCtrl.clear();
                            }
                          });
                        },
                ),
              ),
              const SizedBox(height: 24),

              // ── Descritor ────────────────────────────────────────────
              SectionHeader(title: 'Descritor'),
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'Código do Edital *',
                      child: TextBox(
                        controller: _codigoEditalCtrl,
                        enabled: !readOnly,
                        maxLength: 25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Código da Ata (opcional)',
                      child: TextBox(
                        controller: _codigoAtaCtrl,
                        enabled: !readOnly,
                        maxLength: 30,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Código do Contrato *',
                child: TextBox(
                  controller: _codigoContratoCtrl,
                  enabled: !readOnly,
                  maxLength: 25,
                ),
              ),
              const SizedBox(height: 12),
              ToggleSwitch(
                checked: _retificacao,
                onChanged: readOnly ? null : (v) => setState(() => _retificacao = v),
                content: const Text('Retificação'),
              ),
              const SizedBox(height: 8),
              ToggleSwitch(
                checked: _adesaoParticipacao,
                onChanged:
                    readOnly ? null : (v) => setState(() => _adesaoParticipacao = v),
                content: const Text('Adesão / Participação'),
              ),
              if (_adesaoParticipacao) ...[
                const SizedBox(height: 8),
                ToggleSwitch(
                  checked: _gerenciadoraJurisdicionada,
                  onChanged: readOnly
                      ? null
                      : (v) =>
                          setState(() => _gerenciadoraJurisdicionada = v),
                  content: const Text('Gerenciadora Jurisdicionada (TCE-SP)'),
                ),
                const SizedBox(height: 8),
                if (_gerenciadoraJurisdicionada) ...[
                  Row(
                    children: [
                      Expanded(
                        child: InfoLabel(
                          label: 'Município Gerenciador *',
                          child: TextBox(
                            controller: _municipioGerenciadorCtrl,
                            enabled: !readOnly,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoLabel(
                          label: 'Entidade Gerenciadora *',
                          child: TextBox(
                            controller: _entidadeGerenciadoraCtrl,
                            enabled: !readOnly,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  InfoLabel(
                    label: 'CNPJ da Entidade Gerenciadora',
                    child: TextBox(
                      controller: _cnpjGerenciadoraCtrl,
                      enabled: !readOnly,
                      maxLength: 14,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),

              // ── Fontes de Recurso ─────────────────────────────────────
              SectionHeader(title: 'Fontes de Recurso *'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: kFonteRecursoAjuste.entries.map((e) {
                  return Checkbox(
                    checked: _fontesRecurso.contains(e.key),
                    onChanged: readOnly
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                _fontesRecurso.add(e.key);
                              } else {
                                _fontesRecurso.remove(e.key);
                              }
                            });
                          },
                    content: Text(e.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Itens contratados ─────────────────────────────────────
              SectionHeader(title: 'Itens Contratados *'),
              if (!readOnly)
                Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        controller: _itemCtrl,
                        placeholder: 'Número do item',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: _addItem,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(FluentIcons.add, size: 14),
                          SizedBox(width: 6),
                          Text('Adicionar'),
                        ],
                      ),
                    ),
                  ],
                ),
              if (_itens.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _itens
                      .map((n) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: FluentTheme.of(context)
                                  .accentColor
                                  .withValues(alpha: 0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Item $n'),
                                if (!readOnly) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _itens.remove(n)),
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
              const SizedBox(height: 24),

              // ── Dados do Contrato ─────────────────────────────────────
              SectionHeader(title: 'Dados do Contrato'),
              InfoLabel(
                label: 'Tipo de Contrato *',
                child: ComboBox<int>(
                  value: _tipoContratoId,
                  placeholder: const Text('Selecione o tipo de contrato'),
                  isExpanded: true,
                  items: kTipoContrato.entries
                      .map((e) => ComboBoxItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged:
                      readOnly ? null : (v) => setState(() => _tipoContratoId = v),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InfoLabel(
                      label: 'Número do Contrato/Empenho *',
                      child: TextBox(
                        controller: _numeroContratoEmpenhoCtrl,
                        enabled: !readOnly,
                        maxLength: 50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: InfoLabel(
                      label: 'Ano do Contrato *',
                      child: TextBox(
                        controller: _anoContratoCtrl,
                        enabled: !readOnly,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Número do Processo (opcional)',
                child: TextBox(
                  controller: _processoCtrl,
                  enabled: !readOnly,
                  maxLength: 50,
                ),
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Categoria do Processo *',
                child: ComboBox<int>(
                  value: _categoriaProcessoId,
                  placeholder: const Text('Selecione a categoria do processo'),
                  isExpanded: true,
                  items: kCategoriaProcesso.entries
                      .map((e) => ComboBoxItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: readOnly
                      ? null
                      : (v) => setState(() => _categoriaProcessoId = v),
                ),
              ),
              const SizedBox(height: 12),
              ToggleSwitch(
                checked: _receita,
                onChanged:
                    readOnly ? null : (v) => setState(() => _receita = v),
                content: const Text('Receita'),
              ),
              const SizedBox(height: 12),

              // Despesas
              SectionHeader(title: 'Classificações de Despesa'),
              if (!readOnly)
                Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        controller: _despesaCtrl,
                        placeholder: '8 dígitos (ex: 33903900)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        onSubmitted: (_) => _addDespesa(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: _addDespesa,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(FluentIcons.add, size: 14),
                          SizedBox(width: 6),
                          Text('Adicionar'),
                        ],
                      ),
                    ),
                  ],
                ),
              if (_despesas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _despesas
                      .map((d) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: FluentTheme.of(context)
                                  .accentColor
                                  .withValues(alpha: 0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(d),
                                if (!readOnly) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _despesas.remove(d)),
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
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Código da Unidade (PNCP — opcional)',
                child: TextBox(
                  controller: _codigoUnidadeCtrl,
                  enabled: !readOnly,
                  maxLength: 30,
                ),
              ),
              const SizedBox(height: 24),

              // ── Fornecedor ────────────────────────────────────────────
              SectionHeader(title: 'Fornecedor'),
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'NI do Fornecedor (CNPJ/CPF) *',
                      child: TextBox(
                        controller: _niFornecedorCtrl,
                        enabled: !readOnly,
                        maxLength: 50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Tipo de Pessoa *',
                      child: ComboBox<String>(
                        value: _tipoPessoaFornecedor,
                        placeholder: const Text('Selecione'),
                        isExpanded: true,
                        items: kTipoPessoaFornecedor.entries
                            .map((e) => ComboBoxItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: readOnly
                            ? null
                            : (v) => setState(() => _tipoPessoaFornecedor = v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Nome/Razão Social do Fornecedor *',
                child: TextBox(
                  controller: _nomeRazaoSocialFornecedorCtrl,
                  enabled: !readOnly,
                  maxLength: 100,
                ),
              ),
              const SizedBox(height: 16),

              // Subcontratado (opcional)
              SectionHeader(title: 'Subcontratado (opcional)'),
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'NI do Subcontratado',
                      child: TextBox(
                        controller: _niFornecedorSubCtrl,
                        enabled: !readOnly,
                        maxLength: 50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Tipo de Pessoa',
                      child: ComboBox<String?>(
                        value: _tipoPessoaFornecedorSub,
                        placeholder: const Text('— Nenhum —'),
                        isExpanded: true,
                        items: [
                          const ComboBoxItem<String?>(
                              value: null, child: Text('— Nenhum —')),
                          ...kTipoPessoaFornecedor.entries.map((e) =>
                              ComboBoxItem(
                                value: e.key,
                                child: Text(e.value),
                              )),
                        ],
                        onChanged: readOnly
                            ? null
                            : (v) =>
                                setState(() => _tipoPessoaFornecedorSub = v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Nome/Razão Social do Subcontratado',
                child: TextBox(
                  controller: _nomeRazaoSocialFornecedorSubCtrl,
                  enabled: !readOnly,
                  maxLength: 100,
                ),
              ),
              const SizedBox(height: 24),

              // ── Objeto e Valores ──────────────────────────────────────
              SectionHeader(title: 'Objeto e Valores'),
              InfoLabel(
                label: 'Objeto do Contrato *',
                child: TextBox(
                  controller: _objetoContratoCtrl,
                  enabled: !readOnly,
                  maxLength: 5120,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Informações Complementares (opcional)',
                child: TextBox(
                  controller: _infComplementarCtrl,
                  enabled: !readOnly,
                  maxLength: 5120,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'Valor Inicial (R\$) *',
                      child: TextBox(
                        controller: _valorInicialCtrl,
                        enabled: !readOnly,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Valor Global (R\$)',
                      child: TextBox(
                        controller: _valorGlobalCtrl,
                        enabled: !readOnly,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'Nº de Parcelas',
                      child: TextBox(
                        controller: _numeroParcelasCtrl,
                        enabled: !readOnly,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Valor da Parcela (R\$)',
                      child: TextBox(
                        controller: _valorParcelaCtrl,
                        enabled: !readOnly,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Valor Acumulado (R\$)',
                      child: TextBox(
                        controller: _valorAcumuladoCtrl,
                        enabled: !readOnly,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Datas ────────────────────────────────────────────────
              SectionHeader(title: 'Datas'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'Data de Assinatura *',
                      child: DatePicker(
                        selected: _dataAssinatura,
                        onChanged: readOnly
                            ? null
                            : (d) => setState(() => _dataAssinatura = d),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Início da Vigência *',
                      child: DatePicker(
                        selected: _dataVigenciaInicio,
                        onChanged: readOnly
                            ? null
                            : (d) => setState(() => _dataVigenciaInicio = d),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Fim da Vigência *',
                      child: DatePicker(
                        selected: _dataVigenciaFim,
                        onChanged: readOnly
                            ? null
                            : (d) => setState(() => _dataVigenciaFim = d),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Vigência em Meses (opcional)',
                child: TextBox(
                  controller: _vigenciaMesesCtrl,
                  enabled: !readOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tipo de Objeto ────────────────────────────────────────
              SectionHeader(title: 'Tipo de Objeto do Contrato'),
              InfoLabel(
                label: 'Tipo de Objeto do Contrato *',
                child: ComboBox<int>(
                  value: _tipoObjetoContrato,
                  placeholder: const Text('Selecione o tipo de objeto'),
                  isExpanded: true,
                  items: kTipoObjetoContrato.entries
                      .map((e) => ComboBoxItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: readOnly
                      ? null
                      : (v) => setState(() => _tipoObjetoContrato = v),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// SectionHeader → lib/shared/widgets/section_header.dart

