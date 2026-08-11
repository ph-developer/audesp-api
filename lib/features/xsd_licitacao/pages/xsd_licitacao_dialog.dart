// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/audesp_async_button.dart';
import '../../../shared/widgets/audesp_checkbox.dart';
import '../../../shared/widgets/audesp_cpf_cnpj_field.dart';
import '../../../shared/widgets/audesp_currency_field.dart';
import '../../../shared/widgets/audesp_date_picker_field.dart';
import '../../../shared/widgets/audesp_delete_dialog.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_field_row.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_spacing.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../edital/domain/edital_domain.dart';
import '../models/xsd_licitacao_models.dart';
import '../providers/xsd_comissao_provider.dart';
import '../services/xsd_domain_rules.dart';
import '../services/xsd_export_service.dart';
import '../services/xsd_generation_service.dart';
import '../services/xsd_source_normalizer.dart';
import '../services/xsd_validator.dart';

class XsdLicitacaoDialog extends ConsumerStatefulWidget {
  final int licitacaoId;
  final int editalId;

  const XsdLicitacaoDialog({
    super.key,
    required this.licitacaoId,
    required this.editalId,
  });

  @override
  ConsumerState<XsdLicitacaoDialog> createState() => _XsdLicitacaoDialogState();
}

class _XsdLicitacaoDialogState extends ConsumerState<XsdLicitacaoDialog> {
  static const _assignmentLabels = <int, String>{
    1: 'Presidente',
    2: 'Membro',
    3: 'Pregoeiro',
    4: 'Equipe de apoio',
    5: 'Servidor designado',
    6: 'Leiloeiro',
    7: 'Secretário',
    8: 'Autoridade do pregão',
    9: 'Responsável',
    10: 'Autoridade do convite',
    11: 'Agente de contratação',
    12: 'Comissão de contratação',
  };
  static const _roleNatureLabels = <int, String>{
    1: 'Efetivo',
    2: 'Comissionado',
    3: 'Agente político',
    4: 'Empregado temporário',
    5: 'Empregado público',
    6: 'Outros',
  };

  bool _loading = true;
  bool _generating = false;
  XsdLicitacaoSource? _source;
  XsdLicitacaoVariant? _variant;
  XsdLicitacaoProfile _profile = XsdLicitacaoProfile(
    anoAtoDesignacao: DateTime.now().year,
  );
  DateTime? _lastGeneration;
  final _atoNumero = TextEditingController();
  final _recursosValor = TextEditingController();
  final _outrasFontes = TextEditingController();
  final _memberName = TextEditingController();
  final _memberCpf = TextEditingController();
  final _memberRole = TextEditingController();
  int _memberRoleNature = 1;
  bool _addingMember = false;
  final Set<int> _deletingMemberIds = {};
  final List<XsdComissaoMembro> _commission = [];
  final ValueNotifier<int> _commissionRevision = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _atoNumero.dispose();
    _recursosValor.dispose();
    _outrasFontes.dispose();
    _memberName.dispose();
    _memberCpf.dispose();
    _memberRole.dispose();
    _commissionRevision.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final licitacao = await ref
          .read(licitacoesDaoProvider)
          .findById(widget.licitacaoId);
      final edital = await ref
          .read(editaisDaoProvider)
          .findById(widget.editalId);
      if (licitacao == null || edital == null) {
        throw const FormatException(
          'Licitação ou edital vinculado não encontrado.',
        );
      }
      final source = const XsdSourceNormalizer().normalize(
        edital: jsonDecode(edital.documentoJson) as Map<String, dynamic>,
        licitacao: jsonDecode(licitacao.documentoJson) as Map<String, dynamic>,
      );
      final variant = XsdDomainRules.selectVariant(source);
      final saved = await ref
          .read(xsdLicitacaoProfilesDaoProvider)
          .findByLicitacaoId(widget.licitacaoId);
      final mergedProfile = const XsdSourceNormalizer().mergeProfile(
        source: source,
        persisted: saved,
      );
      final last = await ref
          .read(xsdLicitacaoLogsDaoProvider)
          .getLastGenerationDate(widget.licitacaoId);
      if (!mounted) return;
      setState(() {
        _source = source;
        _variant = variant;
        _profile = mergedProfile;
        _commission.addAll(_profile.comissao);
        _atoNumero.text = _profile.numAtoDesignacao;
        _recursosValor.text = _profile.recursos.valor?.toString() ?? '';
        _outrasFontes.text = _profile.recursos.outrasFontesDescricao ?? '';
        _lastGeneration = last;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      AudespSnackBar.error(context, error.toString());
      Navigator.of(context).pop();
    }
  }

