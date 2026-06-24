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
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_currency_field.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_number_field.dart';
import '../../../shared/widgets/audesp_pncp_field.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/section_card.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../domain/ajuste_domain.dart';
import '../ajuste_providers.dart';
import '../services/ajuste_service.dart';
import '../widgets/gemini_ajuste_import_dialog.dart';
import 'package:file_picker/file_picker.dart';

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
  bool _importingGemini = false;
  int? _loadedId;

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
    _editais = await ref.read(editaisDaoProvider).watchAll();
    _atas = await ref.read(atasDaoProvider).watchAll();

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
    _codigoAtaCtrl.text = PcnpInputFormatter.applyMask(
        descritor['codigoAta'] as String? ?? ajuste.codigoAta ?? '');
    _codigoContratoCtrl.text = PcnpInputFormatter.applyMask(
        descritor['codigoContrato'] as String? ?? ajuste.codigoContrato);
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
      descritor['codigoAta'] = PcnpInputFormatter.stripMask(_codigoAtaCtrl.text);
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
          parseBrCurrency(_valorInicialCtrl.text.trim())
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
          parseBrCurrency(_valorParcelaCtrl.text.trim())
              .toStringAsFixed(4));
    }
    if (_valorGlobalCtrl.text.trim().isNotEmpty) {
      map['valorGlobal'] = double.parse(
          parseBrCurrency(_valorGlobalCtrl.text.trim())
              .toStringAsFixed(4));
    }
    if (_valorAcumuladoCtrl.text.trim().isNotEmpty) {
      map['valorAcumulado'] = double.parse(
          parseBrCurrency(_valorAcumuladoCtrl.text.trim())
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
          codigoContrato: PcnpInputFormatter.stripMask(_codigoContratoCtrl.text),
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
          codigoContrato: PcnpInputFormatter.stripMask(_codigoContratoCtrl.text),
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
    final isEmpenho = _tipoContratoId == 7;
    
    if (isEmpenho || !_receita) {
      if (_despesas.isEmpty) {
        _showError('A classificação de despesa é obrigatória (exigida para despesas ou empenhos).');
        return;
      }
    }
    if (isEmpenho && _despesas.length > 1) {
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

  // ── Importação via Gemini ─────────────────────────────────────────────

  Future<void> _importFromDocx() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    setState(() => _importingGemini = true);
    try {
      final currentValues = <String, String>{
        'tipoContratoId': _tipoContratoId?.toString() ?? '',
        'numeroContratoEmpenho': _numeroContratoEmpenhoCtrl.text.trim(),
        'anoContrato': _anoContratoCtrl.text.trim(),
        'processo': _processoCtrl.text.trim(),
        'categoriaProcessoId': _categoriaProcessoId?.toString() ?? '',
        'niFornecedor': _niFornecedorCtrl.text.trim(),
        'nomeRazaoSocialFornecedor': _nomeRazaoSocialFornecedorCtrl.text.trim(),
        'tipoObjetoContrato': _tipoObjetoContrato?.toString() ?? '',
        'objetoContrato': _objetoContratoCtrl.text.trim(),
        'valorInicial': _valorInicialCtrl.text.trim(),
        'itens': _itens.join(', '),
        'dataAssinatura': _dataAssinatura != null ? DateFormat('dd/MM/yyyy').format(_dataAssinatura!) : '',
        'dataVigenciaInicio': _dataVigenciaInicio != null ? DateFormat('dd/MM/yyyy').format(_dataVigenciaInicio!) : '',
        'dataVigenciaFim': _dataVigenciaFim != null ? DateFormat('dd/MM/yyyy').format(_dataVigenciaFim!) : '',
      };

      final accepted = await showGeminiAjusteImportDialog(
        context: context,
        ref: ref,
        filePath: result.files.single.path!,
        currentValues: currentValues,
      );

      if (!mounted || accepted == null || accepted.isEmpty) return;

      setState(() {
        if (accepted.containsKey('tipoContratoId')) {
          final match = RegExp(r'\d+').firstMatch(accepted['tipoContratoId']!);
          if (match != null) _tipoContratoId = int.tryParse(match.group(0)!);
        }
        if (accepted.containsKey('numeroContratoEmpenho')) {
          _numeroContratoEmpenhoCtrl.text = accepted['numeroContratoEmpenho']!;
        }
        if (accepted.containsKey('anoContrato')) {
          _anoContratoCtrl.text = accepted['anoContrato']!;
        }
        if (accepted.containsKey('processo')) {
          _processoCtrl.text = accepted['processo']!;
        }
        if (accepted.containsKey('niFornecedor')) {
          final ni = accepted['niFornecedor']!.replaceAll(RegExp(r'\D'), '');
          _niFornecedorCtrl.text = accepted['niFornecedor']!;
          if (ni.length == 11) {
            _tipoPessoaFornecedor = 'PF';
          } else if (ni.length == 14) {
            _tipoPessoaFornecedor = 'PJ';
          } else if (ni.isNotEmpty) {
            _tipoPessoaFornecedor = 'PE';
          }
        }
        if (accepted.containsKey('itens')) {
          final itemsRaw = accepted['itens']!;
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
        if (accepted.containsKey('categoriaProcessoId')) {
          final match = RegExp(r'\d+').firstMatch(accepted['categoriaProcessoId']!);
          if (match != null) _categoriaProcessoId = int.tryParse(match.group(0)!);
        }
        if (accepted.containsKey('nomeRazaoSocialFornecedor')) {
          _nomeRazaoSocialFornecedorCtrl.text = accepted['nomeRazaoSocialFornecedor']!;
        }
        if (accepted.containsKey('tipoObjetoContrato')) {
          final match = RegExp(r'\d+').firstMatch(accepted['tipoObjetoContrato']!);
          if (match != null) _tipoObjetoContrato = int.tryParse(match.group(0)!);
        }
        if (accepted.containsKey('objetoContrato')) {
          _objetoContratoCtrl.text = accepted['objetoContrato']!;
        }
        if (accepted.containsKey('valorInicial')) {
          _valorInicialCtrl.text = accepted['valorInicial']!;
        }
        if (accepted.containsKey('dataAssinatura')) {
          try {
            _dataAssinatura = DateFormat('dd/MM/yyyy').parse(accepted['dataAssinatura']!);
          } catch (_) {}
        }
        if (accepted.containsKey('dataVigenciaInicio')) {
          try {
            _dataVigenciaInicio = DateFormat('dd/MM/yyyy').parse(accepted['dataVigenciaInicio']!);
          } catch (_) {}
        }
        if (accepted.containsKey('dataVigenciaFim')) {
          try {
            _dataVigenciaFim = DateFormat('dd/MM/yyyy').parse(accepted['dataVigenciaFim']!);
          } catch (_) {}
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${accepted.length} campo(s) preenchido(s) pelo Gemini.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importingGemini = false);
    }
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
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              TextButton.icon(
                onPressed: _importingGemini ? null : _importFromDocx,
                icon: _importingGemini
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Importar do Word'),
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
                        flex: 1,
                        child: AudespDropdown<int?>(
                          label: 'Ata (somente para SRP)',
                          value: _ataId,
                          items: {
                            null: '— Nenhuma —',
                            for (final a in _atas) a.id: a.dropdownLabel,
                          },
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
                        'Município: $municipio   |   Entidade: $entidade   |   Código do Edital: ${_codigoEditalCtrl.text.isEmpty ? '-' : PcnpInputFormatter.applyMask(_codigoEditalCtrl.text)}   |   Código da Ata: ${_codigoAtaCtrl.text.isEmpty ? '-' : PcnpInputFormatter.applyMask(_codigoAtaCtrl.text)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }),                  
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
                          onChanged:
                              readOnly ? null : (v) => setState(() => _retificacao = v ?? false),
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
                        : (v) => setState(() => _adesaoParticipacao = v ?? false),
                  ),
                  if (_adesaoParticipacao) ...[
                    AudespCheckbox(
                      label: 'Gerenciadora Jurisdicionada',
                      value: _gerenciadoraJurisdicionada,
                      onChanged: readOnly
                          ? null
                          : (v) =>
                              setState(() => _gerenciadoraJurisdicionada = v ?? false),
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
                              validator: (v) => _gerenciadoraJurisdicionada &&
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
                    AudespTextField(
                      label: 'Número do item',
                      hintText: 'Ex: 1',
                      controller: _itemCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      suffixIcon: IconButton(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        tooltip: 'Adicionar',
                        iconSize: 18,
                      ),
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
                  AudespDropdown<int>(
                    label: 'Tipo de Contrato *',
                    value: _tipoContratoId,
                    items: kTipoContrato,
                    onChanged:
                        readOnly ? null : (v) => setState(() => _tipoContratoId = v),
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
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
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
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDropdown<int>(
                          label: 'Categoria do Processo *',
                          value: _categoriaProcessoId,
                          items: kCategoriaProcesso,
                          onChanged: readOnly
                              ? null
                              : (v) => setState(() => _categoriaProcessoId = v),
                          validator: (v) =>
                              v == null ? 'Selecione a categoria do processo' : null,
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
                      AudespTextField(
                        label: '8 dígitos (ex: 33903900)',
                        controller: _despesaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        suffixIcon: IconButton(
                          onPressed: _addDespesa,
                          icon: const Icon(Icons.add),
                          tooltip: 'Adicionar',
                          iconSize: 18,
                        ),
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
                        child: AudespTextField(
                          label: 'NI do Fornecedor (CNPJ/CPF) *',
                          controller: _niFornecedorCtrl,
                          readOnly: readOnly,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AudespDropdown<String>(
                          label: 'Tipo de Pessoa *',
                          value: _tipoPessoaFornecedor,
                          items: kTipoPessoaFornecedor,
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
                          onChanged: readOnly
                              ? null
                              : (v) =>
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
                    onChanged: readOnly
                        ? null
                        : (v) => setState(() => _tipoObjetoContrato = v),
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

