import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
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
import '../domain/edital_domain.dart';
import '../services/edital_service.dart';
import '../widgets/edital_import_csv_dialog.dart';
import '../widgets/gemini_import_dialog.dart';
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
  final _formKey = GlobalKey<FormState>();

  // ── Carregamento ──────────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  bool _isSent = false;
  bool _importingGemini = false;
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
  final _dataAberturaCtrl = TextEditingController();
  final _dataEncerramentoCtrl = TextEditingController();
  final _amparoLegalCtrl = TextEditingController();
  final _linkSistemaCtrl = TextEditingController();
  final _justificativaCtrl = TextEditingController();

  // ── Itens de Compra ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _itens = [];

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
    _dataAberturaCtrl.dispose();
    _dataEncerramentoCtrl.dispose();
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
    _dataDoc = DateTime.tryParse(descritor['dataDocumento'] as String? ?? '');
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
    _dataAberturaCtrl.text = _toDisplayDateTime(doc['dataAberturaProposta'] as String? ?? '');
    _dataEncerramentoCtrl.text = _toDisplayDateTime(doc['dataEncerramentoProposta'] as String? ?? '');
    _amparoLegalCtrl.text = doc['amparoLegalId']?.toString() ?? '';
    _linkSistemaCtrl.text = doc['linkSistemaOrigem'] as String? ?? '';
    _justificativaCtrl.text = doc['justificativaPresencial'] as String? ?? '';
    _itens = (doc['itensCompra'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    if (mounted) setState(() => _loading = false);
  }

  // ── Build JSON ────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final municipio = int.tryParse(ref.read(codigoMunicipioProvider)) ?? 0;
    final entidade = int.tryParse(ref.read(codigoEntidadeProvider)) ?? 0;
    final map = <String, dynamic>{
      'descritor': {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': _codigoEditalCtrl.text.trim(),
        'dataDocumento': _dataDoc != null ? DateFormat('yyyy-MM-dd').format(_dataDoc!) : '',
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
    if (_dataAberturaCtrl.text.trim().isNotEmpty) {
      map['dataAberturaProposta'] = _fromDisplayDateTime(_dataAberturaCtrl.text.trim());
    }
    if (_dataEncerramentoCtrl.text.trim().isNotEmpty) {
      map['dataEncerramentoProposta'] = _fromDisplayDateTime(_dataEncerramentoCtrl.text.trim());
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

  bool _validateDraft() {
    if (_codigoEditalCtrl.text.trim().isEmpty) {
      _showError('Informe o Código do Edital para salvar o rascunho.');
      return false;
    }
    if (_dataDoc == null) {
      _showError('Informe a Data do Documento para salvar o rascunho.');
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
      final dao = ref.read(editaisDaoProvider);
      final municipio = ref.read(codigoMunicipioProvider);
      final entidade = ref.read(codigoEntidadeProvider);

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

  // ── Enviar para o AUDESP ──────────────────────────────────────────────────

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          context.go('/edital');
        }
      },
    );
  }

  // ── PDF picker ────────────────────────────────────────────────────────────

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _pdfPath = result.files.single.path);
    }
  }

  // ── Importação via Gemini ─────────────────────────────────────────────────

  Future<void> _importFromPdf() async {
    // Seleciona o PDF para análise
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    setState(() => _importingGemini = true);
    try {
      final currentValues = <String, String>{
        'codigoEdital': _codigoEditalCtrl.text.trim(),
        'dataDocumento': _dataDoc != null ? DateFormat('dd/MM/yyyy').format(_dataDoc!) : '',
        'tipoInstrumentoConvocatorioId': _tipoInstrumento?.toString() ?? '',
        'modalidadeId': _modalidade?.toString() ?? '',
        'modoDisputaId': _modoDisputa?.toString() ?? '',
        'numeroCompra': _numeroCompraCtrl.text.trim(),
        'anoCompra': _anoCompraCtrl.text.trim(),
        'numeroProcesso': _numeroProcessoCtrl.text.trim(),
        'objetoCompra': _objetoCompraCtrl.text.trim(),
        'srp': _srp.toString(),
        'amparoLegalId': _amparoLegalCtrl.text.trim(),
        'dataAberturaProposta': _dataAberturaCtrl.text.trim(),
        'dataEncerramentoProposta': _dataEncerramentoCtrl.text.trim(),
      };

      final accepted = await showGeminiImportDialog(
        context: context,
        ref: ref,
        pdfPath: result.files.single.path!,
        currentValues: currentValues,
      );

      if (!mounted || accepted == null || accepted.isEmpty) return;

      setState(() {
        if (accepted.containsKey('codigoEdital')) {
          _codigoEditalCtrl.text = accepted['codigoEdital']!;
        }
        if (accepted.containsKey('dataDocumento')) {
          try {
            _dataDoc = DateFormat('dd/MM/yyyy').parse(accepted['dataDocumento']!);
          } catch (_) {}
        }
        if (accepted.containsKey('tipoInstrumentoConvocatorioId')) {
          _tipoInstrumento =
              int.tryParse(accepted['tipoInstrumentoConvocatorioId']!);
        }
        if (accepted.containsKey('modalidadeId')) {
          _modalidade = int.tryParse(accepted['modalidadeId']!);
        }
        if (accepted.containsKey('modoDisputaId')) {
          _modoDisputa = int.tryParse(accepted['modoDisputaId']!);
        }
        if (accepted.containsKey('numeroCompra')) {
          _numeroCompraCtrl.text = accepted['numeroCompra']!;
        }
        if (accepted.containsKey('anoCompra')) {
          _anoCompraCtrl.text = accepted['anoCompra']!;
        }
        if (accepted.containsKey('numeroProcesso')) {
          _numeroProcessoCtrl.text = accepted['numeroProcesso']!;
        }
        if (accepted.containsKey('objetoCompra')) {
          _objetoCompraCtrl.text = accepted['objetoCompra']!;
        }
        if (accepted.containsKey('srp')) {
          _srp = accepted['srp']?.toLowerCase() == 'true';
        }
        if (accepted.containsKey('amparoLegalId')) {
          _amparoLegalCtrl.text = accepted['amparoLegalId']!;
        }
        if (accepted.containsKey('dataAberturaProposta')) {
          _dataAberturaCtrl.text = accepted['dataAberturaProposta']!;
        }
        if (accepted.containsKey('dataEncerramentoProposta')) {
          _dataEncerramentoCtrl.text = accepted['dataEncerramentoProposta']!;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${accepted.length} campo(s) preenchido(s) pelo Gemini.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importingGemini = false);
    }
  }

  // ── Date/datetime helpers ─────────────────────────────────────────────────

  /// `yyyy-MM-dd` → `dd/MM/yyyy` (para exibição ao usuário).
  static String _toDisplayDate(String apiDate) {
    if (apiDate.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy')
          .format(DateFormat('yyyy-MM-dd').parse(apiDate));
    } catch (_) {
      return apiDate;
    }
  }

  /// `yyyy-MM-ddTHH:mm:ss` → `dd/MM/yyyy HH:mm`.
  static String _toDisplayDateTime(String apiDt) {
    if (apiDt.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy HH:mm')
          .format(DateFormat("yyyy-MM-dd'T'HH:mm:ss").parse(apiDt));
    } catch (_) {
      return apiDt;
    }
  }

  /// `dd/MM/yyyy HH:mm` → `yyyy-MM-ddTHH:mm:ss`.
  static String _fromDisplayDateTime(String display) {
    if (display.isEmpty) return '';
    try {
      final d = DateFormat('dd/MM/yyyy HH:mm').parse(display);
      return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);
    } catch (_) {
      return display;
    }
  }

  Future<void> _pickDateTime(TextEditingController ctrl) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() => ctrl.text =
        '${DateFormat('dd/MM/yyyy').format(date)} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}');
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isNew = widget.editalId == null;
    final readonly = _isSent;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/edital')),
        title: Text(isNew ? 'Novo Edital' : 'Editar Edital'),
        actions: [
          if (!_isSent) ...[
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
                onPressed: _importingGemini ? null : _importFromPdf,
                icon: _importingGemini
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Importar do PDF'),
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
          if (_isSent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(
                label: const Text('Enviado'),
                avatar: const Icon(Icons.check_circle, size: 16),
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Formulário principal ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Seção: Descritor ──────────────────────────────────────────────────────

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
                enabled: !readonly && !_retificacao,
                decoration: const InputDecoration(
                  labelText: 'Código do Edital *',
                  hintText: 'Até 25 caracteres',
                  counterText: '',
                ),
                maxLength: 25,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(25)
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: AudespDatePickerField(
                label: 'Data do Edital *',
                value: _dataDoc,
                readOnly: readonly,
                onChanged: (d) => setState(() => _dataDoc = d),
                validator: (d) => d == null ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Retificação'),
                value: _retificacao,
                onChanged: readonly ? null : (v) => setState(() => _retificacao = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Seção: Publicidade ────────────────────────────────────────────────────

  Widget _buildPublicidadeSection(bool readonly) {
    return SectionCard(
      title: 'Publicidade',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Houve Publicação *'),
          value: _houvePublicacao,
          onChanged: readonly
              ? null
              : (v) => setState(() {
                    _houvePublicacao = v;
                    if (!v) _publicacoes.clear();
                  }),
        ),
        if (_houvePublicacao) ...[
          const SizedBox(height: 8),
          _buildPublicacoesList(readonly),
          if (!readonly)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addPublicacao,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Publicação'),
              ),
            ),
          if (_houvePublicacao && _publicacoes.isEmpty)
            Text(
              'Adicione ao menos uma publicação.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(
                kVeiculosPublicacao[_publicacoes[i]['veiculoPublicacao']] ??
                    'Veículo ${_publicacoes[i]['veiculoPublicacao']}',
              ),
              subtitle: Text(_toDisplayDate(_publicacoes[i]['dataPublicacao'] as String? ?? '')),
              trailing: readonly
                  ? null
                  : Row(
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
    return SectionCard(
      title: 'Dados Gerais',
      children: [
        // Código da Unidade Compradora (facultativo)
        TextFormField(
          controller: _codigoUnidadeCtrl,
          enabled: !readonly,
          decoration: const InputDecoration(
            labelText: 'Código da Unidade Compradora (PNCP) – facultativo',
            counterText: '',
          ),
          maxLength: 20,
        ),
        const SizedBox(height: 12),
        // Tipo de Instrumento Convocatório
        DropdownButtonFormField<int>(
          key: ValueKey('inst_$_tipoInstrumento'),
          initialValue: _tipoInstrumento,
          decoration: const InputDecoration(
              labelText: 'Tipo de Instrumento Convocatório *'),
          items: kTipoInstrumento.entries
              .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: readonly ? null : (v) => setState(() => _tipoInstrumento = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        // Modalidade
        DropdownButtonFormField<int>(
          key: ValueKey('mod_$_modalidade'),
          initialValue: _modalidade,
          decoration:
              const InputDecoration(labelText: 'Modalidade de Contratação *'),
          items: kModalidades.entries
              .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: readonly ? null : (v) => setState(() => _modalidade = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        // Modo de Disputa
        DropdownButtonFormField<int>(
          key: ValueKey('disp_$_modoDisputa'),
          initialValue: _modoDisputa,
          decoration: const InputDecoration(labelText: 'Modo de Disputa *'),
          items: kModoDisputa.entries
              .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: readonly ? null : (v) => setState(() => _modoDisputa = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _numeroCompraCtrl,
                enabled: !readonly,
                decoration: const InputDecoration(
                  labelText: 'Número da Compra *',
                  hintText: 'Ex.: 14',
                  counterText: '',
                ),
                maxLength: 50,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(50),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _anoCompraCtrl,
                enabled: !readonly,
                decoration: const InputDecoration(
                  labelText: 'Ano da Compra *',
                  hintText: 'Ex.: 2024',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final n = int.tryParse(v);
                  if (n == null || n < 1970 || n > 2099) return '1970–2099';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _numeroProcessoCtrl,
          enabled: !readonly,
          decoration: const InputDecoration(
            labelText: 'Número do Processo *',
            counterText: '',
          ),
          maxLength: 50,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _objetoCompraCtrl,
          enabled: !readonly,
          decoration: const InputDecoration(
            labelText: 'Objeto da Contratação *',
            counterText: '',
          ),
          maxLength: 5120,
          maxLines: 4,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _infComplementarCtrl,
          enabled: !readonly,
          decoration: const InputDecoration(
            labelText: 'Informações Complementares – facultativo',
            counterText: '',
          ),
          maxLength: 5120,
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('SRP – Sistema de Registro de Preços'),
          value: _srp,
          onChanged: readonly ? null : (v) => setState(() => _srp = v),
        ),
        const SizedBox(height: 12),
        // Datas de propostas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _dataAberturaCtrl,
                readOnly: true,
                enabled: !readonly,
                decoration: const InputDecoration(
                  labelText: 'Abertura de Propostas',
                  hintText: 'dd/MM/yyyy HH:mm',
                  suffixIcon: Icon(Icons.event),
                  helperText:
                      'Obrigatório para instrumento tipo 1 ou 2',
                ),
                onTap: readonly
                    ? null
                    : () => _pickDateTime(_dataAberturaCtrl),
                validator: (v) {
                  if ((_tipoInstrumento == 1 || _tipoInstrumento == 2) &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Obrigatório para instrumento tipo 1 ou 2';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dataEncerramentoCtrl,
                readOnly: true,
                enabled: !readonly,
                decoration: const InputDecoration(
                  labelText: 'Encerramento de Propostas',
                  hintText: 'dd/MM/yyyy HH:mm',
                  suffixIcon: Icon(Icons.event),
                  helperText:
                      'Obrigatório para instrumento tipo 1 ou 2',
                ),
                onTap: readonly
                    ? null
                    : () => _pickDateTime(_dataEncerramentoCtrl),
                validator: (v) {
                  if ((_tipoInstrumento == 1 || _tipoInstrumento == 2) &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Obrigatório para instrumento tipo 1 ou 2';
                  }
                  return null;
                },
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
        TextFormField(
          controller: _linkSistemaCtrl,
          enabled: !readonly,
          decoration: const InputDecoration(
            labelText: 'Link do Sistema de Origem – facultativo',
            hintText: 'https://',
            counterText: '',
          ),
          maxLength: 500,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _justificativaCtrl,
          enabled: !readonly,
          decoration: const InputDecoration(
            labelText:
                'Justificativa para Modalidade Presencial – facultativo',
            counterText: '',
          ),
          maxLength: 500,
          maxLines: 2,
        ),
      ],
    );
  }

  // ── Importação via CSV ────────────────────────────────────────────────────

  Future<void> _importItemsFromCsv() async {
    final imported = await showEditalImportCsvDialog(
      context,
      existingCount: _itens.length,
    );
    if (imported == null || imported.isEmpty) return;
    setState(() => _itens = imported);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${imported.length} item(s) importado(s) com sucesso.'),
        ),
      );
    }
  }

  // ── Seção: Itens de Compra ────────────────────────────────────────────────

  Widget _buildItensSection(bool readonly) {
    return SectionCard(
      title: 'Itens de Compra',
      titleActions: [
        if (!readonly) ...[          TextButton.icon(
              onPressed: _importItemsFromCsv,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Importar via Planilha'),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Item'),
            ),
        ],
      ],
      children: [
        if (_itens.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhum item adicionado.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        for (int i = 0; i < _itens.length; i++) _buildItemTile(i, readonly),
      ],
    );
  }

  Widget _buildItemTile(int index, bool readonly) {
    final item = _itens[index];
    final beneficio =
        kTipoBeneficio[item['tipoBeneficioId'] as int? ?? 1] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
        ),
        title: Text(
          item['descricao'] as String? ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item['materialOuServico'] == 'M' ? 'Material' : 'Serviço'}  |  '
          '$beneficio  |  '
          'Qtd: ${item['quantidade']}  |  '
          'VU: R\$ ${item['valorUnitarioEstimado']}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: readonly
            ? null
            : Row(
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
                        // Renumera
                        for (int j = 0; j < _itens.length; j++) {
                          _itens[j]['numeroItem'] = j + 1;
                        }
                      });
                    },
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
    return SectionCard(
      title: 'Arquivo PDF',
      titleActions: [
        if (!readonly) ...[
          TextButton.icon(
            onPressed: _pickPdf,
            icon: const Icon(Icons.upload_file),
            label: Text(
                _pdfPath == null ? 'Selecionar PDF' : 'Substituir PDF'),
          ),
        ],
      ],
      children: [
        if (_pdfPath != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
            title: Text(
              _pdfPath!.split(RegExp(r'[/\\]')).last,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _pdfPath!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: readonly
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _pdfPath = null),
                  ),
          )
        else
          Text(
            'Nenhum PDF selecionado.',
            style:
                TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
      ],
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

/// Campo de autocomplete para Amparo Legal (100+ valores).
class _AmparoLegalField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _AmparoLegalField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final options = kAmparosLegais.entries.toList();

    return Autocomplete<MapEntry<int, String>>(
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
      onSelected: (e) => controller.text = e.key.toString(),
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        // Sync with external controller
        if (textController.text.isEmpty && controller.text.isNotEmpty) {
          final code = int.tryParse(controller.text);
          if (code != null && kAmparosLegais.containsKey(code)) {
            textController.text = kAmparosLegais[code]!;
          } else {
            textController.text = controller.text;
          }
        }
        textController.addListener(() {
          final v = int.tryParse(textController.text);
          if (v != null) controller.text = textController.text;
        });
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Amparo Legal *',
            hintText: 'Digite o código ou pesquise a descrição',
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          onFieldSubmitted: (_) => onSubmitted(),
          validator: (_) {
            final v = int.tryParse(controller.text);
            if (v == null) return 'Obrigatório';
            if (!kAmparosLegaisValidos.contains(v)) {
              return 'Código inválido';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 260, maxWidth: 600),
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
