import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/database_providers.dart';
import '../../../features/auth/auth_providers.dart';
import '../../../features/auth/widgets/audesp_auth_dialog.dart';
import '../../../features/logs/services/consulta_service.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_chip_input.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_ai_import_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_field_row.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_spacing.dart';
import '../../../shared/widgets/status_chip.dart';
import '../csv/csv.dart';
import '../domain/licitacao_domain.dart';
import '../domain/licitacao_itens_resumo.dart';
import '../licitacao_providers.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../services/licitacao_service.dart';
import '../widgets/item_licitacao_dialog.dart';
import '../widgets/portal_import_dialog.dart';
import '../widgets/ajuste_me_epp_dialog.dart';
import '../widgets/ajuste_situacao_dialog.dart';
import '../widgets/gemini_import_dialog.dart';

/// Formulário de criação/edição de Licitação (Fase 5 – Módulo 2).
///
/// [licitacaoId] null → criar novo; não-null → editar existente.
class LicitacaoFormPage extends ConsumerStatefulWidget {
  final int? licitacaoId;
  final int? preselectedEditalId;
  const LicitacaoFormPage({
    super.key,
    this.licitacaoId,
    this.preselectedEditalId,
  });

  @override
  ConsumerState<LicitacaoFormPage> createState() => _LicitacaoFormPageState();
}

