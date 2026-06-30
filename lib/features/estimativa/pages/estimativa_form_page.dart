import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/audesp_delete_dialog.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/hover_cell_text.dart';
import '../../../shared/widgets/hover_underline_text.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../core/database/database_providers.dart';
import '../estimativa_providers.dart';
import '../models/estimativa_model.dart';
import '../models/estimativa_item_model.dart';
import '../models/estimativa_lote_model.dart';
import '../models/estimativa_orcamento_model.dart';
import '../models/estimativa_fornecedor_model.dart';
import '../widgets/estimativa_item_dialog.dart';
import '../widgets/estimativa_lote_dialog.dart';
import '../widgets/estimativa_fornecedor_dialog.dart';
import '../widgets/estimativa_valor_dialog.dart';
import '../widgets/estimativa_exclusividade_dialog.dart';
import '../widgets/gemini_orcamento_import_dialog.dart';
import '../services/estimativa_pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../edital/domain/edital_domain.dart';

class EstimativaFormPage extends ConsumerStatefulWidget {
  final int? estimativaId;

  const EstimativaFormPage({super.key, this.estimativaId});

  @override
  ConsumerState<EstimativaFormPage> createState() => _EstimativaFormPageState();
}

class _EstimativaFormPageState extends ConsumerState<EstimativaFormPage> {
  // ── Larguras fixas das colunas da tabela ─────────────────────────────────
  static const double _colDrag = 26;
  static const double _colItem = 50;
  static const double _colQuant = 80;
  static const double _colUnidade = 80;
  static const double _colFornecedor = 100;
  static const double _colValorUnit = 100;
  static const double _colValorTotal = 100;
  static const double _colAcoes = 60;
  static const double _minLarguraDesc = 400;

  double get _fixedColumnsWidth =>
      _colDrag +
      _colItem +
      _colQuant +
      _colUnidade +
      (_fornecedores.length * _colFornecedor) +
      _colValorUnit +
      _colValorTotal +
      _colAcoes +
      8; // container horizontal padding (4 each side)

  double _tableWidth(double availableWidth) {
    final descWidth = math.max(
      _minLarguraDesc,
      availableWidth - _fixedColumnsWidth,
    );
    return _fixedColumnsWidth + descWidth;
  }

  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  int? _loadedId;
  final _numeroCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();

  // ── Cabeçalho ────────────────────────────────────────────────────────────
  final _objetoCtrl = TextEditingController();
  String _tipoEstimativa = 'item'; // 'item' ou 'lote'
  String _calculoGlobal = 'min'; // 'min', 'avg', 'median'
  int _casasDecimais = 2; // 2 ou 4 (sempre arredondar para cima)

  // ── Textos PDF (Agora Automáticos) ──────────────────────────────────────
  final _prazoVigenciaCtrl = TextEditingController();
  final _formaPagamentoCtrl = TextEditingController();

  // ── Novas Propriedades ───────────────────────────────────────────────────
  bool _registroPrecos = false;
  bool _temGarantia = false;
  String _exclusividadeMeEpp = 'nenhuma';
  List<String> _fontesRecurso = [];
  final _fonteRecursoInputCtrl = TextEditingController();

  // ── Conteúdo ─────────────────────────────────────────────────────────────
  List<EstimativaLote> _lotes = [];
  List<EstimativaItem> _itens = []; // Usado quando tipoEstimativa == 'item'
  List<EstimativaFornecedor> _fornecedores = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _objetoCtrl.dispose();
    _numeroCtrl.dispose();
    _anoCtrl.dispose();
    _prazoVigenciaCtrl.dispose();
    _formaPagamentoCtrl.dispose();
    _fonteRecursoInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final dao = ref.read(estimativasDaoProvider);

    if (widget.estimativaId == null) {
      final anoAtual = DateTime.now().year;
      final proxNum = await dao.getNextNumero(anoAtual);
      _anoCtrl.text = anoAtual.toString();
      _numeroCtrl.text = proxNum.toString();
      if (mounted) setState(() => _loading = false);
      return;
    }
    final est = await dao.findById(widget.estimativaId!);
    if (est == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _loadedId = est.id;
    _numeroCtrl.text = est.numero.toString();
    _anoCtrl.text = est.ano.toString();

    _objetoCtrl.text = est.objeto;
    _tipoEstimativa = est.tipoEstimativa;
    _calculoGlobal = est.calculoGlobal;
    _casasDecimais = est.casasDecimais;

    _registroPrecos = est.registroPrecos;
    _temGarantia = est.temGarantia;
    _exclusividadeMeEpp = est.exclusividadeMeEpp;
    _fontesRecurso = List.from(est.fontesRecurso);

    _prazoVigenciaCtrl.text = est.prazoVigencia;
    _formaPagamentoCtrl.text = est.formaPagamento;

    _lotes = List.from(est.lotes);
    _itens = List.from(est.itens);
    _fornecedores = List.from(est.fornecedores);

    if (mounted) setState(() => _loading = false);
  }

