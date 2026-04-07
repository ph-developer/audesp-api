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
import 'termo_service.dart';

/// Formulário de criação/edição de Termo Aditivo de Contrato.
///
/// [termoId] null → criar novo; não-null → editar existente.
class TermoFormPage extends ConsumerStatefulWidget {
  final int ajusteId;
  final int? termoId;

  const TermoFormPage({
    super.key,
    required this.ajusteId,
    this.termoId,
  });

  @override
  ConsumerState<TermoFormPage> createState() => _TermoFormPageState();
}

class _TermoFormPageState extends ConsumerState<TermoFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  bool _isSent = false;
  int? _loadedId;

  // ── Campos ────────────────────────────────────────────────────────────
  Ajuste? _parentAjuste;
  final _codigoTermoContratoCtrl = TextEditingController();
  // tipoTermoContratoId é sempre 2 (Termo Aditivo) conforme AUDESP
  final int _tipoTermoContratoId = 2;
  final _numeroTermoContratoCtrl = TextEditingController();
  bool _retificacao = false;
  final _objetoTermoContratoCtrl = TextEditingController();
  DateTime? _dataAssinatura;

  // Qualificações (flags obrigatórias)
  bool _qualificacaoAcrescimoSupressao = false;
  bool _qualificacaoVigencia = false;
  bool _qualificacaoFornecedor = false;
  bool _qualificacaoReajuste = false;
  bool _qualificacaoInformativo = false;

  // Fornecedor
  final _niFornecedorCtrl = TextEditingController();
  String? _tipoPessoaFornecedor;
  final _nomeRazaoSocialFornecedorCtrl = TextEditingController();

  // Subcontratado
  final _niFornecedorSubCtrl = TextEditingController();
  String? _tipoPessoaFornecedorSub;
  final _nomeRazaoSocialFornecedorSubCtrl = TextEditingController();

  // Valores
  final _valorAcrescidoCtrl = TextEditingController();
  final _numeroParcelasCtrl = TextEditingController();
  final _valorParcelaCtrl = TextEditingController();
  final _valorGlobalCtrl = TextEditingController();
  final _prazoAditadoDiasCtrl = TextEditingController();
  DateTime? _dataVigenciaInicio;
  DateTime? _dataVigenciaFim;

  // Obs / Fundamento
  final _informativoObservacaoCtrl = TextEditingController();
  final _fundamentoLegalCtrl = TextEditingController();

  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _codigoTermoContratoCtrl.dispose();
    _numeroTermoContratoCtrl.dispose();
    _objetoTermoContratoCtrl.dispose();
    _niFornecedorCtrl.dispose();
    _nomeRazaoSocialFornecedorCtrl.dispose();
    _niFornecedorSubCtrl.dispose();
    _nomeRazaoSocialFornecedorSubCtrl.dispose();
    _valorAcrescidoCtrl.dispose();
    _numeroParcelasCtrl.dispose();
    _valorParcelaCtrl.dispose();
    _valorGlobalCtrl.dispose();
    _prazoAditadoDiasCtrl.dispose();
    _informativoObservacaoCtrl.dispose();
    _fundamentoLegalCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _parentAjuste =
        await ref.read(ajustesDaoProvider).findById(widget.ajusteId);

    if (widget.termoId != null) {
      await _loadExisting(widget.termoId!);
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadExisting(int id) async {
    final dao = ref.read(termosContratoDaoProvider);
    final termo = await dao.findById(id);
    if (termo == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _loadedId = termo.id;
    _isSent = termo.status == 'sent';

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(termo.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    _codigoTermoContratoCtrl.text =
        doc['codigoTermoContrato'] as String? ?? termo.codigoTermoContrato;
    _numeroTermoContratoCtrl.text =
        doc['numeroTermoContrato'] as String? ?? '';
    _retificacao = doc['retificacao'] as bool? ?? termo.retificacao;
    _objetoTermoContratoCtrl.text =
        doc['objetoTermoContrato'] as String? ?? '';

    final assinatura = doc['dataAssinatura'] as String?;
    if (assinatura != null) _dataAssinatura = DateTime.tryParse(assinatura);

    _qualificacaoAcrescimoSupressao =
        doc['qualificacaoAcrescimoSupressao'] as bool? ?? false;
    _qualificacaoVigencia = doc['qualificacaoVigencia'] as bool? ?? false;
    _qualificacaoFornecedor = doc['qualificacaoFornecedor'] as bool? ?? false;
    _qualificacaoReajuste = doc['qualificacaoReajuste'] as bool? ?? false;
    _qualificacaoInformativo =
        doc['qualificacaoInformativo'] as bool? ?? false;

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

    _valorAcrescidoCtrl.text =
        (doc['valorAcrescido'] as num?)?.toString() ?? '';
    _numeroParcelasCtrl.text =
        (doc['numeroParcelas'] as num?)?.toString() ?? '';
    _valorParcelaCtrl.text = (doc['valorParcela'] as num?)?.toString() ?? '';
    _valorGlobalCtrl.text = (doc['valorGlobal'] as num?)?.toString() ?? '';
    _prazoAditadoDiasCtrl.text =
        (doc['prazoAditadoDias'] as num?)?.toString() ?? '';

    final vigInicio = doc['dataVigenciaInicio'] as String?;
    if (vigInicio != null) {
      _dataVigenciaInicio = DateTime.tryParse(vigInicio);
    }
    final vigFim = doc['dataVigenciaFim'] as String?;
    if (vigFim != null) _dataVigenciaFim = DateTime.tryParse(vigFim);

    _informativoObservacaoCtrl.text =
        doc['informativoObservacao'] as String? ?? '';
    _fundamentoLegalCtrl.text = doc['fundamentoLegal'] as String? ?? '';

    if (mounted) setState(() => _loading = false);
  }

  // ── JSON builder ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final sessionUser = ref.read(localSessionProvider);
    final municipio = int.tryParse(sessionUser?.municipio ?? '') ?? 0;
    final entidade = int.tryParse(sessionUser?.entidade ?? '') ?? 0;
    final isoFmt = DateFormat('yyyy-MM-dd');

    final map = <String, dynamic>{
      'descritor': {
        'municipio': municipio,
        'entidade': entidade,
        'retificacao': _retificacao,
      },
      'codigoContrato': _parentAjuste?.codigoContrato ?? '',
      'codigoTermoContrato': _codigoTermoContratoCtrl.text.trim(),
      'tipoTermoContratoId': _tipoTermoContratoId,
      'numeroTermoContrato': _numeroTermoContratoCtrl.text.trim(),
      'objetoTermoContrato': _objetoTermoContratoCtrl.text.trim(),
      'dataAssinatura': _dataAssinatura != null
          ? isoFmt.format(_dataAssinatura!)
          : '',
      'qualificacaoAcrescimoSupressao': _qualificacaoAcrescimoSupressao,
      'qualificacaoVigencia': _qualificacaoVigencia,
      'qualificacaoFornecedor': _qualificacaoFornecedor,
      'qualificacaoReajuste': _qualificacaoReajuste,
      'tipoPessoaFornecedor': _tipoPessoaFornecedor,
      'nomeRazaoSocialFornecedor':
          _nomeRazaoSocialFornecedorCtrl.text.trim(),
      'valorGlobal': double.tryParse(_valorGlobalCtrl.text.trim()) ?? 0,
      'prazoAditadoDias':
          int.tryParse(_prazoAditadoDiasCtrl.text.trim()) ?? 0,
      'dataVigenciaInicio': _dataVigenciaInicio != null
          ? isoFmt.format(_dataVigenciaInicio!)
          : '',
      'dataVigenciaFim': _dataVigenciaFim != null
          ? isoFmt.format(_dataVigenciaFim!)
          : '',
    };

    if (_qualificacaoInformativo) {
      map['qualificacaoInformativo'] = true;
    }
    if (_niFornecedorCtrl.text.trim().isNotEmpty) {
      map['niFornecedor'] = _niFornecedorCtrl.text.trim();
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
    if (_qualificacaoAcrescimoSupressao &&
        _valorAcrescidoCtrl.text.trim().isNotEmpty) {
      map['valorAcrescido'] =
          double.tryParse(_valorAcrescidoCtrl.text.trim());
    }
    if (_numeroParcelasCtrl.text.trim().isNotEmpty) {
      map['numeroParcelas'] =
          int.tryParse(_numeroParcelasCtrl.text.trim());
    }
    if (_valorParcelaCtrl.text.trim().isNotEmpty) {
      map['valorParcela'] =
          double.tryParse(_valorParcelaCtrl.text.trim());
    }
    if (_informativoObservacaoCtrl.text.trim().isNotEmpty) {
      map['informativoObservacao'] =
          _informativoObservacaoCtrl.text.trim();
    }
    if (_fundamentoLegalCtrl.text.trim().isNotEmpty) {
      map['fundamentoLegal'] = _fundamentoLegalCtrl.text.trim();
    }

    return map;
  }

  // ── Salvar rascunho ───────────────────────────────────────────────────

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
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
      final dao = ref.read(termosContratoDaoProvider);
      final sessionUser = ref.read(localSessionProvider);
      final municipio = sessionUser?.municipio ?? '';
      final entidade = sessionUser?.entidade ?? '';

      if (_loadedId == null) {
        final id = await dao.insertTermo(
          TermosContratoCompanion(
            ajusteId: Value(widget.ajusteId),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoContrato:
                Value(_parentAjuste?.codigoContrato ?? ''),
            codigoTermoContrato:
                Value(_codigoTermoContratoCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            documentoJson: Value(jsonStr),
          ),
        );
        _loadedId = id;
      } else {
        await dao.updateTermo(
          TermosContratoCompanion(
            id: Value(_loadedId!),
            ajusteId: Value(widget.ajusteId),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoContrato:
                Value(_parentAjuste?.codigoContrato ?? ''),
            codigoTermoContrato:
                Value(_codigoTermoContratoCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            documentoJson: Value(jsonStr),
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

  // ── Enviar ────────────────────────────────────────────────────────────

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
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
        final service = ref.read(termoServiceProvider);
        final msg = await service.enviarTermo(
          termoId: _loadedId!,
          documentoJson: jsonStr,
          userId: user?.id,
        );
        setState(() => _isSent = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          context.go('/ajuste/${widget.ajusteId}/termo');
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

  Future<DateTime?> _pickDate(DateTime? initial, {bool limitToday = false}) =>
      showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(1970),
        lastDate:
            limitToday ? DateTime.now() : DateTime(2099),
      );

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
              ? 'Novo Termo Aditivo'
              : _isSent
                  ? 'Termo Aditivo (Enviado)'
                  : 'Editar Termo Aditivo',
        ),
        leading: BackButton(
          onPressed: () =>
              context.go('/ajuste/${widget.ajusteId}/termo'),
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
                label: const Text('Salvar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _enviar,
                icon: const Icon(Icons.send),
                label: const Text('Enviar'),
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
              // Info do contrato pai
              if (_parentAjuste != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajuste Vinculado',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contrato: ${_parentAjuste!.codigoContrato}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Edital: ${_parentAjuste!.codigoEdital}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Identificação ─────────────────────────────────────────
              _SectionHeader(title: 'Identificação'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codigoTermoContratoCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Código do Termo de Contrato *'),
                      readOnly: readOnly,
                      maxLength: 30,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _numeroTermoContratoCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Número do Termo de Contrato *'),
                      readOnly: readOnly,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Tipo do Termo de Contrato'),
                child: const Text('2 – Termo Aditivo (único permitido pelo AUDESP)'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Retificação'),
                value: _retificacao,
                onChanged: readOnly
                    ? null
                    : (v) => setState(() => _retificacao = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _objetoTermoContratoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Objeto do Termo de Contrato *'),
                readOnly: readOnly,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              _DatePickerRow(
                label: 'Data de Assinatura *',
                value: _dataAssinatura,
                fmt: _dateFmt,
                readOnly: readOnly,
                onChanged: (d) => setState(() => _dataAssinatura = d),
                pickDate: (initial) => _pickDate(initial, limitToday: true),
              ),
              const SizedBox(height: 24),

              // ── Qualificações ─────────────────────────────────────────
              _SectionHeader(title: 'Qualificações do Termo Aditivo'),
              SwitchListTile(
                title: const Text('Acréscimo / Supressão'),
                subtitle: const Text('O termo aditivo terá acréscimo/supressão de valor?'),
                value: _qualificacaoAcrescimoSupressao,
                onChanged: readOnly
                    ? null
                    : (v) => setState(
                        () => _qualificacaoAcrescimoSupressao = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Vigência / Parcelas'),
                subtitle: const Text('O termo aditivo terá alteração na vigência ou parcelas?'),
                value: _qualificacaoVigencia,
                onChanged: readOnly
                    ? null
                    : (v) =>
                        setState(() => _qualificacaoVigencia = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Alteração de Fornecedor'),
                subtitle: const Text('O termo aditivo terá alteração do fornecedor?'),
                value: _qualificacaoFornecedor,
                onChanged: readOnly
                    ? null
                    : (v) =>
                        setState(() => _qualificacaoFornecedor = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Reajuste'),
                subtitle: const Text('O termo aditivo altera o valor unitário do item?'),
                value: _qualificacaoReajuste,
                onChanged: readOnly
                    ? null
                    : (v) =>
                        setState(() => _qualificacaoReajuste = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Informativo / Observação'),
                subtitle: const Text('O termo aditivo tem observações?'),
                value: _qualificacaoInformativo,
                onChanged: readOnly
                    ? null
                    : (v) =>
                        setState(() => _qualificacaoInformativo = v),
                contentPadding: EdgeInsets.zero,
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
                          labelText: 'NI do Fornecedor (CNPJ/CPF)'),
                      readOnly: readOnly,
                      maxLength: 50,
                      validator: (v) {
                        if (_qualificacaoFornecedor &&
                            (v == null || v.trim().isEmpty)) {
                          return 'Obrigatório quando "Alteração de Fornecedor" selecionada';
                        }
                        return null;
                      },
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

              // Subcontratado
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
                          : (v) => setState(
                              () => _tipoPessoaFornecedorSub = v),
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

              // ── Valores e Vigência ────────────────────────────────────
              _SectionHeader(title: 'Valores e Vigência'),
              if (_qualificacaoAcrescimoSupressao) ...[
                TextFormField(
                  controller: _valorAcrescidoCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Valor Acrescido/Suprimido (R\$) *'),
                  readOnly: readOnly,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  validator: (v) {
                    if (_qualificacaoAcrescimoSupressao) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Obrigatório';
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Valor inválido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
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
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valorGlobalCtrl,
                decoration: const InputDecoration(
                    labelText: 'Valor Global do Termo *'),
                readOnly: readOnly,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Obrigatório';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Deve ser maior que zero';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prazoAditadoDiasCtrl,
                decoration: const InputDecoration(
                    labelText: 'Prazo Aditado (dias) *'),
                readOnly: readOnly,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Informe um prazo válido';
                  return null;
                },
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
              const SizedBox(height: 24),

              // ── Observações ───────────────────────────────────────────
              _SectionHeader(title: 'Informações Adicionais'),
              if (_qualificacaoInformativo) ...[
                TextFormField(
                  controller: _informativoObservacaoCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Observação do Termo Aditivo'),
                  readOnly: readOnly,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _fundamentoLegalCtrl,
                decoration: const InputDecoration(
                    labelText: 'Fundamento Legal (opcional)'),
                readOnly: readOnly,
                maxLines: 2,
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
