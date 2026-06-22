import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/section_card.dart';
import '../../../core/database/database_providers.dart';
import '../estimativa_providers.dart';
import '../models/estimativa_model.dart';
import '../models/estimativa_item_model.dart';
import '../models/estimativa_lote_model.dart';
import '../widgets/estimativa_item_dialog.dart';
import '../widgets/estimativa_lote_dialog.dart';
import '../services/estimativa_pdf_service.dart';
import 'package:intl/intl.dart';

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
  final _tipoEstimativaKey = GlobalKey<FormFieldState<String>>();
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
              child: TextFormField(
                controller: _numeroCtrl,
                decoration: const InputDecoration(labelText: 'Número *'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _anoCtrl,
                decoration: const InputDecoration(labelText: 'Ano *'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _objetoCtrl,
          decoration: const InputDecoration(
            labelText: 'Objeto da Licitação *',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: _tipoEstimativaKey,
                initialValue: _tipoEstimativa,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Estimativa *',
                ),
                items: const [
                  DropdownMenuItem(value: 'item', child: Text('Por Item')),
                  DropdownMenuItem(value: 'lote', child: Text('Por Lote')),
                ],
                onChanged: (v) async {
                  if (v != null && v != _tipoEstimativa) {
                    if (_itens.isNotEmpty || _lotes.isNotEmpty) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Alterar Tipo de Estimativa?'),
                          content: const Text(
                              'Ao alterar o tipo de estimativa, todos os itens e lotes já adicionados serão apagados. Deseja continuar?'),
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
                        _tipoEstimativaKey.currentState?.reset();
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
              child: DropdownButtonFormField<String>(
                initialValue: _calculoGlobal,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cálculo *',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'min',
                    child: Text('Menor Preço (Mínimo)'),
                  ),
                  DropdownMenuItem(value: 'avg', child: Text('Média')),
                  DropdownMenuItem(value: 'median', child: Text('Mediana')),
                ],
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
              child: DropdownButtonFormField<bool>(
                initialValue: _registroPrecos,
                decoration: const InputDecoration(
                  labelText: 'Registro de Preços? *',
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Sim')),
                  DropdownMenuItem(value: false, child: Text('Não')),
                ],
                onChanged: (v) => setState(() => _registroPrecos = v ?? false),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<bool>(
                initialValue: _temGarantia,
                decoration: const InputDecoration(
                  labelText: 'Exige Garantia? *',
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Sim')),
                  DropdownMenuItem(value: false, child: Text('Não')),
                ],
                onChanged: (v) => setState(() => _temGarantia = v ?? false),
              ),
            ),
          ],
        ),
        if (_temGarantia) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _periodoGarantiaCtrl,
            decoration: const InputDecoration(
              labelText: 'Período da Garantia *',
              hintText: 'Ex: 12 meses',
            ),
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
              child: TextFormField(
                controller: _prazoVigenciaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prazo de Vigência *',
                  hintText: 'Ex: 12 meses',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _formaPagamentoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Forma de Pagamento *',
                  hintText: 'Ex: 30 dias após emissão da NF',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _exclusividadeMeEpp,
          decoration: const InputDecoration(
            labelText: 'Exclusividade ME/EPP *',
          ),
          items: const [
            DropdownMenuItem(
              value: 'nenhuma',
              child: Text('Não exclusiva para ME/EPP'),
            ),
            DropdownMenuItem(
              value: 'exclusiva',
              child: Text('Exclusiva para ME/EPP (Art. 48, I)'),
            ),
            DropdownMenuItem(
              value: 'reservada',
              child: Text('Itens/Lotes reservados para ME/EPP (Art. 48, III)'),
            ),
          ],
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
        TextFormField(
          controller: _fonteRecursoInputCtrl,
          decoration: InputDecoration(
            labelText: 'Nova Fonte (ex: xx/xxxxx)',
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
        TextButton.icon(
          onPressed: isLote ? _addLote : _addItem,
          icon: const Icon(Icons.add),
          label: Text(isLote ? 'Adicionar Lote' : 'Adicionar Item'),
        ),
      ],
      children: [
        if (isLote) ...[
          if (_lotes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Nenhum lote adicionado.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lotes.length,
              itemBuilder: (ctx, i) {
                final lote = _lotes[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${lote.numero}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(
                      lote.descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${lote.itens.length} itens | Total do Lote: ${fmt.format(lote.getValorTotal(_calculoGlobal))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editLote(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => setState(() => _lotes.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ] else ...[
          if (_itens.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Nenhum item adicionado.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _itens.length,
              itemBuilder: (ctx, i) {
                final item = _itens[i];
                final isMensal = item.tipoFornecimento == 'mensal';
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${item.numero}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(
                      item.descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${item.quantidade} ${item.unidade} | '
                      '${isMensal ? "Mensal (${item.quantidadeMeses}m)" : "Única"} | '
                      'Total: ${fmt.format(item.getValorTotal(_calculoGlobal))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.orcamentos.length < 3)
                          const Tooltip(
                            message: 'Menos de 3 orçamentos',
                            child: Icon(
                              Icons.warning_amber,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editItem(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => setState(() => _itens.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  Future<void> _showExclusividadeDialog() async {
    final isLote = _tipoEstimativa == 'lote';
    
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Selecionar ${isLote ? 'Lotes' : 'Itens'} Exclusivos'),
              content: SizedBox(
                width: 400,
                child: isLote
                    ? _lotes.isEmpty
                        ? const Text('Nenhum lote adicionado.')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _lotes.length,
                            itemBuilder: (context, index) {
                              final lote = _lotes[index];
                              return CheckboxListTile(
                                title: Text('Lote ${lote.numero} - ${lote.descricao}'),
                                value: lote.exclusivoMeEpp,
                                onChanged: (v) {
                                  setModalState(() {
                                    _lotes[index] = lote.copyWith(exclusivoMeEpp: v ?? false);
                                  });
                                  setState(() {
                                    _lotes[index] = _lotes[index].copyWith(exclusivoMeEpp: v ?? false);
                                  });
                                },
                              );
                            },
                          )
                    : _itens.isEmpty
                        ? const Text('Nenhum item adicionado.')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _itens.length,
                            itemBuilder: (context, index) {
                              final item = _itens[index];
                              return CheckboxListTile(
                                title: Text('Item ${item.numero} - ${item.descricao}'),
                                value: item.exclusivoMeEpp,
                                onChanged: (v) {
                                  setModalState(() {
                                    _itens[index] = item.copyWith(exclusivoMeEpp: v ?? false);
                                  });
                                  setState(() {
                                    _itens[index] = _itens[index].copyWith(exclusivoMeEpp: v ?? false);
                                  });
                                },
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Concluído'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addLote() async {
    final res = await showEstimativaLoteDialog(
      context: context,
      calculoGlobal: _calculoGlobal,
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
