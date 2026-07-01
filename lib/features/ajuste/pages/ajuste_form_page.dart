import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../features/logs/services/consulta_service.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_currency_field.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_ai_import_dialog.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_pncp_field.dart';
import '../../../shared/widgets/audesp_segmented_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../domain/ajuste_domain.dart';
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
  bool _isSent = false;
  bool _importingGemini = false;
  bool _updatingStatus = false;
  int? _loadedId;
  ApiLog? _lastSendLog;

  // ── Vínculo com Edital e Ata ──────────────────────────────────────────
  int? _editalId;
  int? _ataId;
  List<Edital> _editais = [];
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
    final editaisEnviados = await ref
        .read(editaisDaoProvider)
        .watchByStatus('sent');
    _editais = editaisEnviados.where((e) => !e.isSrp).toList();
    _atas = await ref.read(atasDaoProvider).watchByStatus('sent');

    await _selectPreselectedEdital(widget.preselectedEditalId);

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

  Future<void> _selectPreselectedEdital(int? editalId) async {
    if (editalId == null) return;
    var edital = _editais.where((e) => e.id == editalId).firstOrNull;
    if (edital == null) {
      final found = await ref.read(editaisDaoProvider).findById(editalId);
      if (found != null && found.status == 'sent' && !found.isSrp) {
        edital = found;
        _editais = [..._editais, found];
      }
    }
    if (edital == null) return;
    _editalId = edital.id;
    _codigoEditalCtrl.text = edital.codigoEdital;
  }

  bool get _isSelectedEditalAvailable {
    final id = _editalId;
    return id != null && _editais.any((e) => e.id == id);
  }

  bool get _isSelectedAtaAvailable {
    final id = _ataId;
    return id == null || _atas.any((a) => a.id == id);
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
    if (!_isSelectedEditalAvailable) _editalId = null;
    if (!_isSelectedAtaAvailable) _ataId = null;

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(ajuste.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    _codigoEditalCtrl.text =
        descritor['codigoEdital'] as String? ?? ajuste.codigoEdital;
    _codigoAtaCtrl.text = PcnpInputFormatter.applyMask(
      descritor['codigoAta'] as String? ?? ajuste.codigoAta ?? '',
    );
    _codigoContratoCtrl.text = PcnpInputFormatter.applyMask(
      descritor['codigoContrato'] as String? ?? ajuste.codigoContrato,
    );
    _retificacao = descritor['retificacao'] as bool? ?? ajuste.retificacao;
    _adesaoParticipacao = descritor['adesaoParticipacao'] as bool? ?? false;
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
      'codigoContrato': PcnpInputFormatter.stripMask(_codigoContratoCtrl.text),
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
      descritor['codigoAta'] = PcnpInputFormatter.stripMask(
        _codigoAtaCtrl.text,
      );
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
      'nomeRazaoSocialFornecedor': _nomeRazaoSocialFornecedorCtrl.text.trim(),
      'objetoContrato': _objetoContratoCtrl.text.trim(),
      'valorInicial': double.parse(
        parseBrCurrency(_valorInicialCtrl.text.trim()).toStringAsFixed(4),
      ),
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
    if (_editalId == null) {
      _showError('Selecione o Edital vinculado para salvar o rascunho.');
      return false;
    }
    if (_codigoEditalCtrl.text.trim().isEmpty) {
      _showError('Informe o Código do Edital para salvar o rascunho.');
      return false;
    }
    if (_codigoContratoCtrl.text.trim().isEmpty) {
      _showError('Informe o ID do Contrato PNCP para salvar o rascunho.');
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
          editalId: _editalId!,
          ataId: _ataId,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: _codigoEditalCtrl.text.trim(),
          codigoAta: _codigoAtaCtrl.text.trim().isNotEmpty
              ? PcnpInputFormatter.stripMask(_codigoAtaCtrl.text)
              : null,
          codigoContrato: PcnpInputFormatter.stripMask(
            _codigoContratoCtrl.text,
          ),
          retificacao: _retificacao,
          status: 'draft',
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
        _loadedId = id;
      } else {
        await dao.updateAjuste(
          id: _loadedId!,
          editalId: _editalId!,
          ataId: _ataId,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: _codigoEditalCtrl.text.trim(),
          codigoAta: _codigoAtaCtrl.text.trim().isNotEmpty
              ? PcnpInputFormatter.stripMask(_codigoAtaCtrl.text)
              : null,
          codigoContrato: PcnpInputFormatter.stripMask(
            _codigoContratoCtrl.text,
          ),
          retificacao: _retificacao,
          status: 'draft',
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
      }
      ref.invalidate(ajustesDraftProvider);
      ref.invalidate(ajustesEnviadosProvider);

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
    final isEmpenho = _tipoContratoId == 7;

    if (isEmpenho || !_receita) {
      if (_despesas.isEmpty) {
        _showError(
          'A classificação de despesa é obrigatória (exigida para despesas ou empenhos).',
        );
        return;
      }
    }
    if (isEmpenho && _despesas.length > 1) {
      _showError(
        'Para empenho (tipo 7), informe apenas uma classificação de despesa.',
      );
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
      ref.invalidate(ajustesDraftProvider);
      ref.invalidate(ajustesEnviadosProvider);
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
      final currentValues = <String, String>{
        'tipoContratoId': _tipoContratoId?.toString() ?? '',
        'numeroContratoEmpenho': _numeroContratoEmpenhoCtrl.text.trim(),
        'anoContrato': _anoContratoCtrl.text.trim(),
        'processo': _processoCtrl.text.trim(),
        'categoriaProcessoId': _categoriaProcessoId?.toString() ?? '',
        'fonteRecursosContratacao': (_fontesRecurso.toList()..sort()).join(
          ', ',
        ),
        'niFornecedor': _niFornecedorCtrl.text.trim(),
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

      final finalAccepted = accepted;
      setState(() {
        if (finalAccepted.containsKey('tipoContratoId')) {
          final match = RegExp(
            r'\d+',
          ).firstMatch(finalAccepted['tipoContratoId']!);
          if (match != null) _tipoContratoId = int.tryParse(match.group(0)!);
        }
        if (finalAccepted.containsKey('numeroContratoEmpenho')) {
          _numeroContratoEmpenhoCtrl.text =
              finalAccepted['numeroContratoEmpenho']!;
        }
        if (finalAccepted.containsKey('anoContrato')) {
          _anoContratoCtrl.text = finalAccepted['anoContrato']!;
        }
        if (finalAccepted.containsKey('processo')) {
          _processoCtrl.text = finalAccepted['processo']!;
        }
        if (finalAccepted.containsKey('niFornecedor')) {
          final ni = finalAccepted['niFornecedor']!.replaceAll(
            RegExp(r'\D'),
            '',
          );
          _niFornecedorCtrl.text = finalAccepted['niFornecedor']!;
          if (ni.length == 11) {
            _tipoPessoaFornecedor = 'PF';
          } else if (ni.length == 14) {
            _tipoPessoaFornecedor = 'PJ';
          } else if (ni.isNotEmpty) {
            _tipoPessoaFornecedor = 'PE';
          }
        }
        if (finalAccepted.containsKey('itens')) {
          final itemsRaw = finalAccepted['itens']!;
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
        if (finalAccepted.containsKey('fonteRecursosContratacao')) {
          _fontesRecurso = _parseFontesRecurso(
            finalAccepted['fonteRecursosContratacao']!,
          );
        }
        if (finalAccepted.containsKey('despesas')) {
          _despesas = _parseDespesas(finalAccepted['despesas']!);
        }
        if (finalAccepted.containsKey('categoriaProcessoId')) {
          final match = RegExp(
            r'\d+',
          ).firstMatch(finalAccepted['categoriaProcessoId']!);
          if (match != null) {
            _categoriaProcessoId = int.tryParse(match.group(0)!);
          }
        }
        if (finalAccepted.containsKey('nomeRazaoSocialFornecedor')) {
          _nomeRazaoSocialFornecedorCtrl.text =
              finalAccepted['nomeRazaoSocialFornecedor']!;
        }
        if (finalAccepted.containsKey('tipoObjetoContrato')) {
          final match = RegExp(
            r'\d+',
          ).firstMatch(finalAccepted['tipoObjetoContrato']!);
          if (match != null) {
            _tipoObjetoContrato = int.tryParse(match.group(0)!);
          }
        }
        if (finalAccepted.containsKey('objetoContrato')) {
          _objetoContratoCtrl.text = finalAccepted['objetoContrato']!;
        }
        if (finalAccepted.containsKey('valorInicial')) {
          _valorInicialCtrl.text = finalAccepted['valorInicial']!;
        }
        if (finalAccepted.containsKey('dataAssinatura')) {
          try {
            _dataAssinatura = DateFormat(
              'dd/MM/yyyy',
            ).parse(finalAccepted['dataAssinatura']!);
          } catch (_) {}
        }
        if (finalAccepted.containsKey('dataVigenciaInicio')) {
          try {
            _dataVigenciaInicio = DateFormat(
              'dd/MM/yyyy',
            ).parse(finalAccepted['dataVigenciaInicio']!);
          } catch (_) {}
        }
        if (finalAccepted.containsKey('prazoVigenciaMeses')) {
          final raw = finalAccepted['prazoVigenciaMeses']!;
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
              '${finalAccepted.length} campo(s) preenchido(s) pelo Gemini.',
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

    final readOnly = _isSent;

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
                onPressed: _importingGemini ? null : _importFromDocument,
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
                        flex: 2,
                        child: AudespDropdown<int>(
                          label: 'Edital *',
                          value: _editalId,
                          items: {
                            for (final e in _editais) e.id: e.dropdownLabel,
                          },
                          readOnly: readOnly,
                          onChanged: (v) {
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
                        flex: 1,
                        child: AudespDropdown<int?>(
                          label: 'Ata (somente para SRP)',
                          value: _ataId,
                          items: {
                            null: '— Nenhuma —',
                            for (final a in _atas) a.id: a.dropdownLabel,
                          },
                          readOnly: readOnly,
                          onChanged: (v) {
                            setState(() {
                              _ataId = v;
                              if (v != null) {
                                final ata = _atas
                                    .where((a) => a.id == v)
                                    .firstOrNull;
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
                  Builder(
                    builder: (context) {
                      final municipio = ref.watch(codigoMunicipioProvider);
                      final entidade = ref.watch(codigoEntidadeProvider);
                      if (municipio.isEmpty && entidade.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Município: $municipio   |   Entidade: $entidade   |   Código do Edital: ${_codigoEditalCtrl.text.isEmpty ? '-' : PcnpInputFormatter.applyMask(_codigoEditalCtrl.text)}   |   Código da Ata: ${_codigoAtaCtrl.text.isEmpty ? '-' : PcnpInputFormatter.applyMask(_codigoAtaCtrl.text)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AudespPncpField(
                          label: 'ID do Contrato PNCP *',
                          controller: _codigoContratoCtrl,
                          readOnly: readOnly,
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
                    onChanged: readOnly
                        ? null
                        : (v) => setState(() => _adesaoParticipacao = v),
                  ),
                  if (_adesaoParticipacao) ...[
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
                title: 'Fontes de Recurso',
                children: [
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
                title: 'Itens Contratados',
                children: [
                  if (!readOnly)
                    AudespTextField(
                      label: 'Número do item',
                      hintText: 'Ex: 1',
                      controller: _itemCtrl,
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
                      children: _itens
                          .map(
                            (n) => Chip(
                              label: Text('Item $n'),
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: AudespNumberField(
                          label: 'Ano do Contrato *',
                          controller: _anoContratoCtrl,
                          readOnly: readOnly,
                          hintText: 'Ex: 2024',
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDropdown<int>(
                          label: 'Categoria do Processo *',
                          value: _categoriaProcessoId,
                          items: kCategoriaProcesso,
                          readOnly: readOnly,
                          onChanged: (v) =>
                              setState(() => _categoriaProcessoId = v),
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
              if (!_receita)
                SectionCard(
                  title: 'Classificações de Despesa',
                  children: [
                    if (!readOnly)
                      AudespTextField(
                        label: '8 dígitos (ex: 33903900)',
                        controller: _despesaCtrl,
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AudespTextField(
                          label: 'NI do Fornecedor (CNPJ/CPF) *',
                          controller: _niFornecedorCtrl,
                          readOnly: readOnly,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Obrigatório'
                              : null,
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
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Objeto e Valores ──────────────────────────────────────
              SectionCard(
                title: 'Objeto e Valores',
                children: [
                  AudespDropdown<int>(
                    label: 'Tipo de Objeto do Contrato *',
                    value: _tipoObjetoContrato,
                    items: kTipoObjetoContrato,
                    readOnly: readOnly,
                    onChanged: (v) => setState(() => _tipoObjetoContrato = v),
                    validator: (v) =>
                        v == null ? 'Selecione o tipo de objeto' : null,
                  ),
                  const SizedBox(height: 12),
                  AudespTextField(
                    label: 'Objeto do Contrato *',
                    controller: _objetoContratoCtrl,
                    readOnly: readOnly,
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  AudespTextField(
                    label: 'Informações Complementares',
                    controller: _infComplementarCtrl,
                    readOnly: readOnly,
                    maxLines: 2,
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
                          label: 'Início da Vigência *',
                          value: _dataVigenciaInicio,
                          readOnly: readOnly,
                          onChanged: (d) =>
                              setState(() => _dataVigenciaInicio = d),
                          validator: (d) => d == null ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDatePickerField(
                          label: 'Fim da Vigência *',
                          value: _dataVigenciaFim,
                          readOnly: readOnly,
                          onChanged: (d) =>
                              setState(() => _dataVigenciaFim = d),
                          validator: (d) => d == null ? 'Obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AudespNumberField(
                    label: 'Vigência em Meses',
                    controller: _vigenciaMesesCtrl,
                    readOnly: readOnly,
                    decimals: false,
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
