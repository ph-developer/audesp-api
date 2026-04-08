import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/database/database_providers.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
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
    final sessionUser = ref.read(localSessionProvider);
    final municipio = int.tryParse(sessionUser?.municipio ?? '') ?? 0;
    final entidade = int.tryParse(sessionUser?.entidade ?? '') ?? 0;

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

  // ── Validation ────────────────────────────────────────────────

  String? _validateForm() {
    if (_editalId == null) return 'Selecione o Edital vinculado.';
    if (_codigoEditalCtrl.text.trim().isEmpty) return 'Informe o código do edital.';
    if (_codigoAtaCtrl.text.trim().isEmpty) return 'Informe o código da ata.';
    final ano = int.tryParse(_anoCompraCtrl.text.trim());
    if (ano == null || ano < 1950 || ano > 2100) {
      return 'Ano da contratação inválido (1950–2100).';
    }
    if (_numeroAtaCtrl.text.trim().isEmpty) return 'Informe o número da ata.';
    final anoAta = int.tryParse(_anoAtaCtrl.text.trim());
    if (anoAta == null || anoAta < 1950 || anoAta > 2100) {
      return 'Ano da ata inválido (1950–2100).';
    }
    if (_numerosItem.isEmpty) return 'Informe pelo menos um número de item.';
    if (_dataAssinatura == null) return 'Data de Assinatura obrigatória.';
    if (_dataVigenciaInicio == null) return 'Início de Vigência obrigatório.';
    if (_dataVigenciaFim == null) return 'Fim de Vigência obrigatório.';
    return null;
  }

  // ── Salvar rascunho ───────────────────────────────────────────────

  Future<void> _saveDraft() async {
    final err = _validateForm();
    if (err != null) {
      _showError(err);
      return;
    }

    setState(() => _saving = true);
    try {
      final doc = _buildJson();
      final jsonStr = jsonEncode(doc);
      final dao = ref.read(atasDaoProvider);
      final sessionUser = ref.read(localSessionProvider);
      final municipio = sessionUser?.municipio ?? '';
      final entidade = sessionUser?.entidade ?? '';

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

  // ── Enviar para o AUDESP ──────────────────────────────────────────────

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
        final service = ref.read(ataServiceProvider);

        final msg = await service.enviarAta(
          ataId: _loadedId!,
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
          context.go('/ata');
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
      return const ScaffoldPage(
          content: Center(child: ProgressRing()));
    }

    final readOnly = _isSent;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: PageHeader(
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.go('/ata'),
        ),
        title: Text(
          _loadedId == null
              ? 'Nova Ata'
              : _isSent
                  ? 'Ata (Enviada)'
                  : 'Editar Ata',
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
                placeholder: const Text('Selecione o Edital'),
                isExpanded: true,
                items: _editais
                    .map((e) => ComboBoxItem(
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
                      maxLength: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoLabel(
                    label: 'Código da Ata *',
                    child: TextBox(
                      controller: _codigoAtaCtrl,
                      enabled: !readOnly,
                      maxLength: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 180,
                  child: InfoLabel(
                    label: 'Ano da Contratação *',
                    child: TextBox(
                      controller: _anoCompraCtrl,
                      enabled: !readOnly,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                ToggleSwitch(
                  checked: _retificacao,
                  onChanged:
                      readOnly ? null : (v) => setState(() => _retificacao = v),
                  content: const Text('Retificação'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Dados da Ata ─────────────────────────────────────────
            SectionHeader(title: 'Dados da Ata'),
            Row(
              children: [
                Expanded(
                  child: InfoLabel(
                    label: 'Número da Ata no Sistema de Origem *',
                    child: TextBox(
                      controller: _numeroAtaCtrl,
                      enabled: !readOnly,
                      maxLength: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 180,
                  child: InfoLabel(
                    label: 'Ano da Ata *',
                    child: TextBox(
                      controller: _anoAtaCtrl,
                      enabled: !readOnly,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Datas ────────────────────────────────────────────────
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
                const SizedBox(width: 16),
                Expanded(
                  child: InfoLabel(
                    label: 'Início de Vigência *',
                    child: DatePicker(
                      selected: _dataVigenciaInicio,
                      onChanged: readOnly
                          ? null
                          : (d) => setState(() => _dataVigenciaInicio = d),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoLabel(
                    label: 'Fim de Vigência *',
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
            const SizedBox(height: 24),

            // ── Itens ────────────────────────────────────────────────
            SectionHeader(title: 'Itens da Licitação Referenciados'),
            if (!readOnly)
              Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: TextBox(
                      controller: _itemCtrl,
                      placeholder: 'ex: 3',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Button(
                    onPressed: _addItem,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(FluentIcons.add, size: 16),
                        SizedBox(width: 6),
                        Text('Adicionar Item'),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (_numerosItem.isEmpty)
              Text(
                'Nenhum item adicionado.',
                style: TextStyle(
                  color: FluentTheme.of(context).inactiveColor,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _numerosItem
                    .map(
                      (n) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FluentTheme.of(context).accentColor.lightest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Item $n'),
                            if (!readOnly) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removeItem(n),
                                child: const Icon(FluentIcons.cancel,
                                    size: 10),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
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