  Future<EstimativaModel?> _saveEstimativa() async {
    if (!_formKey.currentState!.validate()) return null;

    setState(() => _saving = true);
    try {
      final textos = <String, String>{};

      final estimativa = EstimativaModel(
        id: _loadedId ?? 0,
        numero: int.tryParse(_numeroCtrl.text) ?? 0,
        ano: int.tryParse(_anoCtrl.text) ?? 0,
        objeto: _objetoCtrl.text.trim(),
        tipoEstimativa: _tipoEstimativa,
        calculoGlobal: _calculoGlobal,
        casasDecimais: _casasDecimais,
        textosPdf: textos,
        registroPrecos: _registroPrecos,
        temGarantia: _temGarantia,
        prazoVigencia: _prazoVigenciaCtrl.text.trim(),
        formaPagamento: _formaPagamentoCtrl.text.trim(),
        exclusividadeMeEpp: _exclusividadeMeEpp,
        fontesRecurso: _fontesRecurso,
        fornecedores: _fornecedores,
        lotes: _tipoEstimativa == 'lote' ? _lotes : [],
        itens: _tipoEstimativa == 'item' ? _itens : [],
      );

      final dao = ref.read(estimativasDaoProvider);
      if (_loadedId == null) {
        final newId = await dao.insertEstimativa(estimativa);
        _loadedId = newId;
      } else {
        await dao.updateEstimativa(estimativa);
      }

      ref.invalidate(estimativasListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estimativa salva com sucesso!')),
        );
      }
      return estimativa;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _gerarPdf() async {
    // Para gerar o PDF, primeiro garantimos que está salvo com as alterações atuais
    final estimativa = await _saveEstimativa();
    if (estimativa == null) return;

    if (mounted) {
      await EstimativaPdfService.gerarPdfEstimativa(context, estimativa);
    }
  }

  // ── Seções ───────────────────────────────────────────────────────────────

  // ── Helpers de renumeracao e conversao ──────────────────────────────────

  List<EstimativaItem> _renumerarItens(List<EstimativaItem> itens) {
    return [
      for (int i = 0; i < itens.length; i++) itens[i].copyWith(numero: i + 1),
    ];
  }

  List<EstimativaLote> _renumerarLotes(List<EstimativaLote> lotes) {
    return [
      for (int i = 0; i < lotes.length; i++) lotes[i].copyWith(numero: i + 1),
    ];
  }

  List<EstimativaItem> _converterLotesToItens(List<EstimativaLote> lotes) {
    final allItens = <EstimativaItem>[];
    for (final lote in lotes) {
      for (final item in lote.itens) {
        allItens.add(
          item.copyWith(
            exclusivoMeEpp: lote.exclusivoMeEpp || item.exclusivoMeEpp,
          ),
        );
      }
    }
    return _renumerarItens(allItens);
  }

  EstimativaLote _converterItensToSingleLote(List<EstimativaItem> itens) {
    final primeiroItem = itens.first;
    return EstimativaLote(
      numero: 1,
      descricao: 'LOTE 01',
      quantidade: 1,
      unidade: 'LOTE',
      materialOuServico: primeiroItem.materialOuServico,
      itemCategoriaId: primeiroItem.itemCategoriaId,
      exclusivoMeEpp: itens.any((i) => i.exclusivoMeEpp),
      itens: _renumerarItens(itens),
    );
  }

  Widget _buildCabecalho() {
    return SectionCard(
      title: 'Dados da Estimativa',
      children: [
        Row(
          children: [
            Expanded(
              child: AudespTextField(
                label: 'Número *',
                controller: _numeroCtrl,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AudespTextField(
                label: 'Ano *',
                controller: _anoCtrl,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AudespTextField(
          label: 'Objeto da Licitação *',
          controller: _objetoCtrl,
          maxLines: 3,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AudespDropdown<String>(
                label: 'Tipo de Estimativa *',
                value: _tipoEstimativa,
                items: const {'item': 'Por Item', 'lote': 'Por Lote'},
                onChanged: (v) async {
                  if (v != null && v != _tipoEstimativa) {
                    final hasItens = _itens.isNotEmpty;
                    final hasLotes = _lotes.isNotEmpty;

                    if (hasItens || hasLotes) {
                      String mensagem;
                      if (_tipoEstimativa == 'item' && v == 'lote') {
                        mensagem =
                            'Será criado um único lote (LOTE 01) com todos os itens existentes. Deseja continuar?';
                      } else {
                        mensagem =
                            'Os itens serão separados avulsos, removendo a estrutura de lotes. Deseja continuar?';
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Alterar Tipo de Estimativa?'),
                          content: Text(mensagem),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Confirmar'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                    }

                    setState(() {
                      _tipoEstimativa = v;
                      if (_tipoEstimativa == 'lote' &&
                          _itens.isNotEmpty &&
                          _lotes.isEmpty) {
                        _lotes = [_converterItensToSingleLote(_itens)];
                        _itens = [];
                      } else if (_tipoEstimativa == 'item' &&
                          _lotes.isNotEmpty) {
                        _itens = _converterLotesToItens(_lotes);
                        _lotes = [];
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AudespDropdown<String>(
                label: 'Tipo de Cálculo *',
                value: _calculoGlobal,
                items: const {
                  'min': 'Menor Preço',
                  'avg': 'Média',
                  'median': 'Mediana',
                },
                onChanged: (v) {
                  if (v != null) setState(() => _calculoGlobal = v);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AudespDropdown<String>(
                label: 'Exclusividade ME/EPP *',
                value: _exclusividadeMeEpp,
                items: const {
                  'nenhuma': 'Não exclusiva para ME/EPP',
                  'exclusiva': 'Exclusiva para ME/EPP (Art. 48, I)',
                  'reservada':
                      'Itens/Lotes reservados para ME/EPP (Art. 48, III)',
                },
                onChanged: (v) =>
                    setState(() => _exclusividadeMeEpp = v ?? 'nenhuma'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AudespDropdown<int>(
                label: 'Casas Decimais',
                value: _casasDecimais,
                items: const {2: '2 casas decimais', 4: '4 casas decimais'},
                onChanged: (v) {
                  if (v != null) setState(() => _casasDecimais = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AudespDropdown<bool>(
                label: 'Registro de Preços? *',
                value: _registroPrecos,
                items: const {true: 'Sim', false: 'Não'},
                onChanged: (v) => setState(() => _registroPrecos = v ?? false),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AudespTextField(
                label: 'Prazo de Vigência',
                controller: _prazoVigenciaCtrl,
                hintText: 'Ex: 12 meses',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AudespTextField(
                label: 'Forma de Pagamento *',
                controller: _formaPagamentoCtrl,
                hintText: 'Ex: 30 dias após emissão da NF',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AudespDropdown<bool>(
                label: 'Exige Garantia? *',
                value: _temGarantia,
                items: const {true: 'Sim', false: 'Não'},
                onChanged: (v) => setState(() => _temGarantia = v ?? false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontesRecursoSection() {
    return SectionCard(
      title: 'Fontes de Recurso/Aplicação',
      children: [
        AudespTextField(
          label: 'Nova Fonte (ex: xx/xxxxx)',
          controller: _fonteRecursoInputCtrl,
          suffixIcon: AudespIconButton(
            icon: Icons.add,
            tooltip: 'Adicionar',
            onPressed: () {
              final v = _fonteRecursoInputCtrl.text.trim();
              if (v.isNotEmpty && !_fontesRecurso.contains(v)) {
                setState(() {
                  _fontesRecurso.add(v);
                  _fonteRecursoInputCtrl.clear();
                });
              }
            },
          ),
          onFieldSubmitted: (v) {
            if (v.trim().isNotEmpty && !_fontesRecurso.contains(v.trim())) {
              setState(() {
                _fontesRecurso.add(v.trim());
                _fonteRecursoInputCtrl.clear();
              });
            }
          },
        ),
        if (_fontesRecurso.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhuma fonte adicionada.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _fontesRecurso.map((fonte) {
              return Chip(
                label: Text(fonte),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _fontesRecurso.remove(fonte);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildItensOuLotesSection() {
    final isLote = _tipoEstimativa == 'lote';
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: _casasDecimais,
    );

    return SectionCard(
      title: isLote ? 'Lotes da Estimativa' : 'Itens da Estimativa',
      titleActions: [
        if (_exclusividadeMeEpp == 'reservada') ...[
          TextButton.icon(
            onPressed: _showExclusividadeDialog,
            icon: const Icon(Icons.checklist),
            label: const Text('Selecionar Exclusivos'),
          ),
          const SizedBox(width: 8),
        ],
        if (_itens.isNotEmpty || _lotes.any((l) => l.itens.isNotEmpty)) ...[
          TextButton.icon(
            onPressed: _importarOrcamentoIa,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Importar Orçamento via IA'),
          ),
          const SizedBox(width: 8),
        ],
        TextButton.icon(
          onPressed: _showFornecedorDialog,
          icon: const Icon(Icons.person_add),
          label: const Text('Incluir Fornecedor'),
        ),
        const SizedBox(width: 8),
        if (isLote)
          TextButton.icon(
            onPressed: _addLote,
            icon: const Icon(Icons.add_to_photos),
            label: const Text('Incluir Lote'),
          )
        else
          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Incluir Item'),
          ),
      ],
      children: [
        if ((isLote && _lotes.isEmpty) || (!isLote && _itens.isEmpty))
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Nenhum item ou lote adicionado.'),
            ),
          )
        else if (isLote)
          _buildLotesList(fmt)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return _HorizontalScrollableTable(
                tableWidth: _tableWidth(constraints.maxWidth),
                child: Column(
                  children: [_buildTableHeader(fmt), _buildItensList(fmt)],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMeEppSection() {
    if (_exclusividadeMeEpp == 'nenhuma') return const SizedBox.shrink();

    final isLote = _tipoEstimativa == 'lote';

    double totalGlobal;
    double totalMeEpp;

    if (isLote) {
      totalGlobal = _lotes.fold(
        0.0,
        (sum, l) =>
            sum +
            l.getValorTotal(_calculoGlobal, casasDecimais: _casasDecimais),
      );
      totalMeEpp = _lotes
          .where((l) => l.exclusivoMeEpp)
          .fold(
            0.0,
            (sum, l) =>
                sum +
                l.getValorTotal(_calculoGlobal, casasDecimais: _casasDecimais),
          );
    } else {
      totalGlobal = _itens.fold(
        0.0,
        (sum, i) =>
            sum +
            i.getValorTotal(_calculoGlobal, casasDecimais: _casasDecimais),
      );
      totalMeEpp = _itens
          .where((i) => i.exclusivoMeEpp)
          .fold(
            0.0,
            (sum, i) =>
                sum +
                i.getValorTotal(_calculoGlobal, casasDecimais: _casasDecimais),
          );
    }

    if (_exclusividadeMeEpp == 'exclusiva') {
      totalMeEpp = totalGlobal;
    }

    if (totalGlobal == 0) return const SizedBox.shrink();

    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: _casasDecimais,
    );
    final percentual = (totalMeEpp / totalGlobal) * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4.0, right: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.expand_circle_down_outlined,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _exclusividadeMeEpp == 'exclusiva'
                  ? '100% exclusivo para ME/EPP'
                  : 'Reservado para ME/EPP: ${fmt.format(totalMeEpp)} (${percentual.toStringAsFixed(2)}%)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              'Total: ${fmt.format(totalGlobal)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExclusividadeDialog() async {
    final result = await showEstimativaExclusividadeDialog(
      context: context,
      tipoEstimativa: _tipoEstimativa,
      itens: _itens,
      lotes: _lotes,
    );
    if (result != null) {
      setState(() {
        _itens = result.itens;
        _lotes = result.lotes;
      });
    }
  }

  Future<void> _addLote() async {
    final res = await showEstimativaLoteDialog(
      context: context,
      calculoGlobal: _calculoGlobal,
      nextNumero: _lotes.length + 1,
    );
    if (res != null) setState(() => _lotes.add(res));
  }

  Future<void> _editLote(int i) async {
    final res = await showEstimativaLoteDialog(
      context: context,
      lote: _lotes[i],
      calculoGlobal: _calculoGlobal,
    );
    if (res != null) setState(() => _lotes[i] = res);
  }

  Future<void> _addItem() async {
    final res = await showEstimativaItemDialog(
      context: context,
      estimativaTipo: 'item',
      calculoGlobal: _calculoGlobal,
      nextNumero: _itens.length + 1,
    );
    if (res != null) setState(() => _itens.add(res));
  }

  Future<void> _editItem(int i) async {
    final res = await showEstimativaItemDialog(
      context: context,
      item: _itens[i],
      estimativaTipo: 'item',
      calculoGlobal: _calculoGlobal,
    );
    if (res != null) setState(() => _itens[i] = res);
  }

  Future<void> _addLoteItem(int loteIndex) async {
    final lote = _lotes[loteIndex];
    final res = await showEstimativaItemDialog(
      context: context,
      estimativaTipo: 'lote',
      calculoGlobal: _calculoGlobal,
      nextNumero: lote.itens.length + 1,
    );
    if (res != null) {
      setState(() {
        final newItens = List<EstimativaItem>.from(lote.itens)..add(res);
        _lotes[loteIndex] = lote.copyWith(itens: _renumerarItens(newItens));
      });
    }
  }

  void _reorderItens(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _itens.removeAt(oldIndex);
      _itens.insert(newIndex, item);
      _itens = _renumerarItens(_itens);
    });
  }

  void _reorderLotes(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final lote = _lotes.removeAt(oldIndex);
      _lotes.insert(newIndex, lote);
      _lotes = _renumerarLotes(_lotes);
    });
  }

  void _reorderLoteItens(int loteIndex, int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final lote = _lotes[loteIndex];
      final newItens = List<EstimativaItem>.from(lote.itens);
      final item = newItens.removeAt(oldIndex);
      newItens.insert(newIndex, item);
      _lotes[loteIndex] = lote.copyWith(itens: _renumerarItens(newItens));
    });
  }

  Widget _buildTableHeader(NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: _tipoEstimativa == 'item'
            ? const BorderRadius.vertical(top: Radius.circular(8))
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: _colDrag),
          SizedBox(
            width: _colItem,
            child: const Center(
              child: Text(
                'Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _minLarguraDesc),
              child: const Text(
                'Descrição',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            width: _colQuant,
            child: const Center(
              child: Text(
                'Quantidade',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            width: _colUnidade,
            child: const Center(
              child: Text(
                'Unidade',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ..._fornecedores.map((f) {
            return SizedBox(
              width: _colFornecedor,
              child: HoverCellText(
                text: f.razaoSocial.isNotEmpty
                    ? f.razaoSocial
                    : 'Novo Fornecedor',
                onTap: () => _showFornecedorDialog(f),
                tooltip: '${f.razaoSocial}\nCNPJ: ${f.cnpj}\nData: ${f.data}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
          SizedBox(
            width: _colValorUnit,
            child: const Center(
              child: Text(
                'Valor Unitário',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            width: _colValorTotal,
            child: const Center(
              child: Text(
                'Valor Total',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: _colAcoes),
        ],
      ),
    );
  }

  Widget _buildItensList(NumberFormat fmt) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _itens.length,
      onReorderItem: _reorderItens,
      itemBuilder: (context, index) {
        final item = _itens[index];
        return _buildItemRow(
          item: item,
          loteIndex: null,
          itemIndex: index,
          fmt: fmt,
          key: ValueKey('item_${item.numero}_${item.descricao.hashCode}'),
        );
      },
    );
  }

  Widget _buildLotesList(NumberFormat fmt) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lotes.length,
      onReorderItem: _reorderLotes,
      itemBuilder: (context, loteIndex) {
        final lote = _lotes[loteIndex];
        final loteTotal = lote.getValorTotal(
          _calculoGlobal,
          casasDecimais: _casasDecimais,
        );
        return Card(
          key: ValueKey('lote_${lote.numero}_${lote.descricao.hashCode}'),
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: loteIndex,
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.move,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: 8.0,
                            top: 8.0,
                            bottom: 8.0,
                          ),
                          child: Icon(Icons.drag_indicator, size: 20),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              HoverUnderlineText(
                                text: 'Lote ${lote.numero} - ${lote.descricao}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                onTap: () => _editLote(loteIndex),
                              ),
                              if (_exclusividadeMeEpp == 'reservada' &&
                                  _tipoEstimativa == 'lote' &&
                                  lote.exclusivoMeEpp)
                                const Tooltip(
                                  message: 'Lote reservado para ME/EPP',
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: 2.5,
                                      left: 2.0,
                                    ),
                                    child: Icon(
                                      Icons.expand_circle_down_outlined,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lote.materialOuServico == 'M' ? 'Material' : 'Serviço'} | '
                            '${lote.itemCategoriaId != null ? kItemCategoria[lote.itemCategoriaId] ?? '' : ''} | '
                            '${formatNumberBR(lote.quantidade)} ${lote.unidade} | '
                            'Subtotal: ${fmt.format(loteTotal)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _addLoteItem(loteIndex),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Incluir Item'),
                    ),
                    const SizedBox(width: 4),
                    AudespIconButton(
                      icon: Icons.delete,
                      tooltip: 'Excluir Lote',
                      color: Colors.red,
                      onPressed: () => _confirmDeleteLote(loteIndex),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return _HorizontalScrollableTable(
                    tableWidth: _tableWidth(constraints.maxWidth),
                    isLote: true,
                    child: Column(
                      children: [
                        _buildTableHeader(fmt),
                        if (lote.itens.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhum item neste lote.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lote.itens.length,
                            onReorderItem: (oldIndex, newIndex) =>
                                _reorderLoteItens(
                                  loteIndex,
                                  oldIndex,
                                  newIndex,
                                ),
                            itemBuilder: (context, itemIndex) {
                              final item = lote.itens[itemIndex];
                              return _buildItemRow(
                                item: item,
                                loteIndex: loteIndex,
                                itemIndex: itemIndex,
                                fmt: fmt,
                                key: ValueKey(
                                  'lote_${loteIndex}_item_${item.numero}_${item.descricao.hashCode}',
                                ),
                                showBottomBorder:
                                    itemIndex < lote.itens.length - 1,
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemRow({
    required EstimativaItem item,
    required int? loteIndex,
    required int itemIndex,
    required NumberFormat fmt,
    required Key key,
    bool showBottomBorder = true,
  }) {
    final statusIcon = item.orcamentos.length >= 3
        ? const Tooltip(
            message: '3 ou mais orçamentos',
            child: Icon(Icons.check_circle, color: Colors.green, size: 16),
          )
        : item.orcamentos.isNotEmpty
        ? const Tooltip(
            message: 'Menos de 3 orçamentos',
            child: Icon(Icons.warning, color: Colors.amber, size: 16),
          )
        : const Tooltip(
            message: 'Sem orçamentos',
            child: Icon(Icons.cancel, color: Colors.red, size: 16),
          );

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        border: showBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: itemIndex,
            child: const MouseRegion(
              cursor: SystemMouseCursors.move,
              child: SizedBox(
                width: _colDrag,
                child: Center(child: Icon(Icons.drag_indicator, size: 18)),
              ),
            ),
          ),
          SizedBox(
            width: _colItem,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HoverCellText(
                  text: '${item.numero}',
                  onTap: () => loteIndex != null
                      ? _editLoteItem(loteIndex, itemIndex)
                      : _editItem(itemIndex),
                  textAlign: TextAlign.center,
                  alignment: Alignment.center,
                ),
                if (_exclusividadeMeEpp == 'reservada' &&
                    _tipoEstimativa == 'item' &&
                    item.exclusivoMeEpp)
                  const Tooltip(
                    message: 'Item reservado para ME/EPP',
                    child: Padding(
                      padding: EdgeInsets.only(top: 2.5, left: 2.0),
                      child: Icon(
                        Icons.expand_circle_down_outlined,
                        size: 12,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _minLarguraDesc),
              child: HoverCellText(
                text: item.descricao,
                onTap: () => loteIndex != null
                    ? _editLoteItem(loteIndex, itemIndex)
                    : _editItem(itemIndex),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.justify,
              ),
            ),
          ),
          SizedBox(
            width: _colQuant,
            child: Center(
              child: item.tipoFornecimento == 'mensal'
                  ? Tooltip(
                      message: '${formatNumberBR(item.quantidade)}/mês',
                      child: Text(
                        '${formatNumberBR(item.quantidade * item.quantidadeMeses)} *',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text(
                      formatNumberBR(item.quantidade),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          SizedBox(
            width: _colUnidade,
            child: Center(
              child: Text(item.unidade, textAlign: TextAlign.center),
            ),
          ),
          ..._fornecedores.map((f) {
            final orc = item.orcamentos
                .where((o) => o.fornecedorId == f.id)
                .firstOrNull;
            return SizedBox(
              width: _colFornecedor,
              child: Center(
                child: HoverCellText(
                  text: orc != null ? formatBRL(orc.valorUnitario) : '-',
                  onTap: () => _showValorDialog(
                    loteIndex: loteIndex,
                    itemIndex: itemIndex,
                    fornecedor: f,
                    atual: orc,
                  ),
                  textAlign: TextAlign.center,
                  alignment: Alignment.center,
                ),
              ),
            );
          }),
          SizedBox(
            width: _colValorUnit,
            child: Center(
              child: Tooltip(
                message:
                    'Cálculo atual: ${_calculoGlobal == 'min'
                        ? 'Menor'
                        : _calculoGlobal == 'avg'
                        ? 'Média'
                        : 'Mediana'}',
                child: Text(
                  formatBRL(
                    item.getValorReferenciaUnitario(
                      _calculoGlobal,
                      casasDecimais: _casasDecimais,
                    ),
                    casasDecimais: _casasDecimais,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _colValorTotal,
            child: Center(
              child: item.tipoFornecimento == 'mensal'
                  ? Tooltip(
                      message:
                          '${formatBRL(item.getValorMensal(_calculoGlobal, casasDecimais: _casasDecimais), casasDecimais: _casasDecimais)}/mês',
                      child: Text(
                        formatBRL(
                          item.getValorTotal(
                            _calculoGlobal,
                            casasDecimais: _casasDecimais,
                          ),
                          casasDecimais: _casasDecimais,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text(
                      formatBRL(
                        item.getValorTotal(
                          _calculoGlobal,
                          casasDecimais: _casasDecimais,
                        ),
                        casasDecimais: _casasDecimais,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          SizedBox(
            width: _colAcoes,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  statusIcon,
                  const SizedBox(width: 8),
                  AudespIconButton(
                    icon: Icons.delete,
                    tooltip: 'Excluir Item',
                    color: Colors.red,
                    onPressed: () => _confirmDeleteItem(loteIndex, itemIndex),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteItem(int? loteIndex, int itemIndex) async {
    final confirm = await showAudespDeleteDialog(
      context: context,
      title: 'Excluir Item',
      entityName: 'este item',
    );

    if (confirm == true) {
      setState(() {
        if (loteIndex != null) {
          final lote = _lotes[loteIndex];
          final newItens = List<EstimativaItem>.from(lote.itens)
            ..removeAt(itemIndex);
          for (int i = 0; i < newItens.length; i++) {
            newItens[i] = newItens[i].copyWith(numero: i + 1);
          }
          _lotes[loteIndex] = lote.copyWith(itens: newItens);
        } else {
          _itens.removeAt(itemIndex);
          for (int i = 0; i < _itens.length; i++) {
            _itens[i] = _itens[i].copyWith(numero: i + 1);
          }
        }
      });
    }
  }

  Future<void> _confirmDeleteLote(int loteIndex) async {
    final lote = _lotes[loteIndex];
    final confirm = await showAudespDeleteDialog(
      context: context,
      title: 'Excluir Lote',
      entityName: 'lote ${lote.numero}',
    );

    if (confirm == true) {
      setState(() {
        _lotes.removeAt(loteIndex);
        for (int i = 0; i < _lotes.length; i++) {
          _lotes[i] = _lotes[i].copyWith(numero: i + 1);
        }
      });
    }
  }

  Future<void> _editLoteItem(int loteIndex, int itemIndex) async {
    final lote = _lotes[loteIndex];
    final res = await showEstimativaItemDialog(
      context: context,
      item: lote.itens[itemIndex],
      estimativaTipo: 'lote',
      calculoGlobal: _calculoGlobal,
    );
    if (res != null) {
      setState(() {
        final newItens = List<EstimativaItem>.from(lote.itens);
        newItens[itemIndex] = res;
        _lotes[loteIndex] = lote.copyWith(itens: newItens);
      });
    }
  }

  Future<void> _showFornecedorDialog([EstimativaFornecedor? fornecedor]) async {
    final result = await showEstimativaFornecedorDialog(
      context: context,
      fornecedor: fornecedor,
    );

    if (result == null) return;

    if (result.isDelete && fornecedor != null) {
      setState(() {
        _fornecedores.removeWhere((f) => f.id == fornecedor.id);
        if (_tipoEstimativa == 'lote') {
          for (int i = 0; i < _lotes.length; i++) {
            final newItens = _lotes[i].itens.map((it) {
              return it.copyWith(
                orcamentos: it.orcamentos
                    .where((o) => o.fornecedorId != fornecedor.id)
                    .toList(),
              );
            }).toList();
            _lotes[i] = _lotes[i].copyWith(itens: newItens);
          }
        } else {
          for (int i = 0; i < _itens.length; i++) {
            _itens[i] = _itens[i].copyWith(
              orcamentos: _itens[i].orcamentos
                  .where((o) => o.fornecedorId != fornecedor.id)
                  .toList(),
            );
          }
        }
      });
    } else if (result.isSave && result.fornecedor != null) {
      setState(() {
        if (fornecedor == null) {
          _fornecedores.add(result.fornecedor!);
        } else {
          final index = _fornecedores.indexWhere((f) => f.id == fornecedor.id);
          if (index != -1) {
            _fornecedores[index] = result.fornecedor!;
          }
        }
      });
    }
  }

  Future<void> _showValorDialog({
    required int? loteIndex,
    required int itemIndex,
    required EstimativaFornecedor fornecedor,
    required EstimativaOrcamento? atual,
  }) async {
    final result = await showEstimativaValorDialog(
      context: context,
      fornecedor: fornecedor,
      atual: atual,
    );

    if (result == -1.0) {
      _updateItemOrcamento(loteIndex, itemIndex, fornecedor.id, null);
    } else if (result != null) {
      _updateItemOrcamento(loteIndex, itemIndex, fornecedor.id, result);
    }
  }

  void _updateItemOrcamento(
    int? loteIndex,
    int itemIndex,
    String fornecedorId,
    double? novoValor,
  ) {
    setState(() {
      if (loteIndex != null) {
        final lote = _lotes[loteIndex];
        final item = lote.itens[itemIndex];
        final orcs = List<EstimativaOrcamento>.from(item.orcamentos);
        orcs.removeWhere((o) => o.fornecedorId == fornecedorId);
        if (novoValor != null) {
          orcs.add(
            EstimativaOrcamento(
              fornecedorId: fornecedorId,
              valorUnitario: novoValor,
            ),
          );
        }
        final newItens = List<EstimativaItem>.from(lote.itens);
        newItens[itemIndex] = item.copyWith(orcamentos: orcs);
        _lotes[loteIndex] = lote.copyWith(itens: newItens);
      } else {
        final item = _itens[itemIndex];
        final orcs = List<EstimativaOrcamento>.from(item.orcamentos);
        orcs.removeWhere((o) => o.fornecedorId == fornecedorId);
        if (novoValor != null) {
          orcs.add(
            EstimativaOrcamento(
              fornecedorId: fornecedorId,
              valorUnitario: novoValor,
            ),
          );
        }
        _itens[itemIndex] = item.copyWith(orcamentos: orcs);
      }
    });
  }

  Future<void> _importarOrcamentoIa() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    if (!mounted) return;

    final isMulti = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Múltiplos orçamentos'),
        content: const Text(
          'O arquivo selecionado contém orçamentos de múltiplas empresas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
    if (isMulti == null) return;

    if (!mounted) return;

    final isLote = _tipoEstimativa == 'lote';

    // Preparar lista de itens para o Gemini
    final List<Map<String, dynamic>> itensEstimativa = [];
    if (isLote) {
      for (final lote in _lotes) {
        for (final item in lote.itens) {
          itensEstimativa.add({
            'id': '${lote.numero}-${item.numero}',
            'descricao': item.descricao,
            'unidade': item.unidade,
            'quantidade': item.quantidade,
          });
        }
      }
    } else {
      for (final item in _itens) {
        itensEstimativa.add({
          'id': '${item.numero}',
          'descricao': item.descricao,
          'unidade': item.unidade,
          'quantidade': item.quantidade,
        });
      }
    }

    if (!mounted) return;

    if (isMulti) {
      final resultados = await showGeminiMultiOrcamentoImportDialog(
        context: context,
        ref: ref,
        pdfPath: path,
        itensEstimativa: itensEstimativa,
      );
      if (resultados == null || resultados.isEmpty) return;

      setState(() {
        for (final orcamentoResult in resultados) {
          _applyOrcamentoResult(orcamentoResult, isLote);
        }
      });
    } else {
      final orcamentoResult = await showGeminiOrcamentoImportDialog(
        context: context,
        ref: ref,
        pdfPath: path,
        itensEstimativa: itensEstimativa,
      );
      if (orcamentoResult == null) return;

      setState(() {
        _applyOrcamentoResult(orcamentoResult, isLote);
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMulti
                ? 'Orçamentos importados com sucesso!'
                : 'Orçamento importado com sucesso!',
          ),
        ),
      );
    }
  }

  void _applyOrcamentoResult(
    GeminiOrcamentoResult orcamentoResult,
    bool isLote,
  ) {
    final novoFornecedor = EstimativaFornecedor(
      razaoSocial: orcamentoResult.razaoSocial ?? '',
      cnpj: orcamentoResult.cnpj ?? '',
      data: orcamentoResult.data ?? '',
    );
    _fornecedores.add(novoFornecedor);

    if (isLote) {
      for (int l = 0; l < _lotes.length; l++) {
        final lote = _lotes[l];
        final novosItens = <EstimativaItem>[];
        for (final item in lote.itens) {
          final val = orcamentoResult.itens['${lote.numero}-${item.numero}'];
          if (val != null) {
            final newOrcamento = EstimativaOrcamento(
              fornecedorId: novoFornecedor.id,
              valorUnitario: val,
            );
            novosItens.add(
              item.copyWith(orcamentos: [...item.orcamentos, newOrcamento]),
            );
          } else {
            novosItens.add(item);
          }
        }
        _lotes[l] = lote.copyWith(itens: novosItens);
      }
    } else {
      for (int i = 0; i < _itens.length; i++) {
        final item = _itens[i];
        final val = orcamentoResult.itens['${item.numero}'];
        if (val != null) {
          final newOrcamento = EstimativaOrcamento(
            fornecedorId: novoFornecedor.id,
            valorUnitario: val,
          );
          _itens[i] = item.copyWith(
            orcamentos: [...item.orcamentos, newOrcamento],
          );
        }
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/estimativa')),
        title: Text(
          _loadedId == null ? 'Nova Estimativa' : 'Editar Estimativa',
        ),
        actions: [
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
              onPressed: _saveEstimativa,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar Estimativa'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _gerarPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Gerar PDF'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCabecalho(),
              const SizedBox(height: 16),
              _buildFontesRecursoSection(),
              const SizedBox(height: 16),
              _buildMeEppSection(),
              _buildItensOuLotesSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalScrollableTable extends StatefulWidget {
  final double tableWidth;
  final Widget child;
  final bool isLote;

  const _HorizontalScrollableTable({
    required this.tableWidth,
    required this.child,
    this.isLote = false,
  });

  @override
  State<_HorizontalScrollableTable> createState() =>
      _HorizontalScrollableTableState();
}

class _HorizontalScrollableTableState
    extends State<_HorizontalScrollableTable> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        mainAxisMargin: widget.isLote ? 6.0 : 0.0,
        crossAxisMargin: 1.0,
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 4.0,
        interactive: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: SizedBox(width: widget.tableWidth, child: widget.child),
          ),
        ),
      ),
    );
  }
}