  Future<void> _export() async {
    final source = _source!;
    setState(() => _generating = true);
    try {
      final profile = _profile.copyWith(
        comissao: List.unmodifiable(_commission),
        numAtoDesignacao: _atoNumero.text.trim(),
        anoAtoDesignacao:
            (_profile.atoDesignacaoData ?? _profile.atoDesignacaoInicio)
                ?.year ??
            _profile.anoAtoDesignacao,
      );
      final defaultFileName = XsdDomainRules.defaultFileName(source, _variant!);
      final output = await FilePicker.saveFile(
        dialogTitle: 'Salvar XML e Markdown validados',
        fileName: '$defaultFileName.xml',
        type: FileType.custom,
        allowedExtensions: const ['xml'],
      );
      if (output == null) return;
      final service = XsdGenerationService(
        validator: const XsdValidator(),
        exporter: const XsdExportService(),
        profiles: ref.read(xsdLicitacaoProfilesDaoProvider),
        logs: ref.read(xsdLicitacaoLogsDaoProvider),
      );
      await service.generateAndSave(
        licitacaoId: widget.licitacaoId,
        source: source,
        profile: profile,
        outputPath: output,
      );
      if (!mounted) return;
      AudespSnackBar.success(
        context,
        'XML validado no XSD ${_variant!.name.toUpperCase()} e par XML/Markdown salvo.',
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        AudespSnackBar.error(context, 'Exportação bloqueada!\n$error');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _addCommissionMember() async {
    final cpf = _memberCpf.text.replaceAll(RegExp(r'\D'), '');
    final name = _memberName.text.trim();
    final role = _memberRole.text.trim();
    if (cpf.length != 11 || name.isEmpty || role.isEmpty) {
      AudespSnackBar.error(
        context,
        'Informe nome, CPF com 11 dígitos e cargo do integrante.',
      );
      return;
    }
    setState(() => _addingMember = true);
    _touchCommission();
    try {
      final currentCatalog = await ref.read(xsdComissaoProvider.future);
      final existing = currentCatalog
          .where((item) => item.cpf.replaceAll(RegExp(r'\D'), '') == cpf)
          .firstOrNull;
      if (existing != null) {
        if (!mounted) return;
        setState(() {
          if (_selectedMember(existing.cpf) == null) {
            _commission.add(existing.copyWith(atribuicao: 2));
          }
        });
        _touchCommission();
        AudespSnackBar.success(
          context,
          'Esse CPF já estava cadastrado e foi selecionado.',
        );
        return;
      }
      final member = XsdComissaoMembro(
        cpf: cpf,
        nome: name,
        atribuicao: 2,
        cargo: role,
        naturezaCargo: _memberRoleNature,
      );
      await ref.read(xsdComissaoProvider.notifier).addMembro(member);
      final catalog = await ref.read(xsdComissaoProvider.future);
      final inserted = catalog.where((item) => item.cpf == cpf).lastOrNull;
      if (!mounted) return;
      setState(() {
        if (inserted != null && _selectedMember(inserted.cpf) == null) {
          _commission.add(inserted);
        }
        _memberName.clear();
        _memberCpf.clear();
        _memberRole.clear();
      });
      _touchCommission();
      AudespSnackBar.success(
        context,
        'Integrante cadastrado e selecionado para esta licitação.',
      );
    } catch (error) {
      if (mounted) {
        AudespSnackBar.error(context, 'Erro ao cadastrar integrante: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _addingMember = false);
        _touchCommission();
      }
    }
  }

  Future<void> _deleteCommissionMember(XsdComissaoMembro member) async {
    final id = member.id;
    if (id == null) return;
    final confirmed = await showAudespDeleteDialog(
      context: context,
      title: 'Excluir integrante',
      entityName: member.nome,
      entityLabel: 'o integrante',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingMemberIds.add(id));
    _touchCommission();
    try {
      await ref.read(xsdComissaoProvider.notifier).removeMembro(id);
      if (!mounted) return;
      setState(() {
        _commission.removeWhere(
          (item) => _digits(item.cpf) == _digits(member.cpf),
        );
      });
      _touchCommission();
      AudespSnackBar.success(context, 'Integrante excluído do catálogo.');
    } catch (error) {
      if (mounted) {
        AudespSnackBar.error(context, 'Erro ao excluir integrante: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _deletingMemberIds.remove(id));
        _touchCommission();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final source = _source!;
    final direct = _variant == XsdLicitacaoVariant.nao3;
    return AlertDialog(
      title: Text('Gerar XML'),
      content: SizedBox(
        width: 860,
        height: 680,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_lastGeneration != null)
                Text(
                  'Última exportação validada: ${_lastGeneration!.toLocal()}',
                ),
              AudespFieldRow(
                children: [
                  AudespFieldRowItem(
                    child: _readOnly(
                      'Edital',
                      '${source.numeroCompra}/${source.anoCompra}',
                    ),
                  ),
                  AudespFieldRowItem(
                    child: _readOnly('Processo', source.numeroProcesso),
                  ),
                  AudespFieldRowItem(
                    child: _readOnly(
                      'Modalidade PNCP',
                      kModalidades[source.modalidadeId] ??
                          '${source.modalidadeId} - Modalidade não identificada',
                    ),
                  ),
                ],
              ),
              _readOnly('Objeto', source.objeto),
              _readOnly('Itens importados', source.itens.length.toString()),
              const SizedBox(height: 12),
              AudespDropdown<XsdObjetoClassificacao>(
                label: 'Classificação obrigatória do objeto',
                value: _profile.objetoClassificacao,
                items: const {
                  XsdObjetoClassificacao.comprasServicos: 'Compras e serviços',
                  XsdObjetoClassificacao.tecnologiaInformacao:
                      'Tecnologia da informação',
                  XsdObjetoClassificacao.obrasEngenharia: 'Obras e engenharia',
                },
                onChanged: (value) => setState(
                  () =>
                      _profile = _profile.copyWith(objetoClassificacao: value),
                ),
              ),
              AudespSpacing.verticalSm,
              AudespFieldRow(
                children: [
                  AudespFieldRowItem(
                    child: AudespCheckbox(
                      label: 'Há subcontratação?',
                      value: _profile.subcontratacao,
                      onChanged: (value) => setState(
                        () =>
                            _profile = _profile.copyWith(subcontratacao: value),
                      ),
                    ),
                  ),
                  AudespFieldRowItem(
                    child: AudespCheckbox(
                      label: 'Há inversão de fases? (Lei 13.121/2008)',
                      value: _profile.lei13121,
                      readOnly: direct,
                      onChanged: (value) => setState(
                        () => _profile = _profile.copyWith(lei13121: value),
                      ),
                    ),
                  ),
                ],
              ),
              if (!direct) ...[
                AudespFieldRow(
                  children: [
                    AudespFieldRowItem(
                      child: _readOnly(
                        'Data da Adjudicação/Homologação',
                        _formatDate(_profile.situacaoData),
                      ),
                    ),
                    AudespFieldRowItem(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: AudespDatePickerField(
                          label: 'Publicação da Adjudicação/Homologação',
                          value: _profile.homologacaoData,
                          onChanged: (value) => setState(
                            () => _profile = _profile.copyWith(
                              homologacaoData: value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (direct) ...[
                _readOnly(
                  'Amparo legal',
                  source.amparoLegalId == null
                      ? 'Não informado no edital'
                      : kAmparosLegais[source.amparoLegalId] ??
                            'Código ${source.amparoLegalId}',
                ),
                const SizedBox(height: 12),
                AudespDatePickerField(
                  label: 'Data de finalização do processo (publicação)',
                  value: _profile.finalizacaoProcessoData,
                  onChanged: (value) => setState(
                    () => _profile = _profile.copyWith(
                      finalizacaoProcessoData: value,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              AudespFieldRow(
                children: [
                  AudespFieldRowItem(
                    child: _readOnly(
                      'Existe parecer técnico-jurídico',
                      _yesNo(_profile.parecerTecnicoJuridico),
                    ),
                  ),
                  if (!direct)
                    AudespFieldRowItem(
                      child: _readOnly(
                        'Exige quitação de tributos',
                        _tributosQuitacaoLabel(),
                      ),
                    ),
                ],
              ),
              if (direct)
                AudespCheckbox(
                  label:
                      'Contratação enquadrada no art. 3º da Resolução 07/2014?',
                  value: _profile.resolucao072014,
                  onChanged: (value) => setState(
                    () => _profile = _profile.copyWith(resolucao072014: value),
                  ),
                ),
              AudespFieldRow(
                children: [
                  AudespFieldRowItem(
                    child: _readOnly(
                      'Existe reserva orçamentária',
                      _yesNo(_profile.recursos.declarados),
                    ),
                  ),
                  AudespFieldRowItem(
                    child: _readOnly(
                      'Fontes de recursos',
                      !_profile.recursos.declarados
                          ? 'Não se aplica'
                          : _profile.recursos.fontes.isEmpty
                          ? 'Não informadas'
                          : _profile.recursos.fontes
                                .map(_resourceSourceLabel)
                                .join(', '),
                    ),
                  ),
                ],
              ),
              if (_profile.recursos.declarados) ...[
                AudespFieldRow(
                  children: [
                    AudespFieldRowItem(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: AudespCurrencyField(
                          label: 'Valor reservado',
                          controller: _recursosValor,
                          onChanged: (_) => _updateResources(),
                        ),
                      ),
                    ),
                    AudespFieldRowItem(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: AudespDatePickerField(
                          label: 'Data da reserva',
                          value: _profile.recursos.data,
                          onChanged: (value) => _updateResources(data: value),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_profile.recursos.fontes.contains(6))
                  AudespTextField(
                    label: 'Descrição das outras fontes',
                    controller: _outrasFontes,
                    onChanged: (_) => _updateResources(),
                  ),
                if (_profile.recursos.fontes.contains(2))
                  _buildConveniosSection(federal: false),
                if (_profile.recursos.fontes.contains(5))
                  _buildConveniosSection(federal: true),
                if (_profile.recursos.fontes.contains(7))
                  _buildOperacoesCreditoSection(),
              ],
              _buildCommissionSummary(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _generating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AudespAsyncButton.icon(
          label: 'Validar e Salvar',
          icon: Icons.verified_outlined,
          onPressed: _generating ? null : _export,
        ),
      ],
    );
  }

  Widget _buildCommissionSummary() {
    const types = {1: 'Permanente', 2: 'Especial', 3: 'Servidor designado'};
    final portaria = _atoNumero.text.trim();
    return Padding(
      padding: const EdgeInsets.only(top: AudespSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Comissão de licitação',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${types[_profile.tipoComissao] ?? 'Tipo não informado'} · '
              '${_commission.length} integrante(s) selecionado(s)',
            ),
            subtitle: Text(_portariaSummary(portaria)),
            trailing: OutlinedButton.icon(
              onPressed: _openCommissionDialog,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Configurar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCommissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Comissão de licitação'),
        content: SizedBox(
          width: 920,
          height: 620,
          child: Consumer(
            builder: (context, dialogRef, _) => ValueListenableBuilder<int>(
              valueListenable: _commissionRevision,
              builder: (context, _, _) => SingleChildScrollView(
                child: _buildCommissionDialogContent(dialogContext, dialogRef),
              ),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _buildCommissionDialogContent(
    BuildContext dialogContext,
    WidgetRef dialogRef,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Tipo da comissão',
                value: _profile.tipoComissao,
                items: const {
                  1: 'Permanente',
                  2: 'Especial',
                  3: 'Servidor designado',
                },
                onChanged: (value) {
                  setState(
                    () => _profile = _profile.copyWith(tipoComissao: value),
                  );
                  _touchCommission();
                },
              ),
            ),
            AudespFieldRowItem(
              child: AudespTextField(
                label: 'Número da Portaria',
                controller: _atoNumero,
                onChanged: (_) => _touchCommission(),
              ),
            ),
            AudespFieldRowItem(
              child: AudespDatePickerField(
                label: 'Data da Portaria',
                value: _profile.atoDesignacaoData,
                onChanged: (value) {
                  setState(() {
                    _profile = _profile.copyWith(
                      atoDesignacaoData: value,
                      anoAtoDesignacao: value?.year,
                    );
                  });
                  _touchCommission();
                },
              ),
            ),
          ],
        ),
        AudespSpacing.verticalLg,
        Text(
          'Cadastrar integrante no catálogo',
          style: Theme.of(dialogContext).textTheme.titleSmall,
        ),
        AudespSpacing.verticalSm,
        AudespFieldRow(
          children: [
            AudespFieldRowItem(
              child: AudespTextField(label: 'Nome', controller: _memberName),
            ),
            AudespFieldRowItem(
              child: AudespCpfCnpjField(label: 'CPF', controller: _memberCpf),
            ),
            AudespFieldRowItem(
              child: AudespTextField(label: 'Cargo', controller: _memberRole),
            ),
            AudespFieldRowItem(
              child: AudespDropdown<int>(
                label: 'Natureza do cargo',
                value: _memberRoleNature,
                items: _roleNatureLabels,
                onChanged: (value) {
                  setState(() => _memberRoleNature = value ?? 1);
                  _touchCommission();
                },
              ),
            ),
            AudespFieldRowItem(
              width: 32,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AudespIconButton(
                    icon: Icons.add,
                    tooltip: 'Cadastrar e selecionar integrante',
                    onPressed: _addingMember ? null : _addCommissionMember,
                    outlined: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        AudespSpacing.verticalMd,
        Text(
          'Integrantes do catálogo',
          style: Theme.of(dialogContext).textTheme.titleSmall,
        ),
        dialogRef
            .watch(xsdComissaoProvider)
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AudespSpacing.md),
                child: LinearProgressIndicator(),
              ),
              error: (error, _) => Text('Catálogo indisponível: $error'),
              data: (members) => members.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Nenhum integrante cadastrado. Use o formulário acima.',
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_commission.length} integrante(s) selecionado(s)',
                        ),
                        ...members.map(_buildCommissionMemberRow),
                      ],
                    ),
            ),
      ],
    );
  }

  Widget _buildCommissionMemberRow(XsdComissaoMembro member) {
    final selected = _selectedMember(member.cpf);
    return Padding(
      padding: const EdgeInsets.only(top: AudespSpacing.sm),
      child: AudespFieldRow(
        children: [
          AudespFieldRowItem(
            flex: 2,
            child: AudespCheckbox(
              label:
                  '${member.nome} · ${AudespCpfCnpjField.formatDocument(member.cpf)} · '
                  '${member.cargo} (${_roleNatureLabels[member.naturezaCargo] ?? 'Natureza ${member.naturezaCargo}'})',
              value: selected != null,
              onChanged: (checked) {
                setState(() {
                  _commission.removeWhere(
                    (item) => _digits(item.cpf) == _digits(member.cpf),
                  );
                  if (checked) {
                    _commission.add(member.copyWith(atribuicao: 2));
                  }
                });
                _touchCommission();
              },
            ),
          ),
          AudespFieldRowItem(
            child: AudespDropdown<int>(
              label: 'Atribuição nesta licitação',
              value: selected?.atribuicao ?? 2,
              items: _assignmentLabels,
              enabled: selected != null,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  final index = _commission.indexWhere(
                    (item) => _digits(item.cpf) == _digits(member.cpf),
                  );
                  if (index >= 0) {
                    _commission[index] = _commission[index].copyWith(
                      atribuicao: value,
                    );
                  }
                });
                _touchCommission();
              },
            ),
          ),
          AudespFieldRowItem(
            width: 32,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AudespIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Excluir integrante',
                  color: Theme.of(context).colorScheme.error,
                  onPressed:
                      member.id == null ||
                          _deletingMemberIds.contains(member.id)
                      ? null
                      : () => _deleteCommissionMember(member),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _touchCommission() => _commissionRevision.value++;

  Widget _readOnly(String label, String value) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value.isEmpty ? 'Não informado' : value),
    trailing: const Tooltip(
      message: 'Importado; somente leitura',
      child: Icon(Icons.lock_outline, size: 18),
    ),
  );

  Widget _buildConveniosSection({required bool federal}) {
    final values = federal
        ? _profile.recursos.conveniosFederais
        : _profile.recursos.conveniosEstaduais;
    final label = federal ? 'Convênios federais' : 'Convênios estaduais';
    return Padding(
      padding: const EdgeInsets.only(top: AudespSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _editConvenio(federal: federal),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          if (values.isEmpty)
            Text(
              'Nenhum convênio ${federal ? 'federal' : 'estadual'} informado.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ...values.indexed.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${entry.$2.numero}/${entry.$2.ano}'),
              subtitle: Text(
                'Repasse: ${formatBRL(entry.$2.valorRepasse)} · '
                'Contrapartida: ${formatBRL(entry.$2.valorContrapartida)}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        _editConvenio(federal: federal, index: entry.$1),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _removeConvenio(federal: federal, index: entry.$1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperacoesCreditoSection() {
    final values = _profile.recursos.operacoesCredito;
    return Padding(
      padding: const EdgeInsets.only(top: AudespSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operações de crédito',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ...values.indexed.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Contrato ${entry.$2.contratoNumero}/${entry.$2.contratoAno}',
              ),
              subtitle: Text(
                '${entry.$2.agenteFinanceiro.isEmpty ? 'Agente não informado' : entry.$2.agenteFinanceiro} · '
                'Repasse: ${formatBRL(entry.$2.valorRepasse)}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editOperacaoCredito(index: entry.$1),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeOperacaoCredito(entry.$1),
                  ),
                ],
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _editOperacaoCredito,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar operação de crédito'),
          ),
        ],
      ),
    );
  }

  void _updateResources({DateTime? data}) {
    setState(() {
      final current = _profile.recursos;
      _profile = _profile.copyWith(
        recursos: XsdRecursosProfile(
          declarados: current.declarados,
          valor: parseBrCurrencyOrNull(_recursosValor.text.trim()),
          data: data ?? current.data,
          fontes: current.fontes,
          outrasFontesDescricao: _outrasFontes.text.trim(),
          conveniosEstaduais: current.conveniosEstaduais,
          conveniosFederais: current.conveniosFederais,
          operacoesCredito: current.operacoesCredito,
        ),
      );
    });
  }

  Future<void> _editConvenio({required bool federal, int? index}) async {
    final currentValues = federal
        ? _profile.recursos.conveniosFederais
        : _profile.recursos.conveniosEstaduais;
    final current = index == null ? null : currentValues[index];
    final formKey = GlobalKey<FormState>();
    final numero = TextEditingController(text: current?.numero ?? '');
    final ano = TextEditingController(
      text: (current?.ano ?? DateTime.now().year).toString(),
    );
    final repasse = TextEditingController(
      text: doubleToBrString(current?.valorRepasse),
    );
    final contrapartida = TextEditingController(
      text: doubleToBrString(current?.valorContrapartida),
    );
    final result = await showDialog<XsdConvenio>(
      context: context,
      builder: (dialogContext) => _ControllerOwner(
        controllers: [numero, ano, repasse, contrapartida],
        child: AlertDialog(
          title: Text(
            '${index == null ? 'Adicionar' : 'Editar'} convênio ${federal ? 'federal' : 'estadual'}',
          ),
          content: SizedBox(
            width: 620,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AudespFieldRow(
                    children: [
                      AudespFieldRowItem(
                        flex: 2,
                        child: AudespTextField(
                          label: 'Número do convênio',
                          controller: numero,
                          maxLength: 12,
                          validator: (value) =>
                              RegExp(
                                r'^[a-zA-Z0-9-]{1,12}$',
                              ).hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Use até 12 letras, números ou hífen',
                        ),
                      ),
                      AudespFieldRowItem(
                        child: AudespTextField(
                          label: 'Ano',
                          controller: ano,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: _validateYear,
                        ),
                      ),
                    ],
                  ),
                  AudespSpacing.verticalMd,
                  AudespFieldRow(
                    children: [
                      AudespFieldRowItem(
                        child: AudespCurrencyField(
                          label: 'Valor do repasse',
                          controller: repasse,
                        ),
                      ),
                      AudespFieldRowItem(
                        child: AudespCurrencyField(
                          label: 'Valor da contrapartida',
                          controller: contrapartida,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(
                  dialogContext,
                  XsdConvenio(
                    numero: numero.text.trim(),
                    ano: int.parse(ano.text.trim()),
                    valorRepasse: parseBrCurrencyOrNull(repasse.text.trim())!,
                    valorContrapartida: parseBrCurrencyOrNull(
                      contrapartida.text.trim(),
                    )!,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final updated = List<XsdConvenio>.from(currentValues);
    index == null ? updated.add(result) : updated[index] = result;
    _setResourceDetails(
      conveniosEstaduais: federal ? null : updated,
      conveniosFederais: federal ? updated : null,
    );
  }

  void _removeConvenio({required bool federal, required int index}) {
    final updated = List<XsdConvenio>.from(
      federal
          ? _profile.recursos.conveniosFederais
          : _profile.recursos.conveniosEstaduais,
    )..removeAt(index);
    _setResourceDetails(
      conveniosEstaduais: federal ? null : updated,
      conveniosFederais: federal ? updated : null,
    );
  }

  Future<void> _editOperacaoCredito({int? index}) async {
    final values = _profile.recursos.operacoesCredito;
    final current = index == null ? null : values[index];
    final formKey = GlobalKey<FormState>();
    final agente = TextEditingController(text: current?.agenteFinanceiro ?? '');
    final contrato = TextEditingController(text: current?.contratoNumero ?? '');
    final ano = TextEditingController(
      text: (current?.contratoAno ?? DateTime.now().year).toString(),
    );
    final repasse = TextEditingController(
      text: doubleToBrString(current?.valorRepasse),
    );
    final result = await showDialog<XsdOperacaoCredito>(
      context: context,
      builder: (dialogContext) => _ControllerOwner(
        controllers: [agente, contrato, ano, repasse],
        child: AlertDialog(
          title: Text(
            '${index == null ? 'Adicionar' : 'Editar'} operação de crédito',
          ),
          content: SizedBox(
            width: 620,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AudespTextField(
                    label: 'Agente financeiro (opcional)',
                    controller: agente,
                    maxLength: 50,
                  ),
                  AudespSpacing.verticalMd,
                  AudespFieldRow(
                    children: [
                      AudespFieldRowItem(
                        flex: 2,
                        child: AudespTextField(
                          label: 'Número do contrato',
                          controller: contrato,
                          maxLength: 20,
                          validator: (value) => value?.trim().isNotEmpty == true
                              ? null
                              : 'Obrigatório',
                        ),
                      ),
                      AudespFieldRowItem(
                        child: AudespTextField(
                          label: 'Ano',
                          controller: ano,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: _validateYear,
                        ),
                      ),
                    ],
                  ),
                  AudespSpacing.verticalMd,
                  AudespCurrencyField(
                    label: 'Valor do repasse',
                    controller: repasse,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(
                  dialogContext,
                  XsdOperacaoCredito(
                    agenteFinanceiro: agente.text.trim(),
                    contratoNumero: contrato.text.trim(),
                    contratoAno: int.parse(ano.text.trim()),
                    valorRepasse: parseBrCurrencyOrNull(repasse.text.trim())!,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final updated = List<XsdOperacaoCredito>.from(values);
    index == null ? updated.add(result) : updated[index] = result;
    _setResourceDetails(operacoesCredito: updated);
  }

  void _removeOperacaoCredito(int index) {
    final updated = List<XsdOperacaoCredito>.from(
      _profile.recursos.operacoesCredito,
    )..removeAt(index);
    _setResourceDetails(operacoesCredito: updated);
  }

  void _setResourceDetails({
    List<XsdConvenio>? conveniosEstaduais,
    List<XsdConvenio>? conveniosFederais,
    List<XsdOperacaoCredito>? operacoesCredito,
  }) {
    setState(() {
      final current = _profile.recursos;
      _profile = _profile.copyWith(
        recursos: XsdRecursosProfile(
          declarados: current.declarados,
          valor: current.valor,
          data: current.data,
          fontes: current.fontes,
          outrasFontesDescricao: current.outrasFontesDescricao,
          conveniosEstaduais: conveniosEstaduais ?? current.conveniosEstaduais,
          conveniosFederais: conveniosFederais ?? current.conveniosFederais,
          operacoesCredito: operacoesCredito ?? current.operacoesCredito,
        ),
      );
    });
  }

  String? _validateYear(String? value) {
    final year = int.tryParse(value?.trim() ?? '');
    return year != null && year >= 1000 && year <= 9999
        ? null
        : 'Informe quatro dígitos';
  }

  XsdComissaoMembro? _selectedMember(String cpf) => _commission
      .where((member) => _digits(member.cpf) == _digits(cpf))
      .firstOrNull;

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _yesNo(bool value) => value ? 'Sim' : 'Não';

  String _tributosQuitacaoLabel() {
    final tipos = <String>[
      if (_profile.tributosFederais) 'Federais',
      if (_profile.tributosEstaduais) 'Estaduais',
      if (_profile.tributosMunicipais) 'Municipais',
    ];
    if (tipos.isEmpty) return 'Nenhum';
    if (tipos.length == 1) return tipos.single;
    return '${tipos.sublist(0, tipos.length - 1).join(', ')} e ${tipos.last}';
  }

  String _formatDate(DateTime? value) => value == null
      ? 'Não informada nos itens'
      : '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _portariaSummary(String numero) {
    final data = _profile.atoDesignacaoData;
    if (numero.isEmpty && data == null) return 'Portaria não informada';
    final prefix = numero.isEmpty ? 'Portaria sem número' : 'Portaria $numero';
    if (data == null) return prefix;
    return '$prefix de ${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _resourceSourceLabel(int value) =>
      const {
        1: 'Tesouro',
        2: 'Convênios estaduais',
        3: 'Fundos especiais',
        4: 'Administração indireta',
        5: 'Convênios federais',
        6: 'Outras fontes',
        7: 'Operações de crédito',
        8: 'Emendas parlamentares',
      }[value] ??
      'Fonte $value';
}

/// Mantém os controladores vivos durante toda a animação de fechamento da rota
/// e os descarta somente quando o conteúdo do diálogo é realmente desmontado.
class _ControllerOwner extends StatefulWidget {
  final List<TextEditingController> controllers;
  final Widget child;

  const _ControllerOwner({required this.controllers, required this.child});

  @override
  State<_ControllerOwner> createState() => _ControllerOwnerState();
}

class _ControllerOwnerState extends State<_ControllerOwner> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
