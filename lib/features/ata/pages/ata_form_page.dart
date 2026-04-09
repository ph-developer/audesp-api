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
import '../../../shared/widgets/section_card.dart';
import '../services/ata_service.dart';

/// Formulário de criação/edição de Ata (Fase 6 – Módulo 3).
///
/// [ataId] null → criar novo; não-null → editar existente.
class AtaFormPage extends ConsumerStatefulWidget {
  final int? ataId;
  final int? preselectedEditalId;
  const AtaFormPage({super.key, this.ataId, this.preselectedEditalId});

  @override
  ConsumerState<AtaFormPage> createState() => _AtaFormPageState();
}

class _AtaFormPageState extends ConsumerState<AtaFormPage> {
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
  final _codigoAtaCtrl = TextEditingController();
  final _anoCompraCtrl = TextEditingController();
  bool _retificacao = false;

  // ── Dados da Ata ───────────────────────────────────────────────────────
  final _numeroAtaCtrl = TextEditingController();
  final _anoAtaCtrl = TextEditingController();
  DateTime? _dataAssinatura;
  DateTime? _dataVigenciaInicio;
  DateTime? _dataVigenciaFim;

  // ── Itens (números dos itens da licitação) ────────────────────────────
  List<int> _numerosItem = [];
  final _itemCtrl = TextEditingController();

  // ── Date formatters ────────────────────────────────────────────────────
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
    _anoCompraCtrl.dispose();
    _numeroAtaCtrl.dispose();
    _anoAtaCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final editaisDao = ref.read(editaisDaoProvider);
    _editais = await editaisDao.watchAll().first;

    if (widget.preselectedEditalId != null) {
      _editalId = widget.preselectedEditalId;
      _fillEditalDescriptor();
    }