class _LicitacaoFormPageState extends ConsumerState<LicitacaoFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  bool _importingGemini = false;
  bool _isSent = false;
  bool _updatingStatus = false;
  int? _loadedId;
  ApiLog? _lastSendLog;

  // ── Vínculo com Edital ─────────────────────────────────────────────────
  int? _editalId;
  List<Edital> _editais = [];

  // ── Descritor ─────────────────────────────────────────────────────────
  final _codigoEditalCtrl = TextEditingController();
  bool _retificacao = false;

  // ── Seção BID ──────────────────────────────────────────────────────────
  int? _recursoBID;
  int? _aberturaPreQualificacaoBID;
  int? _editalPreQualificacaoBID;
  int? _julgamentoPreQualificacaoBID;
  int? _edital2FaseBID;
  int? _julgamentoPropostasBID;
  int? _julgamentoNegociacaoBID;

  // ── Dados Gerais ───────────────────────────────────────────────────────
  int? _tipoNatureza;
  int? _viabilidadeContratacao;
  int? _interposicaoRecurso;
  int? _audienciaPublica;
  int? _exigenciaGarantiaLicitantes;
  final _percentualValorCtrl = TextEditingController();
  int? _exigenciaAmostra;

  // Quitação de tributos
  bool _quitacaoFederal = false;
  bool _quitacaoEstadual = false;
  bool _quitacaoMunicipal = false;

  int? _exigenciaVisitaTecnica;
  bool _exigenciaCurriculo = false;
  bool _exigenciaVistoCREA = false;
  bool _declaracaoRecursos = false;

  // Fontes de recurso (multi-select)
  Set<int> _fontesRecurso = {};

  // Contratação conduzida por órgão externo
  bool _contratacaoConduzida = false;
  List<String> _cpfsCondutores = [];

  // Índices econômicos
  int? _exigenciaIndicesEconomicos;
  List<Map<String, dynamic>> _indicesEconomicos = [];

  // ── Itens ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _itens = [];

  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _codigoEditalCtrl.dispose();
    _percentualValorCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Carrega editais disponíveis
    final editaisDao = ref.read(editaisDaoProvider);
    _editais = await editaisDao.watchAll();

    await _selectPreselectedEdital(widget.preselectedEditalId);

    if (widget.licitacaoId != null) {
      await _loadExisting(widget.licitacaoId!);
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

  Future<void> _selectPreselectedEdital(int? editalId) async {
    if (editalId == null) return;
    var edital = _editais.where((e) => e.id == editalId).firstOrNull;
    if (edital == null) {
      final found = await ref.read(editaisDaoProvider).findById(editalId);
      if (found != null) {
        edital = found;
        _editais = [..._editais, found];
      }
    }
    if (edital == null) return;
    _editalId = edital.id;
    _codigoEditalCtrl.text = edital.codigoEdital;
    _retificacao = edital.retificacao;
  }

  bool get _isSelectedEditalSent {
    final id = _editalId;
    if (id == null) return false;
    final edital = _editais.where((e) => e.id == id).firstOrNull;
    return edital != null && edital.status == 'sent';
  }

  bool get _isSelectedEditalAvailable {
    final id = _editalId;
    return id != null && _editais.any((e) => e.id == id);
  }

  Future<void> _loadExisting(int id) async {
    final dao = ref.read(licitacoesDaoProvider);
    final licitacao = await dao.findById(id);
    if (licitacao == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _loadedId = licitacao.id;
    _isSent = licitacao.status == 'sent';
    _editalId = licitacao.editalId;
    if (!_isSelectedEditalAvailable) _editalId = null;

    Map<String, dynamic> doc = {};
    try {
      doc = jsonDecode(licitacao.documentoJson) as Map<String, dynamic>;
    } catch (_) {}

    final descritor = doc['descritor'] as Map<String, dynamic>? ?? {};
    _codigoEditalCtrl.text =
        descritor['codigoEdital'] as String? ?? licitacao.codigoEdital;
    _retificacao = descritor['retificacao'] as bool? ?? licitacao.retificacao;

    _recursoBID = doc['recursoBID'] as int?;
    _aberturaPreQualificacaoBID = doc['aberturaPreQualificacaoBID'] as int?;
    _editalPreQualificacaoBID = doc['editalPreQualificacaoBID'] as int?;
    _julgamentoPreQualificacaoBID = doc['julgamentoPreQualificacaoBID'] as int?;
    _edital2FaseBID = doc['edital2FaseBID'] as int?;
    _julgamentoPropostasBID = doc['julgamentoPropostasBID'] as int?;
    _julgamentoNegociacaoBID = doc['julgamentoNegociacaoBID'] as int?;

    _tipoNatureza = doc['tipoNatureza'] as int?;
    _viabilidadeContratacao = doc['viabilidadeContratacao'] as int?;
    _interposicaoRecurso = doc['interposicaoRecurso'] as int?;
    _audienciaPublica = doc['audienciaPublica'] as int?;
    _exigenciaGarantiaLicitantes = doc['exigenciaGarantiaLicitantes'] as int?;
    _percentualValorCtrl.text = doubleToBrString(doc['percentualValor']);
    _exigenciaAmostra = doc['exigenciaAmostra'] as int?;
    _quitacaoFederal = doc['quitacaoTributosFederais'] as bool? ?? false;
    _quitacaoEstadual = doc['quitacaoTributosEstaduais'] as bool? ?? false;
    _quitacaoMunicipal = doc['quitacaoTributosMunicipais'] as bool? ?? false;
    _exigenciaVisitaTecnica = doc['exigenciaVisitaTecnica'] as int?;
    _exigenciaCurriculo = doc['exigenciaCurriculo'] as bool? ?? false;
    _exigenciaVistoCREA = doc['exigenciaVistoCREA'] as bool? ?? false;
    _declaracaoRecursos =
        doc['declaracaoRecursosContratacao'] as bool? ?? false;

    final fontes = doc['fonteRecursosContratacao'] as List<dynamic>? ?? [];
    _fontesRecurso = fontes.map((e) => (e as num).toInt()).toSet();

    _contratacaoConduzida = doc['contratacaoConduzida'] as bool? ?? false;
    _cpfsCondutores = (doc['cpfsCondutores'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['cpfCondutor'] as String)
        .toList();

    _exigenciaIndicesEconomicos = doc['exigenciaIndicesEconomicos'] as int?;
    _indicesEconomicos = (doc['indicesEconomicos'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    _itens = (doc['itens'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (_isSent) {
      _lastSendLog = await ref
          .read(apiLogsDaoProvider)
          .findLatestLicitacaoSendLog(
            municipio: licitacao.municipio,
            entidade: licitacao.entidade,
            codigoEdital: licitacao.codigoEdital,
            retificacao: licitacao.retificacao,
          );
    }

    if (mounted) setState(() => _loading = false);
  }

  // ── JSON builder ──────────────────────────────────────────────────────

  Map<String, dynamic> _buildJson() {
    final municipio = int.tryParse(ref.read(codigoMunicipioProvider)) ?? 0;
    final entidade = int.tryParse(ref.read(codigoEntidadeProvider)) ?? 0;

    final itensLimpos = _itens.map((item) {
      final licitantes = (item['licitantes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((l) {
            final ni = l['niPessoa'] as String? ?? '';
            return {...l, 'niPessoa': ni.replaceAll(RegExp(r'\D'), '')};
          })
          .toList();
      return {...item, 'licitantes': licitantes};
    }).toList();

    final map = <String, dynamic>{
      'descritor': {
        'municipio': municipio,
        'entidade': entidade,
        'codigoEdital': _codigoEditalCtrl.text.trim(),
        'retificacao': _retificacao,
      },
      'recursoBID': _recursoBID,
      'tipoNatureza': _tipoNatureza,
      'interposicaoRecurso': _interposicaoRecurso,
      'exigenciaGarantiaLicitantes': _exigenciaGarantiaLicitantes,
      'contratacaoConduzida': _contratacaoConduzida,
      'itens': itensLimpos,
    };

    // Campos de BID (somente quando recursoBID == 1)
    if (_recursoBID == 1) {
      _setIfNonNull(
        map,
        'aberturaPreQualificacaoBID',
        _aberturaPreQualificacaoBID,
      );
      _setIfNonNull(map, 'editalPreQualificacaoBID', _editalPreQualificacaoBID);
      _setIfNonNull(
        map,
        'julgamentoPreQualificacaoBID',
        _julgamentoPreQualificacaoBID,
      );
      _setIfNonNull(map, 'edital2FaseBID', _edital2FaseBID);
      _setIfNonNull(map, 'julgamentoPropostasBID', _julgamentoPropostasBID);
      _setIfNonNull(map, 'julgamentoNegociacaoBID', _julgamentoNegociacaoBID);
    }

    _setIfNonNull(map, 'viabilidadeContratacao', _viabilidadeContratacao);
    _setIfNonNull(map, 'audienciaPublica', _audienciaPublica);
    _setIfNonNull(map, 'exigenciaAmostra', _exigenciaAmostra);
    _setIfNonNull(map, 'exigenciaVisitaTecnica', _exigenciaVisitaTecnica);
    _setIfNonNull(
      map,
      'exigenciaIndicesEconomicos',
      _exigenciaIndicesEconomicos,
    );

    final percentual = parseBrCurrencyOrNull(_percentualValorCtrl.text.trim());
    if (percentual != null && _exigenciaGarantiaLicitantes == 1) {
      map['percentualValor'] = double.parse(percentual.toStringAsFixed(4));
    }

    map['quitacaoTributosFederais'] = _quitacaoFederal;
    map['quitacaoTributosEstaduais'] = _quitacaoEstadual;
    map['quitacaoTributosMunicipais'] = _quitacaoMunicipal;
    map['exigenciaCurriculo'] = _exigenciaCurriculo;
    map['exigenciaVistoCREA'] = _exigenciaVistoCREA;
    map['declaracaoRecursosContratacao'] = _declaracaoRecursos;

    if (_fontesRecurso.isNotEmpty) {
      map['fonteRecursosContratacao'] = _fontesRecurso.toList()..sort();
    }

    if (_contratacaoConduzida && _cpfsCondutores.isNotEmpty) {
      map['cpfsCondutores'] = _cpfsCondutores
          .map((c) => {'cpfCondutor': c})
          .toList();
    }

    if (_indicesEconomicos.isNotEmpty) {
      map['indicesEconomicos'] = _indicesEconomicos;
    }

    return map;
  }

  static void _setIfNonNull(Map<String, dynamic> map, String key, dynamic val) {
    if (val != null) map[key] = val;
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
    return true;
  }

  Future<void> _saveDraft() async {
    if (!_validateDraft()) return;

    setState(() => _saving = true);
    try {
      final doc = _buildJson();
      final jsonStr = jsonEncode(doc);
      final dao = ref.read(licitacoesDaoProvider);
      final municipio = ref.read(codigoMunicipioProvider);
      final entidade = ref.read(codigoEntidadeProvider);

      if (_loadedId == null) {
        final id = await dao.insertLicitacao(
          editalId: _editalId!,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: _codigoEditalCtrl.text.trim(),
          retificacao: _retificacao,
          status: 'draft',
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
        _loadedId = id;
      } else {
        await dao.updateLicitacao(
          id: _loadedId!,
          editalId: _editalId!,
          municipio: municipio,
          entidade: entidade,
          codigoEdital: _codigoEditalCtrl.text.trim(),
          retificacao: _retificacao,
          status: 'draft',
          documentoJson: jsonStr,
          updatedAt: DateTime.now(),
        );
      }
      ref.invalidate(licitacoesDraftProvider);
      ref.invalidate(licitacoesEnviadasProvider);

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
    if (!_formKey.currentState!.validate()) return;
    if (_fontesRecurso.isEmpty) {
      _showError('Selecione ao menos uma fonte de recurso.');
      return;
    }
    if (_contratacaoConduzida && _cpfsCondutores.isEmpty) {
      _showError(
        'Informe ao menos um CPF condutor quando a contratação for conduzida.',
      );
      return;
    }
    if (_exigenciaIndicesEconomicos == 1 && _indicesEconomicos.isEmpty) {
      _showError(
        'Adicione ao menos um índice econômico quando exigência for marcada como "Sim".',
      );
      return;
    }
    if (_itens.isEmpty) {
      _showError('Adicione pelo menos um item.');
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
        final service = ref.read(licitacaoServiceProvider);

        final msg = await service.enviarLicitacao(
          licitacaoId: _loadedId!,
          documentoJson: jsonStr,
          userId: user?.id,
        );

        setState(() => _isSent = true);
        if (mounted) {
          AudespSnackBar.success(context, msg);
          context.go('/licitacao');
        }
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    AudespSnackBar.error(context, msg);
  }

  // ── Índices econômicos ────────────────────────────────────────────────

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
    final licitacao = await ref
        .read(licitacoesDaoProvider)
        .findById(_loadedId!);
    if (licitacao == null) return;
    final log = await ref
        .read(apiLogsDaoProvider)
        .findLatestLicitacaoSendLog(
          municipio: licitacao.municipio,
          entidade: licitacao.entidade,
          codigoEdital: licitacao.codigoEdital,
          retificacao: licitacao.retificacao,
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
          'A licitacao voltara para edicao local. Os logs e o protocolo AUDESP serao mantidos.',
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
      await ref.read(licitacoesDaoProvider).markAsDraft(_loadedId!);
      ref.invalidate(licitacoesDraftProvider);
      ref.invalidate(licitacoesEnviadasProvider);
      if (mounted) {
        setState(() {
          _isSent = false;
          _lastSendLog = null;
        });
        AudespSnackBar.success(context, 'Licitação retornada para rascunho.');
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

  void _addIndice() {
    _showIndiceDialog(null);
  }

  Future<void> _showIndiceDialog(int? editIndex) async {
    final initial = editIndex != null ? _indicesEconomicos[editIndex] : null;
    int? tipoIndice = initial?['tipoIndice'] as int?;
    final nomeCtrl = TextEditingController(
      text: initial?['nomeIndice'] as String? ?? '',
    );
    final valorCtrl = TextEditingController(
      text: doubleToBrString(initial?['valorIndice']),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(editIndex == null ? 'Adicionar Índice' : 'Editar Índice'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AudespDropdown<int>(
                  label: 'Tipo *',
                  value: tipoIndice,
                  items: kTipoIndice,
                  onChanged: (v) => setS(() => tipoIndice = v),
                ),
                const SizedBox(height: 12),
                if (tipoIndice == 8)
                  AudespTextField(
                    label: 'Nome do Índice (3–50 caracteres)',
                    controller: nomeCtrl,
                    maxLength: 50,
                  ),
                const SizedBox(height: 12),
                AudespNumberField(label: 'Índice *', controller: valorCtrl),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && tipoIndice != null) {
      final valor = parseBrCurrencyOrNull(valorCtrl.text.trim());
      if (valor == null) return;
      final entry = <String, dynamic>{
        'tipoIndice': tipoIndice,
        'valorIndice': double.parse(valor.toStringAsFixed(4)),
      };
      if (tipoIndice == 8 && nomeCtrl.text.trim().length >= 3) {
        entry['nomeIndice'] = nomeCtrl.text.trim();
      }
      setState(() {
        if (editIndex == null) {
          _indicesEconomicos.add(entry);
        } else {
          _indicesEconomicos[editIndex] = entry;
        }
      });
    }

    nomeCtrl.dispose();
    valorCtrl.dispose();
  }

  // ── Importação de Portal / Arquivos ──────────────────────────────────────

  Future<void> _openPortalImportDialog() async {
    if (_itens.isNotEmpty) {
      final limpar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Substituir itens?'),
          content: const Text(
            'Já existem itens no formulário. Deseja substituí-los pelos itens importados?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Substituir'),
            ),
          ],
        ),
      );
      if (limpar != true) return;
    }

    if (!mounted) return;
    final csvItens = await showPortalImportDialog(context);
    if (csvItens == null || !mounted) return;

    final novosItens = csvItens.map(_csvItemToMap).toList();

    setState(() {
      _itens = novosItens;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Itens importados com sucesso! Verifique os enquadramentos de '
            'ME/EPP dos licitantes, pois os portais não os diferenciam.',
          ),
          duration: Duration(seconds: 8),
        ),
      );
    }
  }

  // ── Importação via IA (Gemini) ─────────────────────────────────────────

  Future<void> _importFromDocument() async {
    final geminiService = ref.read(geminiServiceProvider);
    final prompt = geminiService.generatePromptFromFields(
      kLicitacaoGeminiFields,
    );

    final result = await showAudespAiImportDialog(
      context,
      title: 'Importar Licitação via IA',
      promptText: prompt,
    );

    if (result == null || !mounted) return;

    setState(() => _importingGemini = true);
    try {
      final currentValues = <String, String>{
        'tipoNatureza': _tipoNatureza?.toString() ?? '',
        'exigenciaAmostra': _exigenciaAmostra?.toString() ?? '',
        'exigenciaCurriculo': _exigenciaCurriculo.toString(),
        'exigenciaVistoCREA': _exigenciaVistoCREA.toString(),
        'exigenciaVisitaTecnica': _exigenciaVisitaTecnica?.toString() ?? '',
        'exigenciaGarantiaLicitantes':
            _exigenciaGarantiaLicitantes?.toString() ?? '',
        'percentualGarantia': _percentualValorCtrl.text.trim(),
        'quitacaoTributosFederais': _quitacaoFederal.toString(),
        'quitacaoTributosEstaduais': _quitacaoEstadual.toString(),
        'quitacaoTributosMunicipais': _quitacaoMunicipal.toString(),
        'fonteRecursosContratacao': _fontesRecurso.isNotEmpty
            ? _fontesRecurso.map((e) => e.toString()).join(', ')
            : '',
        'exigenciaIndicesEconomicos':
            _exigenciaIndicesEconomicos?.toString() ?? '',
        'indicesEconomicos': _indicesEconomicos.isNotEmpty
            ? jsonEncode(_indicesEconomicos)
            : '',
        'recursoBID': _recursoBID?.toString() ?? '',
        'audienciaPublica': _audienciaPublica?.toString() ?? '',
      };

      Map<String, String>? accepted;

      if (result.mode == AiImportMode.manual) {
        if (result.jsonResponse == null || result.jsonResponse!.isEmpty) return;
        final parsed = geminiService.parseResult(
          result.jsonResponse!,
          kLicitacaoGeminiFields,
        );
        accepted = await showGeminiReviewDialog(
          context: context,
          currentValues: currentValues,
          suggestedValues: parsed,
        );
      } else {
        if (result.filePath == null) return;
        accepted = await showGeminiImportDialog(
          context: context,
          ref: ref,
          pdfPath: result.filePath!,
          currentValues: currentValues,
        );
      }

      if (!mounted || accepted == null || accepted.isEmpty) return;

      final finalAccepted = accepted;
      setState(() {
        if (finalAccepted.containsKey('tipoNatureza')) {
          _tipoNatureza = int.tryParse(finalAccepted['tipoNatureza']!);
        }
        if (finalAccepted.containsKey('exigenciaAmostra')) {
          _exigenciaAmostra = int.tryParse(finalAccepted['exigenciaAmostra']!);
        }
        if (finalAccepted.containsKey('exigenciaCurriculo')) {
          _exigenciaCurriculo = [
            'true',
            'sim',
          ].contains(finalAccepted['exigenciaCurriculo']?.toLowerCase());
        }
        if (finalAccepted.containsKey('exigenciaVistoCREA')) {
          _exigenciaVistoCREA = [
            'true',
            'sim',
          ].contains(finalAccepted['exigenciaVistoCREA']?.toLowerCase());
        }
        if (finalAccepted.containsKey('exigenciaVisitaTecnica')) {
          _exigenciaVisitaTecnica = int.tryParse(
            finalAccepted['exigenciaVisitaTecnica']!,
          );
        }
        if (finalAccepted.containsKey('exigenciaGarantiaLicitantes')) {
          _exigenciaGarantiaLicitantes = int.tryParse(
            finalAccepted['exigenciaGarantiaLicitantes']!,
          );
        }
        if (finalAccepted.containsKey('percentualGarantia')) {
          _percentualValorCtrl.text = finalAccepted['percentualGarantia']!;
        }
        if (finalAccepted.containsKey('quitacaoTributosFederais')) {
          _quitacaoFederal = [
            'true',
            'sim',
          ].contains(finalAccepted['quitacaoTributosFederais']?.toLowerCase());
        }
        if (finalAccepted.containsKey('quitacaoTributosEstaduais')) {
          _quitacaoEstadual = [
            'true',
            'sim',
          ].contains(finalAccepted['quitacaoTributosEstaduais']?.toLowerCase());
        }
        if (finalAccepted.containsKey('quitacaoTributosMunicipais')) {
          _quitacaoMunicipal = ['true', 'sim'].contains(
            finalAccepted['quitacaoTributosMunicipais']?.toLowerCase(),
          );
        }
        if (finalAccepted.containsKey('fonteRecursosContratacao')) {
          final raw = finalAccepted['fonteRecursosContratacao']!;
          Set<int> parsed;
          if (raw.trim().startsWith('[')) {
            try {
              final list = jsonDecode(raw) as List;
              parsed = list
                  .map(
                    (e) => (e is num) ? e.toInt() : int.tryParse(e.toString()),
                  )
                  .whereType<int>()
                  .toSet();
            } catch (_) {
              parsed = {};
            }
          } else {
            parsed = raw
                .split(',')
                .map((s) => int.tryParse(s.trim()))
                .whereType<int>()
                .toSet();
          }
          if (parsed.isNotEmpty) _fontesRecurso = parsed;
        }
        if (finalAccepted.containsKey('exigenciaIndicesEconomicos')) {
          _exigenciaIndicesEconomicos = int.tryParse(
            finalAccepted['exigenciaIndicesEconomicos']!,
          );
        }
        if (finalAccepted.containsKey('indicesEconomicos')) {
          try {
            final parsed =
                jsonDecode(finalAccepted['indicesEconomicos']!) as List;
            _indicesEconomicos = parsed
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } catch (_) {}
        }
        if (finalAccepted.containsKey('recursoBID')) {
          _recursoBID = int.tryParse(finalAccepted['recursoBID']!);
        }
        if (finalAccepted.containsKey('audienciaPublica')) {
          _audienciaPublica = int.tryParse(finalAccepted['audienciaPublica']!);
        }
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

  static Map<String, dynamic> _csvItemToMap(LicitacaoItemCsvModel item) {
    final map = <String, dynamic>{
      'numeroItem': item.numeroItem,
      'situacaoCompraItemId': item.situacaoCompraItemId,
      'licitantes': item.licitantes.map(_csvLicitanteToMap).toList(),
    };
    if (item.tipoOrcamento != null) map['tipoOrcamento'] = item.tipoOrcamento;
    final valorEstimado = item.valorEstimado;
    if (valorEstimado != null) {
      map['valor'] = double.parse(valorEstimado.toStringAsFixed(4));
    }
    if (item.dataOrcamento != null) map['dataOrcamento'] = item.dataOrcamento;
    if (item.dataSituacao != null) map['dataSituacaoItem'] = item.dataSituacao;
    if (item.tipoValor != null) map['tipoValor'] = item.tipoValor;
    if (item.tipoProposta != null) map['tipoProposta'] = item.tipoProposta;
    return map;
  }

  static Map<String, dynamic> _csvLicitanteToMap(LicitanteCsvModel l) {
    final map = <String, dynamic>{
      'tipoPessoaId': l.tipoPessoaId,
      'niPessoa': l.niPessoa,
      'declaracaoMEouEPP': l.declaracaoMEouEPP,
      'resultadoHabilitacao': l.resultadoHabilitacao,
    };
    if (l.nomeRazaoSocial.isNotEmpty) {
      map['nomeRazaoSocial'] = l.nomeRazaoSocial;
    }
    if (l.valorProposta != 0) {
      map['valor'] = double.parse(l.valorProposta.toStringAsFixed(4));
    }
    return map;
  }

  // ── CPFs condutores ────────────────────────────────────────────────────

  // ── Ajuste ME/EPP em lote ─────────────────────────────────────────────

  bool get _temLicitante => _itens.any(
    (item) => (item['licitantes'] as List<dynamic>? ?? []).isNotEmpty,
  );

  Future<void> _abrirAjusteMeEpp() async {
    // Extrai licitantes únicos (por niPessoa), preservando status atual.
    final unicos = <String, Map<String, dynamic>>{};
    for (final item in _itens) {
      for (final l
          in (item['licitantes'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()) {
        final ni = l['niPessoa'] as String? ?? '';
        if (ni.isEmpty) continue;
        unicos.putIfAbsent(ni, () => Map<String, dynamic>.from(l));
      }
    }

    if (unicos.isEmpty || !mounted) return;

    final resultado = await showAjusteMeEppDialog(context, unicos);
    if (resultado == null || !mounted) return;

    // Aplica o status atualizado em cascata em todos os itens/licitantes.
    setState(() {
      _itens = _itens.map((item) {
        final licitantes = (item['licitantes'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((l) {
              final ni = l['niPessoa'] as String? ?? '';
              final novoStatus = resultado[ni];
              if (novoStatus == null) return l;
              return {...l, 'declaracaoMEouEPP': novoStatus};
            })
            .toList();
        return {...item, 'licitantes': licitantes};
      }).toList();
    });
  }

  Future<void> _abrirAjusteSituacao() async {
    if (_itens.isEmpty || !mounted) return;

    final novosItens = await showAjusteSituacaoDialog(context, _itens);
    if (novosItens != null && mounted) {
      setState(() {
        _itens = novosItens;
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final readOnly = _isSent;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/licitacao')),
        title: Text(
          _loadedId == null
              ? 'Nova Licitação'
              : _isSent
              ? 'Licitação'
              : 'Editar Licitação',
        ),
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
            else if (_importingGemini)
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
                onPressed: _importFromDocument,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Importar via IA'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _saveDraft,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar Rascunho'),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: _editalId != null && !_isSelectedEditalSent
                    ? 'Edital ainda não enviado à AUDESP'
                    : 'Enviar à AUDESP',
                child: FilledButton.icon(
                  onPressed: (!_isSelectedEditalSent) ? null : _enviar,
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar à AUDESP'),
                ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEditalSection(readOnly),
              const SizedBox(height: 16),
              _buildDescritorSection(readOnly),
              const SizedBox(height: 16),
              _buildBidSection(readOnly),
              const SizedBox(height: 16),
              _buildDadosGeraisSection(readOnly),
              const SizedBox(height: 16),
              _buildGarantiaSection(readOnly),
              const SizedBox(height: 16),
              _buildQuitacaoSection(readOnly),
              const SizedBox(height: 16),
              _buildFontesRecursoSection(readOnly),
              const SizedBox(height: 16),
              _buildContratacaoConduzidaSection(readOnly),
              const SizedBox(height: 16),
              _buildIndicesEconomicosSection(readOnly),
              const SizedBox(height: 16),
              if (_itens.isNotEmpty) ...[
                _buildItensResumo(LicitacaoItensResumo.calcular(_itens)),
                const SizedBox(height: 16),
              ],
              _buildItensSection(readOnly),
            ],
          ),
        ),
      ),
    );
  }

  // ── Seções ─────────────────────────────────────────────────────────────

  Widget _buildEditalSection(bool readOnly) {
    return SectionCard(
      title: 'Edital Vinculado',
      children: [
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Edital *',
                value: _editalId,
                items: {for (final e in _editais) e.id: e.dropdownLabel},
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
      ],
    );
  }

  Widget _buildDescritorSection(bool readOnly) {
    final municipio = ref.watch(codigoMunicipioProvider);
    final entidade = ref.watch(codigoEntidadeProvider);
    return SectionCard(
      title: 'Descritor',
      children: [
        if (municipio.isNotEmpty || entidade.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Município: $municipio   |   Entidade: $entidade   |   Código do Edital: ${_codigoEditalCtrl.text.isEmpty ? '-' : PcnpInputFormatter.applyMask(_codigoEditalCtrl.text)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _buildBidSection(bool readOnly) {
    return SectionCard(
      title: 'Recursos BID',
      children: [
        AudespDropdown<int>(
          label: 'Recurso BID *',
          value: _recursoBID,
          items: kRecursoBID,
          readOnly: readOnly,
          onChanged: (v) => setState(() => _recursoBID = v),
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
        if (_recursoBID == 1) ...[
          AudespSpacing.verticalMd,
          const Text(
            'Fases BID (preencha conforme aplicável):',
            style: TextStyle(fontSize: 12),
          ),
          AudespSpacing.verticalSm,
          AudespFieldRow(
            children: [
              AudespFieldRowItem(
                child: AudespDropdown<int>(
                  label: 'Abertura Pré-Qualificação',
                  value: _aberturaPreQualificacaoBID,
                  items: kTriState,
                  readOnly: readOnly,
                  onChanged: (v) =>
                      setState(() => _aberturaPreQualificacaoBID = v),
                ),
              ),
              AudespFieldRowItem(
                child: AudespDropdown<int>(
                  label: 'Edital Pré-Qualificação',
                  value: _editalPreQualificacaoBID,
                  items: kTriState,
                  readOnly: readOnly,
                  onChanged: (v) =>
                      setState(() => _editalPreQualificacaoBID = v),
                ),
              ),
              AudespFieldRowItem(
                child: AudespDropdown<int>(
                  label: 'Julgamento Pré-Qualificação',
                  value: _julgamentoPreQualificacaoBID,
                  items: kTriState,
                  readOnly: readOnly,
                  onChanged: (v) =>
                      setState(() => _julgamentoPreQualificacaoBID = v),
                ),
              ),
            ],
          ),
          AudespSpacing.verticalSm,
          AudespFieldRow(
            children: [
              AudespFieldRowItem(
                child: AudespDropdown<int>(
                  label: 'Edital 2ª Fase',
                  value: _edital2FaseBID,
                  items: kTriState,
                  readOnly: readOnly,
                  onChanged: (v) => setState(() => _edital2FaseBID = v),
                ),
              ),
              AudespFieldRowItem(
                child: AudespDropdown<int>(
                  label: 'Julgamento de Propostas',
                  value: _julgamentoPropostasBID,
                  items: kTriState,
                  readOnly: readOnly,
                  onChanged: (v) => setState(() => _julgamentoPropostasBID = v),
                ),
              ),
              AudespFieldRowItem(
                child: AudespDropdown<int>(
                  label: 'Julgamento/Negociação',
                  value: _julgamentoNegociacaoBID,
                  items: kTriState,
                  readOnly: readOnly,
                  onChanged: (v) =>
                      setState(() => _julgamentoNegociacaoBID = v),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDadosGeraisSection(bool readOnly) {
    return SectionCard(
      title: 'Dados Gerais',
      children: [
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Tipo de Natureza *',
                value: _tipoNatureza,
                items: kTipoNatureza,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _tipoNatureza = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
            ),
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Viabilidade de Contratação',
                value: _viabilidadeContratacao,
                items: kTriState,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _viabilidadeContratacao = v),
              ),
            ),
          ],
        ),
        AudespSpacing.verticalMd,
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Interposição de Recurso *',
                value: _interposicaoRecurso,
                items: kTriState,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _interposicaoRecurso = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
            ),
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Audiência Pública',
                value: _audienciaPublica,
                items: kTriState,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _audienciaPublica = v),
              ),
            ),
          ],
        ),
        AudespSpacing.verticalMd,
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Exigência de Amostra',
                value: _exigenciaAmostra,
                items: kExigenciaAmostra,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _exigenciaAmostra = v),
              ),
            ),
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Exigência de Visita Técnica',
                value: _exigenciaVisitaTecnica,
                items: kExigenciaVisitaTecnica,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _exigenciaVisitaTecnica = v),
              ),
            ),
          ],
        ),
        AudespSpacing.verticalMd,
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespCheckbox(
                label: 'Exige Currículo',
                value: _exigenciaCurriculo,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _exigenciaCurriculo = v),
              ),
            ),
            AudespFieldRowItem(
              child: AudespCheckbox(
                label: 'Exige Visto CREA',
                value: _exigenciaVistoCREA,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _exigenciaVistoCREA = v),
              ),
            ),
            AudespFieldRowItem(
              child: AudespCheckbox(
                label: 'Declaração de Recursos',
                value: _declaracaoRecursos,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _declaracaoRecursos = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGarantiaSection(bool readOnly) {
    return SectionCard(
      title: 'Garantia de Licitantes',
      children: [
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Exigência de Garantia *',
                value: _exigenciaGarantiaLicitantes,
                items: kTriState,
                readOnly: readOnly,
                onChanged: (v) =>
                    setState(() => _exigenciaGarantiaLicitantes = v),
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
            ),
            AudespFieldRowItem(
              child: AudespNumberField(
                label: 'Percentual (%)',
                controller: _percentualValorCtrl,
                enabled: !readOnly && _exigenciaGarantiaLicitantes == 1,
                hintText: '0 a 100',
                maxLength: 3,
                validator: (v) {
                  if (_exigenciaGarantiaLicitantes != 1) return null;
                  if (v == null || v.trim().isEmpty) return null;
                  final d = parseBrCurrencyOrNull(v.trim());
                  if (d == null || d < 0 || d > 100) {
                    return 'Valor entre 0 e 100';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuitacaoSection(bool readOnly) {
    return SectionCard(
      title: 'Quitação de Tributos',
      children: [
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespCheckbox(
                label: 'Tributos Federais',
                value: _quitacaoFederal,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _quitacaoFederal = v),
              ),
            ),
            AudespFieldRowItem(
              child: AudespCheckbox(
                label: 'Tributos Estaduais',
                value: _quitacaoEstadual,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _quitacaoEstadual = v),
              ),
            ),
            AudespFieldRowItem(
              child: AudespCheckbox(
                label: 'Tributos Municipais',
                value: _quitacaoMunicipal,
                readOnly: readOnly,
                onChanged: (v) => setState(() => _quitacaoMunicipal = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontesRecursoSection(bool readOnly) {
    return SectionCard(
      title: 'Fontes de Recurso',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: kFonteRecurso.entries.map((e) {
            final selected = _fontesRecurso.contains(e.key);
            return FilterChip(
              label: Text(e.value, style: const TextStyle(fontSize: 11)),
              selected: selected,
              onSelected: readOnly
                  ? null
                  : (v) => setState(() {
                      if (v) {
                        _fontesRecurso.add(e.key);
                      } else {
                        _fontesRecurso.remove(e.key);
                      }
                    }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContratacaoConduzidaSection(bool readOnly) {
    return SectionCard(
      title: 'Contratação Conduzida',
      children: [
        AudespCheckbox(
          label: 'Contratação Conduzida por Órgão Externo',
          value: _contratacaoConduzida,
          readOnly: readOnly,
          onChanged: (v) => setState(() => _contratacaoConduzida = v),
        ),
        if (_contratacaoConduzida) ...[
          const SizedBox(height: 12),
          AudespChipInput<String>(
            label: 'CPF do Condutor (11 dígitos)',
            hintText: '00000000000',
            chips: _cpfsCondutores,
            onAdd: (cpf) => setState(() => _cpfsCondutores.add(cpf)),
            onRemove: (cpf) => setState(() => _cpfsCondutores.remove(cpf)),
            maxLength: 11,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            validateInput: (cpf) {
              if (cpf == null || cpf.length != 11) {
                return 'CPF deve conter 11 dígitos';
              }
              if (_cpfsCondutores.contains(cpf)) return 'CPF já adicionado';
              return null;
            },
            formatChip: (cpf) => cpf,
            readOnly: readOnly,
          ),
        ],
      ],
    );
  }

  Widget _buildIndicesEconomicosSection(bool readOnly) {
    return SectionCard(
      title: 'Índices Econômicos',
      children: [
        AudespDropdown<int>(
          label: 'Exigência de Índices Econômicos',
          value: _exigenciaIndicesEconomicos,
          items: kTriState,
          readOnly: readOnly,
          onChanged: (v) => setState(() => _exigenciaIndicesEconomicos = v),
        ),
        if (_exigenciaIndicesEconomicos == 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Índices (${_indicesEconomicos.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (!readOnly)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar'),
                  onPressed: _addIndice,
                ),
            ],
          ),
          ..._indicesEconomicos.asMap().entries.map((entry) {
            final i = entry.key;
            final idx = entry.value;
            return Card(
              margin: const EdgeInsets.only(top: 4),
              child: ListTile(
                dense: true,
                title: Text(kTipoIndice[idx['tipoIndice']] ?? ''),
                subtitle: Text(
                  '${idx['nomeIndice'] != null ? '${idx['nomeIndice']}  ' : ''}Índice: ${formatNumberBR((idx['valorIndice'] as num?)?.toDouble())}',
                ),
                trailing: readOnly
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AudespIconButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'Editar índice',
                            onPressed: () => _showIndiceDialog(i),
                          ),
                          AudespIconButton(
                            icon: Icons.delete_outline,
                            tooltip: 'Excluir índice',
                            onPressed: () =>
                                setState(() => _indicesEconomicos.removeAt(i)),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildItensSection(bool readOnly) {
    return SectionCard(
      title: 'Itens de Licitação',
      titleActions: [
        if (!readOnly) ...[
          TextButton.icon(
            onPressed: _openPortalImportDialog,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Importar'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: (_itens.isNotEmpty && _temLicitante)
                ? _abrirAjusteMeEpp
                : null,
            icon: const Icon(Icons.tune_outlined, size: 18),
            label: const Text('Ajustar ME/EPP'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _itens.isNotEmpty ? _abrirAjusteSituacao : null,
            icon: const Icon(Icons.rule_outlined, size: 18),
            label: const Text('Ajustar Situação'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () async {
              final result = await showItemLicitacaoDialog(context);
              if (result != null) setState(() => _itens.add(result));
            },
            icon: const Icon(Icons.add, size: 18),
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
          )
        else
          ...[
            ...List.generate(_itens.length, (i) {
              final item = _itens[i];
              final numItem = item['numeroItem'];
              final situacao = item['situacaoCompraItemId'] != null
                  ? kSituacaoCompraItem[(item['situacaoCompraItemId'] as num)
                            .toInt()] ??
                        ''
                  : '';
              final numLicitantes =
                  (item['licitantes'] as List<dynamic>? ?? []).length;
              final valorMedio = valorMedioDoItem(item);
              final valorVencedor = valorVencedorDoItem(item);
              return Card(
                margin: const EdgeInsets.only(top: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(child: Text('$numItem')),
                  title: Text('Item $numItem'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$situacao  |  $numLicitantes licitante(s)'),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Valor médio: ${valorMedio == null ? '—' : formatBRL(valorMedio, casasDecimais: 2)}',
                          ),
                          Text(
                            'Valor do vencedor: ${valorVencedor == null ? '—' : formatBRL(valorVencedor, casasDecimais: 2)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: readOnly
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AudespIconButton(
                              icon: Icons.edit_outlined,
                              tooltip: 'Editar',
                              onPressed: () async {
                                final result = await showItemLicitacaoDialog(
                                  context,
                                  initial: item,
                                );
                                if (result != null) {
                                  setState(() => _itens[i] = result);
                                }
                              },
                            ),
                            AudespIconButton(
                              icon: Icons.delete_outline,
                              tooltip: 'Remover',
                              onPressed: () =>
                                  setState(() => _itens.removeAt(i)),
                            ),
                          ],
                        ),
                ),
              );
            }),
          ],
      ],
    );
  }

  Widget _buildItensResumo(LicitacaoItensResumo resumo) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = Color.alphaBlend(
      Colors.green.withValues(alpha: 0.08),
      colorScheme.surface,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.summarize_outlined, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Resumo dos itens',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _ResumoItem(
                label: 'Itens',
                value: resumo.quantidadeItens.toString(),
              ),
              _ResumoItem(
                label: 'Licitantes distintos',
                value: resumo.quantidadeLicitantesDistintos.toString(),
              ),
              ...kSituacaoCompraItem.entries.map(
                (entry) => _ResumoItem(
                  label: entry.value.replaceFirst(RegExp(r'^\d+\s*[–-]\s*'), ''),
                  value: (resumo.itensPorSituacao[entry.key] ?? 0).toString(),
                ),
              ),
              if ((resumo.itensPorSituacao[null] ?? 0) > 0)
                _ResumoItem(
                  label: 'Sem situação',
                  value: resumo.itensPorSituacao[null].toString(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.green.shade200, height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _ResumoItem(
                label: 'Valor médio de todos os itens',
                value: formatBRL(
                  resumo.valorMedioTodosItens,
                  casasDecimais: 2,
                ),
              ),
              _ResumoItem(
                label: 'Valor médio dos itens com vencedor',
                value: formatBRL(
                  resumo.valorMedioItensComVencedor,
                  casasDecimais: 2,
                ),
              ),
              _ResumoItem(
                label: 'Valor total dos vencedores',
                value: formatBRL(
                  resumo.valorVencedores,
                  casasDecimais: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String label;
  final String value;

  const _ResumoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
