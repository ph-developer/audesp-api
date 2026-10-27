import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../edital/widgets/pcnp_input_formatter.dart';
import '../../processo/domain/processo_rules.dart';
import '../../processo/processo_providers.dart';

final atasParaAjusteProvider = FutureProvider.autoDispose<List<OpcaoAta>>((
  ref,
) async {
  return ProcessoRules.opcoesAtaParaAjuste(
    await ref.watch(processosProvider.future),
  );
});

Future<Ata?> showAtasParaAjusteDialog({required BuildContext context}) {
  return showAudespDialog<Ata>(
    context: context,
    size: DialogSize.large,
    builder: (_) => const _AtasParaAjusteDialog(),
  );
}

class _AtasParaAjusteDialog extends ConsumerStatefulWidget {
  const _AtasParaAjusteDialog();

  @override
  ConsumerState<_AtasParaAjusteDialog> createState() =>
      _AtasParaAjusteDialogState();
}

class _AtasParaAjusteDialogState extends ConsumerState<_AtasParaAjusteDialog> {
  final _searchCtrl = TextEditingController();
  bool _exibirJaVinculadas = false;
  bool _mostrarBloqueadas = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(atasParaAjusteProvider);

    return AlertDialog(
      title: const Text('Atas para ajuste'),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (opcoes) {
            final candidates = opcoes.where((opcao) {
              if (!_exibirJaVinculadas && opcao.ajustesVinculados > 0) {
                return false;
              }
              return _mostrarBloqueadas || opcao.liberado;
            }).toList();
            final filtered = candidates.where((opcao) {
              return matchesLikeSearch(
                _searchableAtaText(opcao),
                _searchCtrl.text,
              );
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AudespTextField(
                        label: 'Filtrar',
                        controller: _searchCtrl,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : AudespIconButton(
                                icon: Icons.close,
                                tooltip: 'Limpar filtro',
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildCheckbox(
                      label: 'Exibir já vinculadas',
                      value: _exibirJaVinculadas,
                      onChanged: (value) =>
                          setState(() => _exibirJaVinculadas = value),
                    ),
                    const SizedBox(width: 8),
                    _buildCheckbox(
                      label: 'Mostrar bloqueadas',
                      value: _mostrarBloqueadas,
                      onChanged: (value) =>
                          setState(() => _mostrarBloqueadas = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: candidates.isEmpty
                      ? Center(
                          child: Text(
                            _exibirJaVinculadas
                                ? 'Nenhuma ata disponível.'
                                : 'Nenhuma ata enviada de edital SRP aguardando ajuste.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : filtered.isEmpty
                      ? const Center(
                          child: Text('Nenhuma ata para este filtro.'),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final opcao = filtered[index];
                            final ata = opcao.ata;
                            final edital = opcao.processo.edital;
                            final compra = [
                              if (edital.modalidadeLabel.isNotEmpty)
                                edital.modalidadeLabel,
                              if (edital.numeroCompra.isNotEmpty &&
                                  edital.anoCompra != 0)
                                '${edital.numeroCompra}/${edital.anoCompra}',
                            ].join(' ');
                            final count = opcao.ajustesVinculados;

                            return ListTile(
                              enabled: opcao.liberado,
                              leading: const Icon(Icons.assignment_outlined),
                              title: Text(
                                [
                                  PcnpInputFormatter.applyMask(ata.codigoAta),
                                  if (ata.numeroAtaRegistroPreco.isNotEmpty &&
                                      ata.anoAta != 0)
                                    'Ata ${ata.numeroAtaRegistroPreco}/${ata.anoAta}',
                                ].join(' - '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  compra.isEmpty ? edital.codigoEdital : compra,
                                  if (edital.objetoCompra.isNotEmpty)
                                    edital.objetoCompra,
                                  ?opcao.motivoBloqueio,
                                ].join('\n'),
                                maxLines: opcao.liberado ? 3 : 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: count > 0
                                  ? StatusChip(
                                      label:
                                          '$count ${count == 1 ? 'ajuste' : 'ajustes'}',
                                    )
                                  : null,
                              onTap: opcao.liberado
                                  ? () => Navigator.of(context).pop(ata)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: (value) => onChanged(value ?? false),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

String _searchableAtaText(OpcaoAta opcao) {
  final ata = opcao.ata;
  final edital = opcao.processo.edital;
  return [
    ata.codigoAta,
    PcnpInputFormatter.applyMask(ata.codigoAta),
    ata.numeroAtaRegistroPreco,
    ata.anoAta == 0 ? '' : ata.anoAta.toString(),
    ata.dropdownLabel,
    edital.modalidadeLabel,
    edital.numeroCompra,
    edital.anoCompra == 0 ? '' : edital.anoCompra.toString(),
    edital.codigoEdital,
    edital.idContratacaoPNCP,
    edital.dropdownLabel,
    edital.objetoCompra,
  ].join(' ');
}
