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

  final _dateFmt = DateFormat('dd/MM/yyyy');

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

  // ── Salvar rascunho ───────────────────────────────────────────────────

  Future<void> _saveDraft() async {
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
    if (_dataAssinatura == null ||
        _dataVigenciaInicio == null ||
        _dataVigenciaFim == null) {
      _showError('Preencha todas as datas obrigatórias.');
      return;
    }

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

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(1970),
        lastDate: DateTime(2099),
      );

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
                    width: 20,
                    height: 20,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vínculo com Edital ───────────────────────────────────
              _SectionHeader(title: 'Vínculo com Edital'),
              DropdownButtonFormField<int>(
                value: _editalId,
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
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _ataId,
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
              const SizedBox(height: 24),

              // ── Descritor ────────────────────────────────────────────
              _SectionHeader(title: 'Descritor'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codigoEditalCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Código do Edital *'),
                      readOnly: readOnly,
                      maxLength: 25,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codigoAtaCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Código da Ata (opcional)'),
                      readOnly: readOnly,
                      maxLength: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codigoContratoCtrl,
                decoration:
                    const InputDecoration(labelText: 'Código do Contrato *'),
                readOnly: readOnly,
                maxLength: 25,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Retificação'),
                subtitle: const Text('Este documento é uma retificação?'),
                value: _retificacao,
                onChanged: readOnly ? null : (v) => setState(() => _retificacao = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Adesão / Participação'),
                subtitle: const Text(
                    'Adesão ou participação em licitação gerenciada por outra entidade?'),
                value: _adesaoParticipacao,
                onChanged:
                    readOnly ? null : (v) => setState(() => _adesaoParticipacao = v),
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
                    maxLength: 14,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ],
              const SizedBox(height: 24),

              // ── Fontes de Recurso ─────────────────────────────────────
              _SectionHeader(title: 'Fontes de Recurso *'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: kFonteRecursoAjuste.entries.map((e) {
                  final selected = _fontesRecurso.contains(e.key);
                  return FilterChip(
                    label: Text(e.value),
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
              const SizedBox(height: 24),

              // ── Itens contratados ─────────────────────────────────────
              _SectionHeader(title: 'Itens Contratados *'),
              if (!readOnly)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _itemCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Número do item'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onFieldSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _addItem,
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
              if (_itens.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _itens
                      .map((n) => Chip(
                            label: Text('Item $n'),
                            onDeleted: readOnly
                                ? null
                                : () => setState(() => _itens.remove(n)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),

              // ── Dados do Contrato ─────────────────────────────────────
              _SectionHeader(title: 'Dados do Contrato'),
              DropdownButtonFormField<int>(
                value: _tipoContratoId,
                decoration:
                    const InputDecoration(labelText: 'Tipo de Contrato *'),
                isExpanded: true,
                items: kTipoContrato.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: readOnly ? null : (v) => setState(() => _tipoContratoId = v),
                validator: (v) => v == null ? 'Selecione o tipo de contrato' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _numeroContratoEmpenhoCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Número do Contrato/Empenho *'),
                      readOnly: readOnly,
                      maxLength: 50,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _anoContratoCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Ano do Contrato *'),
                      readOnly: readOnly,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              TextFormField(
                controller: _processoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Número do Processo (opcional)'),
                readOnly: readOnly,
                maxLength: 50,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _categoriaProcessoId,
                decoration:
                    const InputDecoration(labelText: 'Categoria do Processo *'),
                isExpanded: true,
                items: kCategoriaProcesso.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged:
                    readOnly ? null : (v) => setState(() => _categoriaProcessoId = v),
                validator: (v) =>
                    v == null ? 'Selecione a categoria do processo' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Receita'),
                subtitle: const Text(
                    'O processo gera receita (true) ou despesa (false) para a entidade?'),
                value: _receita,
                onChanged:
                    readOnly ? null : (v) => setState(() => _receita = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),

              // Despesas
              _SectionHeader(title: 'Classificações de Despesa'),
              if (!readOnly)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _despesaCtrl,
                        decoration: const InputDecoration(
                            labelText: '8 dígitos (ex: 33903900)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        onFieldSubmitted: (_) => _addDespesa(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _addDespesa,
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
              if (_despesas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _despesas
                      .map((d) => Chip(
                            label: Text(d),
                            onDeleted: readOnly
                                ? null
                                : () => setState(() => _despesas.remove(d)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _codigoUnidadeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Código da Unidade (PNCP — opcional)'),
                readOnly: readOnly,
                maxLength: 30,
              ),
              const SizedBox(height: 24),

              // ── Fornecedor ────────────────────────────────────────────
              _SectionHeader(title: 'Fornecedor'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _niFornecedorCtrl,
                      decoration: const InputDecoration(
                          labelText: 'NI do Fornecedor (CNPJ/CPF) *'),
                      readOnly: readOnly,
                      maxLength: 50,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tipoPessoaFornecedor,
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
                maxLength: 100,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // Subcontratado (opcional)
              _SectionHeader(title: 'Subcontratado (opcional)'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _niFornecedorSubCtrl,
                      decoration: const InputDecoration(
                          labelText: 'NI do Subcontratado'),
                      readOnly: readOnly,
                      maxLength: 50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _tipoPessoaFornecedorSub,
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
                maxLength: 100,
              ),
              const SizedBox(height: 24),

              // ── Objeto e Valores ──────────────────────────────────────
              _SectionHeader(title: 'Objeto e Valores'),
              TextFormField(
                controller: _objetoContratoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Objeto do Contrato *'),
                readOnly: readOnly,
                maxLength: 5120,
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
                maxLength: 5120,
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
              const SizedBox(height: 24),

              // ── Datas ────────────────────────────────────────────────
              _SectionHeader(title: 'Datas'),
              _DatePickerRow(
                label: 'Data de Assinatura *',
                value: _dataAssinatura,
                fmt: _dateFmt,
                readOnly: readOnly,
                onChanged: (d) => setState(() => _dataAssinatura = d),
                pickDate: _pickDate,
              ),
              const SizedBox(height: 12),
              _DatePickerRow(
                label: 'Início da Vigência *',
                value: _dataVigenciaInicio,
                fmt: _dateFmt,
                readOnly: readOnly,
                onChanged: (d) => setState(() => _dataVigenciaInicio = d),
                pickDate: _pickDate,
              ),
              const SizedBox(height: 12),
              _DatePickerRow(
                label: 'Fim da Vigência *',
                value: _dataVigenciaFim,
                fmt: _dateFmt,
                readOnly: readOnly,
                onChanged: (d) => setState(() => _dataVigenciaFim = d),
                pickDate: _pickDate,
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
              const SizedBox(height: 24),

              // ── Tipo de Objeto ────────────────────────────────────────
              _SectionHeader(title: 'Tipo de Objeto do Contrato'),
              DropdownButtonFormField<int>(
                value: _tipoObjetoContrato,
                decoration: const InputDecoration(
                    labelText: 'Tipo de Objeto do Contrato *'),
                isExpanded: true,
                items: kTipoObjetoContrato.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: readOnly
                    ? null
                    : (v) => setState(() => _tipoObjetoContrato = v),
                validator: (v) =>
                    v == null ? 'Selecione o tipo de objeto' : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat fmt;
  final bool readOnly;
  final ValueChanged<DateTime?> onChanged;
  final Future<DateTime?> Function(DateTime?) pickDate;

  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.fmt,
    required this.readOnly,
    required this.onChanged,
    required this.pickDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: readOnly
          ? null
          : () async {
              final picked = await pickDate(value);
              if (picked != null) onChanged(picked);
            },
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: readOnly ? null : const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null ? fmt.format(value!) : '—',
        ),
      ),
    );
  }
}
