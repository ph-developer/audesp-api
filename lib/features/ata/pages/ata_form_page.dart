import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/text_validation.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../features/logs/services/consulta_service.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_field_row.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_pncp_field.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_spacing.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_warning_message.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../../licitacao/domain/licitacao_referencia.dart';
import '../../processo/domain/processo.dart';
import '../../processo/domain/processo_rules.dart';
import '../../processo/processo_providers.dart';
import '../ata_providers.dart';
import '../domain/ata_rules.dart';
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
  bool _updatingStatus = false;
  int? _loadedId;
  ApiLog? _lastSendLog;

  // ── Vínculo com Edital ─────────────────────────────────────────────────
  int? _editalId;
  List<OpcaoEdital> _opcoesEdital = [];
  Set<int>? _itensLicitacao;

  Iterable<OpcaoEdital> get _opcoesVisiveis => _opcoesEdital.where(
    (o) => o.liberado || o.processo.edital.id == _editalId,
  );

  Iterable<Edital> get _editais =>
      _opcoesVisiveis.map((o) => o.processo.edital);

  String? get _motivoBloqueioEdital {
    if (_editalId == null) return null;
    final opcao = _opcoesEdital
        .where((o) => o.processo.edital.id == _editalId)
        .firstOrNull;
    return opcao == null
        ? 'O edital vinculado não foi encontrado.'
        : opcao.motivoBloqueio;
  }

  bool get _editalSemPncp =>
      _editais.where((e) => e.id == _editalId).firstOrNull?.semPncp ?? false;

  // ── Descritor ─────────────────────────────────────────────────────────
  final _codigoEditalCtrl = TextEditingController();
  final _codigoAtaCtrl = TextEditingController();
  int? _anoCompra;
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
  final _itemFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _codigoEditalCtrl.dispose();
    _codigoAtaCtrl.dispose();
    _numeroAtaCtrl.dispose();
    _anoAtaCtrl.dispose();
    _itemCtrl.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.ataId != null) {
      await _loadExisting(widget.ataId!);
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
    final processos = await ref.refresh(processosProvider.future);
    if (!mounted) return processos;
    final opcoes = ProcessoRules.opcoesAta(processos);
    final editalId = _editalId;
    if (editalId != null &&
        !opcoes.any((o) => o.processo.edital.id == editalId)) {
      final edital = await ref.read(editaisDaoProvider).findById(editalId);
      if (!mounted || editalId != _editalId) return processos;
      if (edital != null) {
        final processo =
            processos.where((p) => p.edital.id == editalId).firstOrNull ??
            Processo(edital: edital, licitacoes: [], atas: [], ajustes: []);
        opcoes.add(
          OpcaoEdital(
            processo: processo,
            motivoBloqueio: ProcessoRules.motivoBloqueioAta(processo),
          ),
        );
      }
    }
    setState(() => _opcoesEdital = opcoes);
    return processos;
  }

  Future<void> _carregarItensLicitacao() async {
    final editalId = _editalId;
    Set<int>? numeros;
    if (editalId != null) {
      try {
        final licitacoes = await ref
            .read(licitacoesDaoProvider)
            .watchByEdital(editalId);
        numeros = LicitacaoReferencia.numerosItens(licitacoes);
      } catch (_) {
        // Sem referência legível, o rascunho pode ser salvo, mas não enviado.
      }
    }
    if (!mounted || editalId != _editalId) return;
    setState(() => _itensLicitacao = numeros);
  }

  void _fillEditalDescriptor() {
    if (_editalId == null) return;
    final edital = _editais.where((e) => e.id == _editalId).firstOrNull;
    if (edital != null) {
      _codigoEditalCtrl.text = edital.codigoEdital;
      try {
        final doc = jsonDecode(edital.documentoJson) as Map<String, dynamic>;
        _anoCompra = doc['anoCompra'] as int?;
      } catch (_) {
        _anoCompra = null;
      }
    }
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
            : ProcessoRules.motivoBloqueioAta(
                    Processo(
                      edital: edital,
                      licitacoes: [],
                      atas: [],
                      ajustes: [],
                    ),
                  ) ??
                  'O edital não está disponível para criar ata.',
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
    _retificacao = edital.retificacao;
    _anoCompra = edital.anoCompra;
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
    await _carregarOpcoesEdital();
    if (!mounted) return;

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(ata.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    _codigoEditalCtrl.text =
        descritor['codigoEdital'] as String? ?? ata.codigoEdital;
    final codigoAta = descritor['codigoAta'] as String? ?? ata.codigoAta;
    _codigoAtaCtrl.text = _editalSemPncp
        ? codigoAta
        : PcnpInputFormatter.applyMask(codigoAta);
    _retificacao = descritor['retificacao'] as bool? ?? ata.retificacao;
    _fillEditalDescriptor();

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

    if (_isSent) {
      _lastSendLog = await ref
          .read(apiLogsDaoProvider)
          .findLatestAtaSendLog(
            municipio: ata.municipio,
            entidade: ata.entidade,
            codigoEdital: ata.codigoEdital,
            codigoAta: ata.codigoAta,
            retificacao: ata.retificacao,
          );
    }
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
        'codigoAta': _editalSemPncp
            ? _codigoAtaCtrl.text.trim()
            : PcnpInputFormatter.stripMask(_codigoAtaCtrl.text),
        'anoCompra': _anoCompra ?? 0,
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
      _showError(
        _editalSemPncp
            ? 'Informe o Código da Ata para salvar o rascunho.'
            : 'Informe o ID da Ata PNCP para salvar o rascunho.',
      );
      return false;
    }
    final rawAta = _editalSemPncp
        ? _codigoAtaCtrl.text.trim()
        : PcnpInputFormatter.stripMask(_codigoAtaCtrl.text);
    if (_editalSemPncp && rawAta.length > 31) {
      _showError('Máximo 31 caracteres');
      return false;
    }
    if (!_editalSemPncp && rawAta.length == 31 && _editalId != null) {
      final edital = _editais.where((e) => e.id == _editalId).firstOrNull;
      if (edital != null) {
        final editalBase = edital.idContratacaoPNCP.replaceAll(
          RegExp(r'\D'),
          '',
        );
        if (editalBase.length == 25 && rawAta.substring(0, 25) != editalBase) {
          _showError(
            'Os 25 primeiros dígitos da Ata (${PcnpInputFormatter.applyMask(rawAta.substring(0, 25))}) devem corresponder ao Edital (${PcnpInputFormatter.applyMask(editalBase)}).',
          );
          return false;
        }
      }
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
      final codigoAta = _editalSemPncp
          ? _codigoAtaCtrl.text.trim()
          : PcnpInputFormatter.stripMask(_codigoAtaCtrl.text);

      if (_loadedId == null) {
        final id = await dao.insertAta(
          editalId: _editalId!,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: _codigoEditalCtrl.text.trim(),
          codigoAta: codigoAta,
          retificacao: _retificacao,
          status: 'draft',
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
        _loadedId = id;
      } else {
        await dao.updateAta(
          id: _loadedId!,
          editalId: _editalId!,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: _codigoEditalCtrl.text.trim(),
          codigoAta: codigoAta,
          retificacao: _retificacao,
          status: 'draft',
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
      }
      ref.invalidate(atasDraftProvider);
      ref.invalidate(atasEnviadasProvider);
      ref.invalidate(processosProvider);

      if (mounted) {
        AudespSnackBar.success(context, 'Rascunho salvo com sucesso.');
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
    final editalId = _editalId;
    try {
      final processos = await _carregarOpcoesEdital();
      if (!mounted || editalId != _editalId) return;
      final processo = processos
          .where((p) => p.edital.id == editalId)
          .firstOrNull;
      final motivo = processo == null
          ? 'O edital vinculado não foi encontrado.'
          : ProcessoRules.motivoBloqueioAta(processo);
      if (motivo != null) {
        _showError(motivo);
        return;
      }
    } catch (e) {
      _showError('Não foi possível conferir as dependências do edital: $e');
      return;
    }
    await _carregarItensLicitacao();
    if (!mounted || editalId != _editalId) return;
    if (_itensLicitacao == null) {
      _showError(
        'Não foi possível conferir os itens: a licitação enviada do edital não possui itens legíveis.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_numerosItem.isEmpty) {
      _showError('Informe pelo menos um número de item.');
      return;
    }
    final erroItens = AtaRules.validarItens(
      _numerosItem,
      numerosLicitacao: _itensLicitacao,
    );
    if (erroItens != null) {
      _showError(erroItens);
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

        if (!mounted) return;
        ref.invalidate(processosProvider);
        setState(() => _isSent = true);
        if (mounted) {
          AudespSnackBar.success(context, msg);
          context.go('/ata');
        }
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    AudespSnackBar.error(context, msg);
  }

  // ── Itens ─────────────────────────────────────────────────────────────

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
    final ata = await ref.read(atasDaoProvider).findById(_loadedId!);
    if (ata == null) return;
    final log = await ref
        .read(apiLogsDaoProvider)
        .findLatestAtaSendLog(
          municipio: ata.municipio,
          entidade: ata.entidade,
          codigoEdital: ata.codigoEdital,
          codigoAta: ata.codigoAta,
          retificacao: ata.retificacao,
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
          'A ata voltara para edicao local. Os logs e o protocolo AUDESP serao mantidos.',
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
      await ref.read(atasDaoProvider).markAsDraft(_loadedId!);
      if (!mounted) return;
      ref.invalidate(atasDraftProvider);
      ref.invalidate(atasEnviadasProvider);
      ref.invalidate(processosProvider);
      if (mounted) {
        setState(() {
          _isSent = false;
          _lastSendLog = null;
        });
        AudespSnackBar.success(context, 'Ata retornada para rascunho.');
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
    final raw = _itemCtrl.text.trim();
    final num = int.tryParse(raw);
    if (num == null || num < 1) {
      _showError('Informe um número de item válido (inteiro positivo).');
      _itemFocusNode.requestFocus();
      return;
    }
    final editalId = _editalId;
    await _carregarItensLicitacao();
    if (!mounted || editalId != _editalId) return;
    if (_numerosItem.contains(num)) {
      _showError('Item $num já adicionado.');
      _itemFocusNode.requestFocus();
      return;
    }
    final erro = AtaRules.validarItens([
      num,
    ], numerosLicitacao: _itensLicitacao);
    if (erro != null) {
      _showError(erro);
      _itemFocusNode.requestFocus();
      return;
    }
    setState(() {
      _numerosItem.add(num);
      _numerosItem.sort();
      _itemCtrl.clear();
    });
    _itemFocusNode.requestFocus();
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
        leading: BackButton(onPressed: () => context.go('/ata')),
        title: Text(
          _loadedId == null
              ? 'Nova Ata'
              : _isSent
              ? 'Ata'
              : 'Editar Ata',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vínculo com Edital ───────────────────────────────────
              SectionCard(
                title: 'Vínculo com Edital',
                children: [
                  AudespFieldRow(
                    children: [
                      AudespFieldRowItem(
                        child: AudespDropdown<int>.items(
                          label: 'Edital *',
                          value: _editais.any((e) => e.id == _editalId)
                              ? _editalId
                              : null,
                          items: [
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
                          validator: (v) =>
                              v == null ? 'Selecione o edital vinculado' : null,
                        ),
                      ),
                      AudespFieldRowItem(
                        width: 200,
                        child: AudespCheckbox(
                          label: 'Retificação',
                          value: _retificacao,
                          readOnly: readOnly,
                          onChanged: (v) => setState(() => _retificacao = v),
                        ),
                      ),
                    ],
                  ),
                  if (_motivoBloqueioEdital case final motivo? when !_isSent)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AudespWarningMessage(
                        message:
                            '$motivo O rascunho pode ser salvo; o envio está bloqueado.',
                      ),
                    ),
                ],
              ),
              AudespSpacing.verticalLg,

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
                          : _editalSemPncp
                          ? _codigoEditalCtrl.text
                          : PcnpInputFormatter.applyMask(
                              _codigoEditalCtrl.text,
                            );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Município: $municipio   |   Entidade: $entidade   |   Código do Edital: $codigoEdital',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                  AudespFieldRow(
                    children: [
                      AudespFieldRowItem(
                        child: _editalSemPncp
                            ? AudespTextField(
                                label: 'Código da Ata (Sem PNCP) *',
                                controller: _codigoAtaCtrl,
                                readOnly: readOnly,
                                maxLength: 31,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o Código da Ata';
                                  }
                                  if (v.trim().length > 31) {
                                    return 'Máximo 31 caracteres';
                                  }
                                  return null;
                                },
                              )
                            : AudespPncpField(
                                label: 'ID da Ata PNCP *',
                                controller: _codigoAtaCtrl,
                                readOnly: readOnly,
                                isAta: true,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o ID da Ata PNCP';
                                  }
                                  final raw = PcnpInputFormatter.stripMask(v);
                                  if (raw.length < 31) {
                                    return 'ID da Ata PNCP incompleto (31 dígitos)';
                                  }
                                  if (_editalId != null) {
                                    final edital = _editais
                                        .where((e) => e.id == _editalId)
                                        .firstOrNull;
                                    if (edital != null) {
                                      final editalBase = edital
                                          .idContratacaoPNCP
                                          .replaceAll(RegExp(r'\D'), '');
                                      if (editalBase.length == 25 &&
                                          raw.substring(0, 25) != editalBase) {
                                        return 'Os 25 primeiros dígitos devem corresponder ao Edital (${PcnpInputFormatter.applyMask(editalBase)})';
                                      }
                                    }
                                  }
                                  return null;
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
              AudespSpacing.verticalLg,

              // ── Dados da Ata ─────────────────────────────────────────
              SectionCard(
                title: 'Dados da Ata',
                children: [
                  AudespFieldRow(
                    children: [
                      AudespFieldRowItem(
                        child: AudespTextField(
                          label: 'Número da Ata *',
                          controller: _numeroAtaCtrl,
                          readOnly: readOnly,
                          maxLength: 30,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o número da ata'
                              : validarTamanhoMaximo(v, 30),
                        ),
                      ),
                      AudespFieldRowItem(
                        width: 200,
                        child: AudespNumberField(
                          label: 'Ano da Ata *',
                          controller: _anoAtaCtrl,
                          readOnly: readOnly,
                          decimals: false,
                          maxLength: 4,
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
                  AudespSpacing.verticalLg,
                  // ── Datas ──────────────────────────────────────────
                  AudespFieldRow(
                    children: [
                      AudespFieldRowItem(
                        child: AudespDatePickerField(
                          label: 'Data de Assinatura *',
                          value: _dataAssinatura,
                          readOnly: readOnly,
                          onChanged: (d) => setState(() => _dataAssinatura = d),
                          validator: (d) => d == null ? 'Obrigatório' : null,
                        ),
                      ),
                      AudespFieldRowItem(
                        child: AudespDatePickerField(
                          label: 'Início de Vigência *',
                          value: _dataVigenciaInicio,
                          readOnly: readOnly,
                          onChanged: (d) =>
                              setState(() => _dataVigenciaInicio = d),
                          validator: (d) => d == null ? 'Obrigatório' : null,
                        ),
                      ),
                      AudespFieldRowItem(
                        child: AudespDatePickerField(
                          label: 'Fim de Vigência *',
                          value: _dataVigenciaFim,
                          readOnly: readOnly,
                          onChanged: (d) =>
                              setState(() => _dataVigenciaFim = d),
                          validator: (d) => d == null ? 'Obrigatório' : null,
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
                  if (_editalId != null && _itensLicitacao == null)
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
                      label: 'Número do item',
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
                  if (_numerosItem.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum item adicionado.',
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
                  ],
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
