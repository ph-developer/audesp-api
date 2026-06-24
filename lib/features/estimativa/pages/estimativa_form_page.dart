import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/hover_cell_text.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
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
import '../../../core/utils/currency_formatter.dart';

class EstimativaFormPage extends ConsumerStatefulWidget {
  final int? estimativaId;

  const EstimativaFormPage({super.key, this.estimativaId});

  @override
  ConsumerState<EstimativaFormPage> createState() => _EstimativaFormPageState();
}

class _EstimativaFormPageState extends ConsumerState<EstimativaFormPage> {
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

  // ── Textos PDF (Agora Automáticos) ──────────────────────────────────────
  final _prazoVigenciaCtrl = TextEditingController();
  final _formaPagamentoCtrl = TextEditingController();

  // ── Novas Propriedades ───────────────────────────────────────────────────
  bool _registroPrecos = false;
  bool _temGarantia = false;
  final _periodoGarantiaCtrl = TextEditingController();
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
    _periodoGarantiaCtrl.dispose();
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

    _registroPrecos = est.registroPrecos;
    _temGarantia = est.temGarantia;
    _periodoGarantiaCtrl.text = est.periodoGarantia;
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
        textosPdf: textos,
        registroPrecos: _registroPrecos,
        temGarantia: _temGarantia,
        periodoGarantia: _periodoGarantiaCtrl.text.trim(),
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
                    if (_itens.isNotEmpty || _lotes.isNotEmpty) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Alterar Tipo de Estimativa?'),
                          content: const Text(
                            'Ao alterar o tipo de estimativa, todos os itens e lotes já adicionados serão apagados. Deseja continuar?',
                          ),
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
                      if (confirm != true) {
                        return;
                      }
                    }
                    setState(() {
                      _tipoEstimativa = v;
                      _itens.clear();
                      _lotes.clear();
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
                  'min': 'Menor Preço (Mínimo)',
                  'avg': 'Média',
                  'median': 'Mediana',
                  'desc': 'Maior Desconto',
                },
                onChanged: (v) {
                  if (v != null) setState(() => _calculoGlobal = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
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
              child: AudespDropdown<bool>(
                label: 'Exige Garantia? *',
                value: _temGarantia,
                items: const {true: 'Sim', false: 'Não'},
                onChanged: (v) => setState(() => _temGarantia = v ?? false),
              ),
            ),
          ],
        ),
        if (_temGarantia) ...[
          const SizedBox(height: 12),
          AudespTextField(
            label: 'Período da Garantia *',
            controller: _periodoGarantiaCtrl,
            hintText: 'Ex: 12 meses',
            validator: (v) => (_temGarantia && (v == null || v.trim().isEmpty))
                ? 'Obrigatório'
                : null,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AudespTextField(
                label: 'Prazo de Vigência *',
                controller: _prazoVigenciaCtrl,
                hintText: 'Ex: 12 meses',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
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
          ],
        ),
        const SizedBox(height: 16),
        AudespDropdown<String>(
          label: 'Exclusividade ME/EPP *',
          value: _exclusividadeMeEpp,
          items: const {
            'nenhuma': 'Não exclusiva para ME/EPP',
            'exclusiva': 'Exclusiva para ME/EPP (Art. 48, I)',
            'reservada': 'Itens/Lotes reservados para ME/EPP (Art. 48, III)',
          },
          onChanged: (v) =>
              setState(() => _exclusividadeMeEpp = v ?? 'nenhuma'),
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
          suffixIcon: IconButton(
            onPressed: () {
              final v = _fonteRecursoInputCtrl.text.trim();
              if (v.isNotEmpty && !_fontesRecurso.contains(v)) {
                setState(() {
                  _fontesRecurso.add(v);
                  _fonteRecursoInputCtrl.clear();
                });
              }
            },
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar',
            iconSize: 18,
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
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Incluir Item'),
        ),
        if (isLote) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _addLote,
            icon: const Icon(Icons.add_to_photos),
            label: const Text('Incluir Lote'),
          ),
        ],
      ],
      children: [
        if ((isLote && _lotes.isEmpty) || (!isLote && _itens.isEmpty))
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Nenhum item ou lote adicionado.'),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 12,
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => Colors.transparent,
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: double.infinity,
              columnSpacing: 24,
              columns: [
                if (isLote)
                  const DataColumn(label: Text('Lote', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Quantidade', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Unidade', style: TextStyle(fontWeight: FontWeight.bold))),
                ..._fornecedores.map((f) {
                  return DataColumn(
                    label: Expanded(
                      child: HoverCellText(
                        text: f.razaoSocial.isNotEmpty ? f.razaoSocial : 'Novo Fornecedor',
                        onTap: () => _showFornecedorDialog(f),
                        tooltip: 'CNPJ: ${f.cnpj}\nData: ${f.data}\nClique para editar',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
                const DataColumn(label: Expanded(child: Text('Valor Unitário', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                const DataColumn(label: Expanded(child: Text('Valor Total', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
                const DataColumn(label: Text('')),
              ],
              rows: _buildTableRows(fmt),
            ),
          ),
      ],
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

  List<DataRow> _buildTableRows(NumberFormat fmt) {
    final isLote = _tipoEstimativa == 'lote';
    final rows = <DataRow>[];

    if (isLote) {
      for (int l = 0; l < _lotes.length; l++) {
        final lote = _lotes[l];
        for (int i = 0; i < lote.itens.length; i++) {
          rows.add(_buildDataRow(
            item: lote.itens[i],
            loteIndex: l,
            itemIndex: i,
            isLote: true,
          ));
        }
      }
    } else {
      for (int i = 0; i < _itens.length; i++) {
        rows.add(_buildDataRow(
          item: _itens[i],
          loteIndex: null,
          itemIndex: i,
          isLote: false,
        ));
      }
    }
    return rows;
  }

  DataRow _buildDataRow({
    required EstimativaItem item,
    required int? loteIndex,
    required int itemIndex,
    required bool isLote,
  }) {
    final statusIcon = item.orcamentos.length >= 3
        ? const Tooltip(message: '3 ou mais orçamentos', child: Icon(Icons.check_circle, color: Colors.green, size: 16))
        : item.orcamentos.isNotEmpty
            ? const Tooltip(message: 'Menos de 3 orçamentos', child: Icon(Icons.warning, color: Colors.amber, size: 16))
            : const Tooltip(message: 'Sem orçamentos', child: Icon(Icons.cancel, color: Colors.red, size: 16));

    return DataRow(
      cells: [
        if (isLote)
          DataCell(
            HoverCellText(
              text: '${_lotes[loteIndex ?? 0].numero}',
              onTap: () => _editLote(loteIndex ?? 0),
              textAlign: TextAlign.center,
              alignment: Alignment.center,
            ),
          ),
        DataCell(
          HoverCellText(
            text: '${item.numero}',
            onTap: () => isLote ? _editLoteItem(loteIndex ?? 0, itemIndex) : _editItem(itemIndex),
            textAlign: TextAlign.center,
            alignment: Alignment.center,
          ),
        ),
        DataCell(
          HoverCellText(
            text: item.descricao,
            onTap: () => isLote ? _editLoteItem(loteIndex ?? 0, itemIndex) : _editItem(itemIndex),
            width: 200,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.justify,
          ),
        ),
        DataCell(
          Center(
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
        DataCell(Center(child: Text(item.unidade, textAlign: TextAlign.center))),
        ..._fornecedores.map((f) {
          final orc = item.orcamentos.where((o) => o.fornecedorId == f.id).firstOrNull;
          return DataCell(
            Center(
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
                width: 80,
              ),
            ),
          );
        }),
        DataCell(Center(child: Tooltip(
          message: 'Cálculo atual: ${_calculoGlobal == 'min' ? 'Menor' : _calculoGlobal == 'avg' ? 'Média' : 'Mediana'}',
          child: Text(formatBRL(item.getValorReferenciaUnitario(_calculoGlobal)), textAlign: TextAlign.center),
        ))),
        DataCell(Center(child: Text(formatBRL(item.getValorTotal(_calculoGlobal)), textAlign: TextAlign.center))),
        DataCell(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                statusIcon,
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  tooltip: 'Excluir Item',
                  onPressed: () => _confirmDeleteItem(loteIndex, itemIndex),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteItem(int? loteIndex, int itemIndex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Excluir Item'),
          content: const Text('Deseja excluir este item e todos os seus orçamentos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        if (loteIndex != null) {
          final lote = _lotes[loteIndex];
          final newItens = List<EstimativaItem>.from(lote.itens)..removeAt(itemIndex);
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
              return it.copyWith(orcamentos: it.orcamentos.where((o) => o.fornecedorId != fornecedor.id).toList());
            }).toList();
            _lotes[i] = _lotes[i].copyWith(itens: newItens);
          }
        } else {
          for (int i = 0; i < _itens.length; i++) {
            _itens[i] = _itens[i].copyWith(
              orcamentos: _itens[i].orcamentos.where((o) => o.fornecedorId != fornecedor.id).toList(),
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

  void _updateItemOrcamento(int? loteIndex, int itemIndex, String fornecedorId, double? novoValor) {
    setState(() {
      if (loteIndex != null) {
        final lote = _lotes[loteIndex];
        final item = lote.itens[itemIndex];
        final orcs = List<EstimativaOrcamento>.from(item.orcamentos);
        orcs.removeWhere((o) => o.fornecedorId == fornecedorId);
        if (novoValor != null) {
          orcs.add(EstimativaOrcamento(fornecedorId: fornecedorId, valorUnitario: novoValor));
        }
        final newItens = List<EstimativaItem>.from(lote.itens);
        newItens[itemIndex] = item.copyWith(orcamentos: orcs);
        _lotes[loteIndex] = lote.copyWith(itens: newItens);
      } else {
        final item = _itens[itemIndex];
        final orcs = List<EstimativaOrcamento>.from(item.orcamentos);
        orcs.removeWhere((o) => o.fornecedorId == fornecedorId);
        if (novoValor != null) {
          orcs.add(EstimativaOrcamento(fornecedorId: fornecedorId, valorUnitario: novoValor));
        }
        _itens[itemIndex] = item.copyWith(orcamentos: orcs);
      }
    });
  }

  Future<void> _importarOrcamentoIa() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

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

    final orcamentoResult = await showGeminiOrcamentoImportDialog(
      context: context,
      ref: ref,
      pdfPath: path,
      itensEstimativa: itensEstimativa,
    );

    if (orcamentoResult == null) return;

    // Aplicar os resultados
    setState(() {
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
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento importado com sucesso!')),
      );
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
              _buildItensOuLotesSection(),
            ],
          ),
        ),
      ),
    );
  }
}