    if (widget.ataId != null) {
      await _loadExisting(widget.ataId!);
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
    final dao = ref.read(atasDaoProvider);
    final ata = await dao.findById(id);
    if (ata == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _loadedId = ata.id;
    _isSent = ata.status == 'sent';
    _editalId = ata.editalId;

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(ata.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    _codigoEditalCtrl.text =
        descritor['codigoEdital'] as String? ?? ata.codigoEdital;
    _codigoAtaCtrl.text =
        descritor['codigoAta'] as String? ?? ata.codigoAta;
    _retificacao = descritor['retificacao'] as bool? ?? ata.retificacao;
    _anoCompraCtrl.text =
        (descritor['anoCompra'] as int?)?.toString() ?? '';

    _numeroAtaCtrl.text = doc['numeroAtaRegistroPreco'] as String? ?? '';
    _anoAtaCtrl.text = (doc['anoAta'] as int?)?.toString() ?? '';

    final assinatura = doc['dataAssinatura'] as String?;
    if (assinatura != null) {
      _dataAssinatura = DateTime.tryParse(assinatura);
    }
    final vigInicio = doc['dataVigenciaInicio'] as String?;
    if (vigInicio != null) {
      _dataVigenciaInicio = DateTime.tryParse(vigInicio);
    }
    final vigFim = doc['dataVigenciaFim'] as String?;
    if (vigFim != null) {
      _dataVigenciaFim = DateTime.tryParse(vigFim);
    }

    _numerosItem = (doc['numeroItem'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();

    if (mounted) setState(() => _loading = false);
  }

  // ── JSON builder ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final municipio = int.tryParse(ref.read(codigoMunicipioProvider)) ?? 0;
    final entidade = int.tryParse(ref.read(codigoEntidadeProvider)) ?? 0;

    return {
      'descritor': {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': _codigoEditalCtrl.text.trim(),
        'codigoAta': _codigoAtaCtrl.text.trim(),
        'anoCompra': int.tryParse(_anoCompraCtrl.text.trim()) ?? 0,
        'retificacao': _retificacao,
      },
      'numeroItem': _numerosItem,
      'numeroAtaRegistroPreco': _numeroAtaCtrl.text.trim(),
      'anoAta': int.tryParse(_anoAtaCtrl.text.trim()) ?? 0,
      'dataAssinatura': _dataAssinatura != null
          ? DateFormat('yyyy-MM-dd').format(_dataAssinatura!)
          : '',
      'dataVigenciaInicio': _dataVigenciaInicio != null
          ? DateFormat('yyyy-MM-dd').format(_dataVigenciaInicio!)
          : '',
      'dataVigenciaFim': _dataVigenciaFim != null
          ? DateFormat('yyyy-MM-dd').format(_dataVigenciaFim!)
          : '',
    };
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
    if (_codigoAtaCtrl.text.trim().isEmpty) {
      _showError('Informe o Código da Ata para salvar o rascunho.');
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
      final dao = ref.read(atasDaoProvider);
      final municipio = ref.read(codigoMunicipioProvider);
      final entidade = ref.read(codigoEntidadeProvider);

      if (_loadedId == null) {
        final id = await dao.insertAta(
          AtasCompanion(
            editalId: Value(_editalId!),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoEdital: Value(_codigoEditalCtrl.text.trim()),
            codigoAta: Value(_codigoAtaCtrl.text.trim()),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            documentoJson: Value(jsonStr),
            updatedAt: Value(DateTime.now()),
          ),
        );
        _loadedId = id;
      } else {
        await dao.updateAta(
          AtasCompanion(
            id: Value(_loadedId!),
            editalId: Value(_editalId!),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoEdital: Value(_codigoEditalCtrl.text.trim()),
            codigoAta: Value(_codigoAtaCtrl.text.trim()),
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
    if (_numerosItem.isEmpty) {
      _showError('Informe pelo menos um número de item.');
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
        final service = ref.read(ataServiceProvider);

        final msg = await service.enviarAta(
          ataId: _loadedId!,
          documentoJson: jsonStr,
          userId: user?.id,
        );

        setState(() => _isSent = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          context.go('/ata');
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

  // ── Seletor de data ───────────────────────────────────────────────────

  Future<DateTime?> _pickDate(DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
  }

  // ── Itens ─────────────────────────────────────────────────────────────

  void _addItem() {
    final raw = _itemCtrl.text.trim();
    final num = int.tryParse(raw);
    if (num == null || num < 1) {
      _showError('Informe um número de item válido (inteiro positivo).');
      return;
    }
    if (_numerosItem.contains(num)) {
      _showError('Item $num já adicionado.');
      return;
    }
    setState(() {
      _numerosItem.add(num);
      _numerosItem.sort();
      _itemCtrl.clear();
    });
  }

  void _removeItem(int num) {
    setState(() => _numerosItem.remove(num));
  }

  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final readOnly = _isSent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _loadedId == null
              ? 'Nova Ata'
              : _isSent
                  ? 'Ata (Enviada)'
                  : 'Editar Ata',
        ),
        actions: [
          if (!readOnly) ...[
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
              SectionCard(
                title: 'Vínculo com Edital',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _editalId,
                          decoration: const InputDecoration(
                            labelText: 'Edital *',
                          ),
                          items: _editais
                              .map((e) => DropdownMenuItem(
                                    value: e.id,
                                    child: Text(
                                      '${e.codigoEdital} — Mun: ${e.municipio} / Ent: ${e.entidade}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: readOnly
                              ? null
                              : (v) {
                                  setState(() => _editalId = v);
                                  _fillEditalDescriptor();
                                },
                          validator: (v) =>
                              v == null ? 'Selecione o edital vinculado' : null,
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
                        'Município: $municipio   |   Entidade: $entidade   |   Código do Edital: ${_codigoEditalCtrl.text.isEmpty ? '-' : _codigoEditalCtrl.text}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codigoAtaCtrl,
                          readOnly: readOnly,
                          decoration: const InputDecoration(
                            labelText: 'Código da Ata *',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o código da ata'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _anoCompraCtrl,
                          readOnly: readOnly,
                          decoration: const InputDecoration(
                            labelText: 'Ano da Contratação *',
                            hintText: 'ex: 2026',
                          ),
                          keyboardType: TextInputType.number,                          
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (v) {
                            final y = int.tryParse(v ?? '');
                            if (y == null || y < 1950 || y > 2100) {
                              return 'Ano inválido (1950–2100)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Dados da Ata ─────────────────────────────────────────
              SectionCard(
                title: 'Dados da Ata',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _numeroAtaCtrl,
                          readOnly: readOnly,
                          decoration: const InputDecoration(
                            labelText: 'Número da Ata no Sistema de Origem *',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o número da ata'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: _anoAtaCtrl,
                          readOnly: readOnly,
                          decoration: const InputDecoration(
                            labelText: 'Ano da Ata *',
                            hintText: 'ex: 2026',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (v) {
                            final y = int.tryParse(v ?? '');
                            if (y == null || y < 1950 || y > 2100) {
                              return 'Ano inválido (1950–2100)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Datas ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Data de Assinatura *',
                          value: _dataAssinatura,
                          readOnly: readOnly,
                          formatter: _dateFmt,
                          onTap: () async {
                            final d = await _pickDate(_dataAssinatura);
                            if (d != null) setState(() => _dataAssinatura = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DateField(
                          label: 'Início de Vigência *',
                          value: _dataVigenciaInicio,
                          readOnly: readOnly,
                          formatter: _dateFmt,
                          onTap: () async {
                            final d = await _pickDate(_dataVigenciaInicio);
                            if (d != null) setState(() => _dataVigenciaInicio = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DateField(
                          label: 'Fim de Vigência *',
                          value: _dataVigenciaFim,
                          readOnly: readOnly,
                          formatter: _dateFmt,
                          onTap: () async {
                            final d = await _pickDate(_dataVigenciaFim);
                            if (d != null) setState(() => _dataVigenciaFim = d);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Itens ────────────────────────────────────────────────
              SectionCard(
                title: 'Itens da Licitação Referenciados',
                children: [
                  if (!readOnly)
                    TextFormField(
                      controller: _itemCtrl,
                      decoration: InputDecoration(
                        labelText: 'Número do item',
                        hintText: 'ex: 3',
                        suffixIcon: IconButton(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          tooltip: 'Adicionar',
                          iconSize: 18,
                        )
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onFieldSubmitted: (_) => _addItem(),                            
                    ),
                  if (_numerosItem.isEmpty)
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
                      children: _numerosItem
                          .map(
                            (n) => Chip(
                              label: Text('Item $n'),
                              deleteIcon: readOnly
                                  ? null
                                  : const Icon(Icons.close, size: 16),
                              onDeleted: readOnly ? null : () => _removeItem(n),
                            ),
                          )
                          .toList(),
                      ),
                    ]
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool readOnly;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.readOnly,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: readOnly ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: readOnly
              ? null
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value != null ? formatter.format(value!) : '—',
          style: value == null
              ? TextStyle(color: Theme.of(context).colorScheme.outline)
              : null,
        ),
      ),
    );
  }
}
