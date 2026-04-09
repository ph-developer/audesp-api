import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/section_card.dart';
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
  final _formKey = GlobalKey<FormState>();

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
    final municipio = int.tryParse(ref.read(codigoMunicipioProvider)) ?? 0;
    final entidade = int.tryParse(ref.read(codigoEntidadeProvider)) ?? 0;
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
      'valorInicial': double.parse(
          (double.tryParse(_valorInicialCtrl.text.trim()) ?? 0)
              .toStringAsFixed(4)),
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
    if (_despesas.isNotEmpty && !_receita) map['despesas'] = _despesas;
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
      map['valorParcela'] = double.parse(
          (double.tryParse(_valorParcelaCtrl.text.trim()) ?? 0)
              .toStringAsFixed(4));
    }
    if (_valorGlobalCtrl.text.trim().isNotEmpty) {
      map['valorGlobal'] = double.parse(
          (double.tryParse(_valorGlobalCtrl.text.trim()) ?? 0)
              .toStringAsFixed(4));
    }
    if (_valorAcumuladoCtrl.text.trim().isNotEmpty) {
      map['valorAcumulado'] = double.parse(
          (double.tryParse(_valorAcumuladoCtrl.text.trim()) ?? 0)
              .toStringAsFixed(4));
    }
    if (_vigenciaMesesCtrl.text.trim().isNotEmpty) {
      map['vigenciaMeses'] =
          int.tryParse(_vigenciaMesesCtrl.text.trim());
    }

    return map;
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
    if (_codigoContratoCtrl.text.trim().isEmpty) {
      _showError('Informe o Código do Contrato para salvar o rascunho.');
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

  // ── Enviar ────────────────────────────────────────────────────────────

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
    if (_itens.isEmpty) {
      _showError('Informe ao menos um item contratado.');
      return;
    }
    if (_tipoContratoId == 7 && !_receita && _despesas.isEmpty) {
      _showError('Para empenho (tipo 7), informe ao menos uma classificação de despesa.');
      return;
    }
    if (_tipoContratoId == 7 && !_receita && _despesas.length > 1) {
      _showError('Para empenho (tipo 7), informe apenas uma classificação de despesa.');
      return;
    }
    if (_dataAssinatura == null ||
        _dataVigenciaInicio == null ||
        _dataVigenciaFim == null) {
      _showError('Preencha todas as datas obrigatórias.');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          context.go('/ajuste');
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
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final readOnly = _isSent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _loadedId == null
              ? 'Novo Ajuste'
              : _isSent
                  ? 'Ajuste (Enviado)'
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
                    child: CircularProgressIndicator(strokeWidth: 2)),
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vínculo com Edital ───────────────────────────────────
              SectionCard(
                title: 'Vínculo com Edital',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _editalId,
                          decoration: const InputDecoration(labelText: 'Edital *'),
                          isExpanded: true,
                          items: _editais
                              .map((e) => DropdownMenuItem(
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
                          validator: (v) =>
                              v == null ? 'Selecione o edital vinculado' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _ataId,
                          decoration: const InputDecoration(
                              labelText: 'Ata (opcional — somente para SRP)'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text('— Nenhuma —')),
                            ..._atas.map((a) => DropdownMenuItem(
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
                    ],
                  ),                  
                ],
              ),
              const SizedBox(height: 16),

              // ── Descritor ────────────────────────────────────────────
              SectionCard(
                title: 'Descritor',
                children: [
                  Builder(builder: (context) {
                    final municipio = ref.watch(codigoMunicipioProvider);
                    final entidade = ref.watch(codigoEntidadeProvider);
                    if (municipio.isEmpty && entidade.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Município: $municipio   |   Entidade: $entidade   |   Código do Edital: ${_codigoEditalCtrl.text.isEmpty ? '-' : _codigoEditalCtrl.text}   |   Código da Ata: ${_codigoAtaCtrl.text.isEmpty ? '-' : _codigoAtaCtrl.text}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }),                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codigoContratoCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Código do Contrato *'),
                          readOnly: readOnly,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: SwitchListTile(
                          title: const Text('Retificação'),
                          value: _retificacao,
                          onChanged:
                              readOnly ? null : (v) => setState(() => _retificacao = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codigoUnidadeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Código da Unidade (PNCP — opcional)'),
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: 4),                  
                  SwitchListTile(
                    title: const Text('Adesão / Participação'),
                    subtitle: const Text(
                        'Adesão ou participação em licitação gerenciada por outra entidade?'),
                    value: _adesaoParticipacao,
                    onChanged: readOnly
                        ? null
                        : (v) => setState(() => _adesaoParticipacao = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_adesaoParticipacao) ...[
                    SwitchListTile(
                      title: const Text('Gerenciadora Jurisdicionada'),
                      subtitle: const Text(
                          'A entidade gerenciadora é jurisdicionada ao TCE-SP?'),
                      value: _gerenciadoraJurisdicionada,
                      onChanged: readOnly
                          ? null
                          : (v) =>
                              setState(() => _gerenciadoraJurisdicionada = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_gerenciadoraJurisdicionada) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _municipioGerenciadorCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Município Gerenciador *'),
                              readOnly: readOnly,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) => _gerenciadoraJurisdicionada &&
                                      _adesaoParticipacao &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _entidadeGerenciadoraCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Entidade Gerenciadora *'),
                              readOnly: readOnly,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (v) => _gerenciadoraJurisdicionada &&
                                      _adesaoParticipacao &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Obrigatório'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _cnpjGerenciadoraCtrl,
                        decoration: const InputDecoration(
                            labelText: 'CNPJ da Entidade Gerenciadora'),
                        readOnly: readOnly,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(14),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Fontes de Recurso ─────────────────────────────────────
              SectionCard(
                title: 'Fontes de Recurso',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: kFonteRecursoAjuste.entries.map((e) {
                      final selected = _fontesRecurso.contains(e.key);
                      return FilterChip(
                        label: Text(e.value, style: const TextStyle(fontSize: 11)),
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
                title: 'Itens Contratados',
                children: [
                  if (!readOnly)
                    TextFormField(
                      controller: _itemCtrl,
                      decoration: InputDecoration(
                          labelText: 'Número do item',
                          hintText: 'Ex: 1',
                          suffixIcon: IconButton(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            tooltip: 'Adicionar',
                            iconSize: 18,
                          ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onFieldSubmitted: (_) => _addItem(),
                    ),
                  if (_itens.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum item adicionado.',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _itens
                          .map((n) => Chip(
                                label: Text('Item $n'),
                                deleteIcon: readOnly
                                    ? null
                                    : const Icon(Icons.close, size: 16),
                                onDeleted: readOnly
                                    ? null
                                    : () => setState(() => _itens.remove(n)),
                              ))
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
                  DropdownButtonFormField<int>(
                    initialValue: _tipoContratoId,
                    decoration: const InputDecoration(
                        labelText: 'Tipo de Contrato *'),
                    isExpanded: true,
                    items: kTipoContrato.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged:
                        readOnly ? null : (v) => setState(() => _tipoContratoId = v),
                    validator: (v) =>
                        v == null ? 'Selecione o tipo de contrato' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _numeroContratoEmpenhoCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Número do Contrato/Empenho *'),
                          readOnly: readOnly,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _anoContratoCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Ano do Contrato *',
                              hintText: 'Ex: 2024' 
                            ),
                          readOnly: readOnly,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
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
                        child: TextFormField(
                          controller: _processoCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Número do Processo *'),
                          readOnly: readOnly,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SearchableIntField(
                          items: kCategoriaProcesso,
                          value: _categoriaProcessoId,
                          label: 'Categoria do Processo *',
                          enabled: !readOnly,
                          onChanged: (v) => setState(
                              () => _categoriaProcessoId = v != null ? int.tryParse(v) : null),
                          validator: (v) => (v == null || v.trim().isEmpty)
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receita ou Despesa *',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Despesa'),
                              icon: Icon(Icons.arrow_circle_up_outlined),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Receita'),
                              icon: Icon(Icons.arrow_circle_down_outlined),
                            ),
                          ],
                          selected: {_receita},
                          onSelectionChanged: readOnly
                              ? null
                              : (v) => setState(() => _receita = v.first),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Classificações de Despesa ─────────────────────────────
              if (!_receita)
                SectionCard(
                  title: 'Classificações de Despesa',
                  children: [
                    if (!readOnly)
                      TextFormField(
                        controller: _despesaCtrl,
                        decoration: InputDecoration(
                            labelText: '8 dígitos (ex: 33903900)',                                
                            suffixIcon: IconButton(
                              onPressed: _addDespesa,
                              icon: const Icon(Icons.add),
                              tooltip: 'Adicionar',
                              iconSize: 18,
                            )
                          ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        onFieldSubmitted: (_) => _addDespesa(),
                      ),
                    if (_despesas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Nenhuma despesa adicionada.',
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _despesas
                            .map((d) => Chip(
                                  label: Text(d),
                                  deleteIcon: readOnly
                                      ? null
                                      : const Icon(Icons.close, size: 16),
                                  onDeleted: readOnly
                                      ? null
                                      : () =>
                                          setState(() => _despesas.remove(d)),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 16),

              // ── Fornecedor ────────────────────────────────────────────
              SectionCard(
                title: 'Fornecedor',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _niFornecedorCtrl,
                          decoration: const InputDecoration(
                              labelText: 'NI do Fornecedor (CNPJ/CPF) *'),
                          readOnly: readOnly,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _tipoPessoaFornecedor,
                          decoration: const InputDecoration(
                              labelText: 'Tipo de Pessoa *'),
                          isExpanded: true,
                          items: kTipoPessoaFornecedor.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: readOnly
                              ? null
                              : (v) =>
                                  setState(() => _tipoPessoaFornecedor = v),
                          validator: (v) =>
                              v == null ? 'Selecione o tipo de pessoa' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomeRazaoSocialFornecedorCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nome/Razão Social do Fornecedor *'),
                    readOnly: readOnly,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Subcontratado ─────────────────────────────────────────
              SectionCard(
                title: 'Subcontratado (opcional)',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _niFornecedorSubCtrl,
                          decoration: const InputDecoration(
                              labelText: 'NI do Subcontratado'),
                          readOnly: readOnly,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _tipoPessoaFornecedorSub,
                          decoration: const InputDecoration(
                              labelText: 'Tipo de Pessoa'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text('— Nenhum —')),
                            ...kTipoPessoaFornecedor.entries.map((e) =>
                                DropdownMenuItem(
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomeRazaoSocialFornecedorSubCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nome/Razão Social do Subcontratado'),
                    readOnly: readOnly,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Objeto e Valores ──────────────────────────────────────
              SectionCard(
                title: 'Objeto e Valores',
                children: [
                  _SearchableIntField(
                    items: kTipoObjetoContrato,
                    value: _tipoObjetoContrato,
                    label: 'Tipo de Objeto do Contrato *',
                    enabled: !readOnly,
                    onChanged: (v) => setState(() =>
                        _tipoObjetoContrato = v != null ? int.tryParse(v) : null),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Selecione o tipo de objeto'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _objetoContratoCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Objeto do Contrato *'),
                    readOnly: readOnly,
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _infComplementarCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Informações Complementares (opcional)'),
                    readOnly: readOnly,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _valorInicialCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Valor Inicial (R\$) *'),
                          readOnly: readOnly,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Obrigatório';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return 'Valor inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _valorGlobalCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Valor Global (R\$)'),
                          readOnly: readOnly,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _numeroParcelasCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Nº de Parcelas'),
                          readOnly: readOnly,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _valorParcelaCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Valor da Parcela (R\$)'),
                          readOnly: readOnly,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _valorAcumuladoCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Valor Acumulado (R\$)'),
                          readOnly: readOnly,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
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
                          label: 'Início da Vigência *',
                          value: _dataVigenciaInicio,
                          readOnly: readOnly,
                          onChanged: (d) => setState(() => _dataVigenciaInicio = d),
                          validator: (d) => d == null ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDatePickerField(
                          label: 'Fim da Vigência *',
                          value: _dataVigenciaFim,
                          readOnly: readOnly,
                          onChanged: (d) => setState(() => _dataVigenciaFim = d),
                          validator: (d) => d == null ? 'Obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vigenciaMesesCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Vigência em Meses (opcional)'),
                    readOnly: readOnly,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

/// Campo pesquisável para seleção de itens de um mapa `int → String`.
/// Funciona como o campo de Amparo Legal no Edital.
class _SearchableIntField extends StatelessWidget {
  final Map<int, String> items;
  final int? value;
  final String label;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String?>? validator;

  const _SearchableIntField({
    required this.items,
    required this.value,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final options = items.entries.toList();

    return Autocomplete<MapEntry<int, String>>(
      initialValue: value != null && items.containsKey(value)
          ? TextEditingValue(text: items[value]!)
          : TextEditingValue.empty,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.toLowerCase();
        if (q.isEmpty) return options;
        return options.where(
          (e) =>
              e.key.toString().contains(q) ||
              e.value.toLowerCase().contains(q),
        );
      },
      displayStringForOption: (e) => e.value,
      onSelected: (e) => onChanged(e.key.toString()),
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Digite o código ou pesquise a descrição',
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          onFieldSubmitted: (_) => onSubmitted(),
          validator: (_) => validator?.call(
            value?.toString(),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 600),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(option.value),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
