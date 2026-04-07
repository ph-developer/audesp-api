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
import 'empenho_service.dart';

/// Formulário de criação/edição de Empenho de Contrato.
///
/// [empenhoId] null → criar novo; não-null → editar existente.
class EmpenhoFormPage extends ConsumerStatefulWidget {
  final int ajusteId;
  final int? empenhoId;

  const EmpenhoFormPage({
    super.key,
    required this.ajusteId,
    this.empenhoId,
  });

  @override
  ConsumerState<EmpenhoFormPage> createState() => _EmpenhoFormPageState();
}

class _EmpenhoFormPageState extends ConsumerState<EmpenhoFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  bool _isSent = false;
  int? _loadedId;

  // ── Campos ────────────────────────────────────────────────────────────
  Ajuste? _parentAjuste;
  final _numeroEmpenhoCtrl = TextEditingController();
  final _anoEmpenhoCtrl = TextEditingController();
  bool _retificacao = false;
  DateTime? _dataEmissaoEmpenho;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _numeroEmpenhoCtrl.dispose();
    _anoEmpenhoCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _parentAjuste =
        await ref.read(ajustesDaoProvider).findById(widget.ajusteId);

    if (widget.empenhoId != null) {
      await _loadExisting(widget.empenhoId!);
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadExisting(int id) async {
    final dao = ref.read(empenhosDaoProvider);
    final empenho = await dao.findById(id);
    if (empenho == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _loadedId = empenho.id;
    _isSent = empenho.status == 'sent';

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(empenho.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    _numeroEmpenhoCtrl.text =
        descritor['numeroEmpenho'] as String? ?? empenho.numeroEmpenho;
    _anoEmpenhoCtrl.text =
        (descritor['anoEmpenho'] as int?)?.toString() ??
            empenho.anoEmpenho.toString();
    _retificacao = descritor['retificacao'] as bool? ?? empenho.retificacao;

    final dataEmissao = doc['dataEmissaoEmpenho'] as String?;
    if (dataEmissao != null) {
      _dataEmissaoEmpenho = DateTime.tryParse(dataEmissao);
    }

    if (mounted) setState(() => _loading = false);
  }

  // ── JSON builder ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final sessionUser = ref.read(localSessionProvider);
    final municipio = int.tryParse(sessionUser?.municipio ?? '') ?? 0;
    final entidade = int.tryParse(sessionUser?.entidade ?? '') ?? 0;
    final isoFmt = DateFormat('yyyy-MM-dd');

    return {
      'descritor': {
        'municipio': municipio,
        'entidade': entidade,
        'numeroEmpenho': _numeroEmpenhoCtrl.text.trim(),
        'anoEmpenho': int.tryParse(_anoEmpenhoCtrl.text.trim()) ?? 0,
        'retificacao': _retificacao,
      },
      'codigoContrato': _parentAjuste?.codigoContrato ?? '',
      'dataEmissaoEmpenho': _dataEmissaoEmpenho != null
          ? isoFmt.format(_dataEmissaoEmpenho!)
          : '',
    };
  }

  // ── Salvar rascunho ───────────────────────────────────────────────────

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataEmissaoEmpenho == null) {
      _showError('Informe a data de emissão do empenho.');
      return;
    }

    setState(() => _saving = true);
    try {
      final doc = _buildJson();
      final jsonStr = jsonEncode(doc);
      final dao = ref.read(empenhosDaoProvider);
      final sessionUser = ref.read(localSessionProvider);
      final municipio = sessionUser?.municipio ?? '';
      final entidade = sessionUser?.entidade ?? '';

      if (_loadedId == null) {
        final id = await dao.insertEmpenho(
          EmpenhosCompanion(
            ajusteId: Value(widget.ajusteId),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoContrato:
                Value(_parentAjuste?.codigoContrato ?? ''),
            numeroEmpenho: Value(_numeroEmpenhoCtrl.text.trim()),
            anoEmpenho:
                Value(int.tryParse(_anoEmpenhoCtrl.text.trim()) ?? 0),
            retificacao: Value(_retificacao),
            status: const Value('draft'),
            documentoJson: Value(jsonStr),
          ),
        );
        _loadedId = id;
      } else {
        await dao.updateEmpenho(
          EmpenhosCompanion(
            id: Value(_loadedId!),
            ajusteId: Value(widget.ajusteId),
            municipio: Value(municipio),
            entidade: Value(entidade),
            codigoContrato:
                Value(_parentAjuste?.codigoContrato ?? ''),
            numeroEmpenho: Value(_numeroEmpenhoCtrl.text.trim()),
            anoEmpenho:
                Value(int.tryParse(_anoEmpenhoCtrl.text.trim()) ?? 0),
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
    if (_dataEmissaoEmpenho == null) {
      _showError('Informe a data de emissão do empenho.');
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
        final service = ref.read(empenhoServiceProvider);
        final msg = await service.enviarEmpenho(
          empenhoId: _loadedId!,
          documentoJson: jsonStr,
          userId: user?.id,
        );
        setState(() => _isSent = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          context.go('/ajuste/${widget.ajusteId}/empenho');
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
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
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
              ? 'Novo Empenho'
              : _isSent
                  ? 'Empenho (Enviado)'
                  : 'Editar Empenho',
        ),
        leading: BackButton(
          onPressed: () =>
              context.go('/ajuste/${widget.ajusteId}/empenho'),
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

              _SectionHeader(title: 'Dados do Empenho'),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _numeroEmpenhoCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Número do Empenho *'),
                      readOnly: readOnly,
                      maxLength: 35,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _anoEmpenhoCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Ano do Empenho *'),
                      readOnly: readOnly,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      maxLength: 4,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1950 || n > 2100) {
                          return 'Ano inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Retificação'),
                subtitle:
                    const Text('Este documento é uma retificação?'),
                value: _retificacao,
                onChanged: readOnly
                    ? null
                    : (v) => setState(() => _retificacao = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: readOnly
                    ? null
                    : () async {
                        final picked =
                            await _pickDate(_dataEmissaoEmpenho);
                        if (picked != null) {
                          setState(() => _dataEmissaoEmpenho = picked);
                        }
                      },
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Data de Emissão do Empenho *',
                    suffixIcon: readOnly
                        ? null
                        : const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dataEmissaoEmpenho != null
                        ? _dateFmt.format(_dataEmissaoEmpenho!)
                        : '—',
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

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
