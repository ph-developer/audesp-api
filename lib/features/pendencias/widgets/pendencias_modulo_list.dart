import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../shared/formatters/documento_rotulo.dart';
import '../../../shared/formatters/pcnp_input_formatter.dart';
import '../../../shared/widgets/document_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/ufesp_indicador.dart';
import '../../pncp/pncp_providers.dart';
import '../../pncp/widgets/pncp_compra_card.dart';
import '../../pncp/widgets/pncp_contrato_card.dart';
import '../../pncp/widgets/pncp_ata_card.dart';
import '../../processo/domain/ufesp_rules.dart';
import '../domain/pendencias_modulos.dart';
import '../pendencias_providers.dart';
import 'pendencia_protocolo_card.dart';

class PendenciasModuloList extends ConsumerWidget {
  final String modulo;
  final String search;
  final bool mostrarDispensadas;

  const PendenciasModuloList({
    super.key,
    required this.modulo,
    this.search = '',
    this.mostrarDispensadas = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ufesp = ref.watch(ufespConfigProvider).value ?? const UfespConfig();
    return ref
        .watch(pendenciasModulosProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text('Erro ao carregar pendências: $e')),
          data: (pendencias) {
            final itens = <Widget>[];
            bool busca(String texto) => matchesLikeSearch(texto, search);

            if (modulo == '/edital') {
              for (final compra in [
                ...pendencias.comprasEdital,
                if (mostrarDispensadas) ...pendencias.comprasDispensadas,
              ]) {
                if (busca(
                  '${tituloPncpCompra(compra)} ${compra.numeroControle} '
                  '${compra.objeto} ${compra.motivoDispensa ?? ''}',
                )) {
                  itens.add(PncpCompraCard(compra: compra, ufesp: ufesp));
                }
              }
            }
            if (modulo == '/licitacao') {
              for (final edital in pendencias.criarLicitacao) {
                if (!busca(_buscaEdital(edital))) continue;
                itens.add(
                  DocumentCard(
                    icon: Icons.playlist_add,
                    title: tituloEdital(edital),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (edital.objetoCompra.isNotEmpty)
                          Text(edital.objetoCompra),
                        const Text(
                          'O edital está concluído e ainda não tem licitação.',
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            UfespIndicador(
                              valorEstimado: edital.valorTotalEstimado,
                              config: ufesp,
                            ),
                            if (edital.semPncp) StatusChip.semPncp(),
                            TextButton.icon(
                              onPressed: () => context.go(
                                '/licitacao/new?editalId=${edital.id}',
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Nova licitação'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
            final Iterable<PendenciaProtocolo<Object>> protocolos =
                switch (modulo) {
                  '/edital' => pendencias.editais,
                  '/licitacao' => pendencias.licitacoes,
                  '/ata' => pendencias.atas,
                  '/ajuste' => pendencias.ajustes,
                  _ => const [],
                };
            for (final pendencia in protocolos) {
              final documento = pendencia.documento;
              final edital = pendencia.edital;
              final (
                titulo,
                rota,
                nome,
                feminino,
                retificacao,
              ) = switch (documento) {
                Edital e => (
                  tituloEdital(e),
                  '/edital/${e.id}',
                  'edital',
                  false,
                  e.retificacao,
                ),
                Licitacao l => (
                  tituloLicitacao(l, edital),
                  '/licitacao/${l.id}',
                  'licitação',
                  true,
                  l.retificacao,
                ),
                Ata a => (
                  tituloAta(a),
                  '/ata/${a.id}',
                  'ata',
                  true,
                  a.retificacao,
                ),
                Ajuste a => (
                  tituloAjuste(a),
                  '/ajuste/${a.id}',
                  'ajuste',
                  false,
                  a.retificacao,
                ),
                _ => throw StateError('Documento sem módulo de envio.'),
              };
              final descricao = [
                if (edital != null && documento is! Edital)
                  tituloEdital(edital),
                if (edital != null) edital.objetoCompra,
                if (documento is Ajuste && documento.editalId == null)
                  'Adesão — ${PcnpInputFormatter.applyMask(documento.codigoEdital)}',
              ].where((p) => p.isNotEmpty).join(' | ');
              final texto = [
                titulo,
                descricao,
                if (edital != null) _buscaEdital(edital),
                if (documento is Ata)
                  '${documento.codigoAta} ${documento.codigoEdital}',
                if (documento is Ajuste)
                  '${documento.codigoContrato} ${documento.codigoEdital} ${documento.codigoAta ?? ''}',
                if (documento is Licitacao) documento.codigoEdital,
              ].join(' ');
              if (!busca(texto)) continue;
              itens.add(
                PendenciaProtocoloCard(
                  key: ValueKey(rota),
                  titulo: titulo,
                  descricao: descricao,
                  nome: nome,
                  feminino: feminino,
                  rota: rota,
                  conclusao: pendencia.conclusao,
                  indicadores: [
                    if (documento is Edital)
                      UfespIndicador(
                        valorEstimado: documento.valorTotalEstimado,
                        config: ufesp,
                      ),
                    if (edital?.semPncp == true) StatusChip.semPncp(),
                    if (retificacao) StatusChip.retificacao(),
                  ],
                ),
              );
            }
            if (modulo == '/ata') {
              for (final pendencia in [
                ...pendencias.atasPncp,
                ...pendencias.atasBloqueadas,
                if (mostrarDispensadas) ...pendencias.atasDispensadas,
              ]) {
                final ata = pendencia.ata;
                if (!busca(
                  [
                    tituloPncpAta(ata),
                    ata.numeroControle,
                    ata.numeroControleCompra,
                    PcnpInputFormatter.applyMask(ata.numeroControle),
                    PcnpInputFormatter.applyMask(ata.numeroControleCompra),
                    ata.objeto,
                    ata.motivoDispensa ?? '',
                    pendencia.motivoBloqueio ?? '',
                    if (pendencia.edital != null)
                      _buscaEdital(pendencia.edital!),
                  ].join(' '),
                )) {
                  continue;
                }
                itens.add(
                  PncpAtaCard(
                    key: ValueKey('pncpAta-${ata.id}'),
                    pendencia: pendencia,
                  ),
                );
              }
            }
            if (modulo == '/ajuste') {
              for (final pendencia in [
                ...pendencias.contratosAjuste,
                ...pendencias.contratosBloqueados,
                if (mostrarDispensadas) ...pendencias.contratosDispensados,
              ]) {
                final contrato = pendencia.contrato;
                if (!busca(
                  [
                    tituloPncpContrato(contrato),
                    contrato.numeroControle,
                    contrato.numeroControleCompra ?? '',
                    contrato.niFornecedor,
                    contrato.objeto,
                    contrato.motivoDispensa ?? '',
                    pendencia.motivoBloqueio ?? '',
                    if (pendencia.edital != null)
                      _buscaEdital(pendencia.edital!),
                  ].join(' '),
                )) {
                  continue;
                }
                itens.add(
                  PncpContratoCard(
                    key: ValueKey('pncpContrato-${contrato.id}'),
                    pendencia: pendencia,
                  ),
                );
              }
            }
            if (itens.isEmpty) {
              return EmptyState(
                icon: Icons.task_alt,
                message: search.isEmpty
                    ? 'Nenhuma pendência para você.'
                    : 'Nenhum resultado para "$search"',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: itens.length,
              itemBuilder: (context, i) => itens[i],
            );
          },
        );
  }
}

String _buscaEdital(Edital edital) => [
  tituloEdital(edital),
  edital.codigoEdital,
  edital.idContratacaoPNCP,
  edital.objetoCompra,
  edital.dropdownLabel,
].join(' ');
