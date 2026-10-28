import '../../../core/database/models/ajuste.dart';
import '../../../core/database/models/ata.dart';
import '../../../core/database/models/licitacao.dart';
import '../../../core/database/models/user.dart';
import '../../../core/navigation/app_modules.dart' show canAccessLocation;
import '../../../shared/formatters/pcnp_input_formatter.dart';
import 'processo.dart';
import 'processo_rules.dart';

enum EtapaTipo { edital, licitacao, ata, ajuste }

enum SituacaoEtapa { bloqueada, aCriar, rascunho, enviada }

class AcaoEtapa {
  final String label;
  final String route;

  const AcaoEtapa({required this.label, required this.route});
}

class EtapaProcesso {
  final EtapaTipo tipo;
  final SituacaoEtapa situacao;
  final int quantidade;
  final String? motivoBloqueio;
  final List<AcaoEtapa> acoes;

  EtapaProcesso({
    required this.tipo,
    required this.situacao,
    required this.quantidade,
    this.motivoBloqueio,
    required List<AcaoEtapa> acoes,
  }) : acoes = List.unmodifiable(acoes);
}

abstract final class ProcessoEtapas {
  static List<EtapaProcesso> de(Processo processo, User user) {
    final edital = processo.edital;
    final editalEnviado = edital.status == 'sent';
    final situacaoLicitacao = ProcessoRules.situacaoLicitacao(
      processo.licitacoes,
    );
    final motivoAta = ProcessoRules.motivoBloqueioAta(processo);
    final motivoAjuste = ProcessoRules.motivoBloqueioAjuste(processo);

    EtapaProcesso etapa({
      required EtapaTipo tipo,
      required SituacaoEtapa situacao,
      required int quantidade,
      String? motivoBloqueio,
      required List<AcaoEtapa> acoes,
    }) => EtapaProcesso(
      tipo: tipo,
      situacao: situacao,
      quantidade: quantidade,
      motivoBloqueio: situacao == SituacaoEtapa.bloqueada
          ? motivoBloqueio
          : null,
      acoes: acoes
          .where((acao) => canAccessLocation(user, acao.route))
          .toList(),
    );

    return [
      etapa(
        tipo: EtapaTipo.edital,
        situacao: editalEnviado
            ? SituacaoEtapa.enviada
            : SituacaoEtapa.rascunho,
        quantidade: 1,
        acoes: [
          AcaoEtapa(label: 'Abrir edital', route: '/edital/${edital.id}'),
        ],
      ),
      etapa(
        tipo: EtapaTipo.licitacao,
        situacao: switch (situacaoLicitacao) {
          SituacaoLicitacao.enviada => SituacaoEtapa.enviada,
          SituacaoLicitacao.rascunho => SituacaoEtapa.rascunho,
          SituacaoLicitacao.inexistente =>
            editalEnviado ? SituacaoEtapa.aCriar : SituacaoEtapa.bloqueada,
        },
        quantidade: processo.licitacoes.length,
        motivoBloqueio: 'O edital ainda não foi enviado ao AUDESP.',
        acoes: [
          for (final licitacao in processo.licitacoes)
            AcaoEtapa(
              label: processo.licitacoes.length == 1
                  ? 'Abrir licitação'
                  : 'Abrir licitação ${licitacao.status == 'sent' ? 'enviada' : 'rascunho'} #${licitacao.id}',
              route: '/licitacao/${licitacao.id}',
            ),
          if (processo.licitacoes.isEmpty && editalEnviado)
            AcaoEtapa(
              label: 'Nova licitação',
              route: '/licitacao/new?editalId=${edital.id}',
            ),
        ],
      ),
      // A licitação gera Ata (edital SRP) ou Ajuste (não SRP); a etapa que
      // não se aplica só aparece quando já há documentos antigos nela.
      if (edital.isSrp || processo.atas.isNotEmpty)
        etapa(
          tipo: EtapaTipo.ata,
          situacao: _situacaoDocumentos(
            processo.atas.map((ata) => ata.status),
            motivoAta,
          ),
          quantidade: processo.atas.length,
          motivoBloqueio: motivoAta,
          acoes: [
            for (final ata in processo.atas)
              AcaoEtapa(
                label: 'Abrir ata ${_rotuloAta(ata)}',
                route: '/ata/${ata.id}',
              ),
            if (ProcessoRules.podeCriarAta(processo))
              AcaoEtapa(
                label: 'Nova ata',
                route: '/ata/new?editalId=${edital.id}',
              ),
          ],
        ),
      if (!edital.isSrp || processo.ajustes.isNotEmpty)
        etapa(
          tipo: EtapaTipo.ajuste,
          situacao: _situacaoDocumentos(
            processo.ajustes.map((ajuste) => ajuste.status),
            motivoAjuste,
          ),
          quantidade: processo.ajustes.length,
          motivoBloqueio: motivoAjuste,
          acoes: [
            for (final ajuste in processo.ajustes)
              AcaoEtapa(
                label: 'Abrir ajuste ${_rotuloAjuste(ajuste)}',
                route: '/ajuste/${ajuste.id}',
              ),
            if (!edital.isSrp && ProcessoRules.podeCriarAjuste(processo))
              AcaoEtapa(
                label: 'Novo ajuste',
                route: '/ajuste/new?editalId=${edital.id}',
              ),
          ],
        ),
    ];
  }
}

SituacaoEtapa _situacaoDocumentos(
  Iterable<String> status,
  String? motivoBloqueio,
) {
  if (status.isEmpty) {
    return motivoBloqueio == null
        ? SituacaoEtapa.aCriar
        : SituacaoEtapa.bloqueada;
  }
  return status.every((s) => s == 'sent')
      ? SituacaoEtapa.enviada
      : SituacaoEtapa.rascunho;
}

// Número/ano quando informados; senão o código (com máscara PNCP) ou o id.
String _rotuloAta(Ata ata) =>
    _rotulo(ata.numeroAtaRegistroPreco, ata.anoAta, ata.codigoAta, ata.id);

String _rotuloAjuste(Ajuste ajuste) => _rotulo(
  ajuste.numeroContratoEmpenho,
  ajuste.anoContrato,
  ajuste.codigoContrato,
  ajuste.id,
);

String _rotulo(String numero, int ano, String codigo, int id) {
  if (numero.trim().isNotEmpty) {
    return ano == 0 ? numero.trim() : '${numero.trim()}/$ano';
  }
  final codigoLimpo = codigo.trim();
  return codigoLimpo.isEmpty
      ? '$id'
      : PcnpInputFormatter.applyMask(codigoLimpo);
}

String descricaoPendencia(Pendencia p) => switch (p.tipo) {
  TipoPendencia.criarLicitacao => 'Criar licitação',
  TipoPendencia.enviarLicitacao => 'Enviar licitação',
  TipoPendencia.criarAta => 'Criar ata',
  TipoPendencia.criarAjuste => 'Criar ajuste',
};

String rotaPendencia(Pendencia p) => switch (p.tipo) {
  TipoPendencia.criarLicitacao =>
    '/licitacao/new?editalId=${p.processo.edital.id}',
  TipoPendencia.enviarLicitacao =>
    '/licitacao/${_rascunhoMaisRecente(p.processo).id}',
  TipoPendencia.criarAta => '/ata/new?editalId=${p.processo.edital.id}',
  TipoPendencia.criarAjuste => '/ajuste/new?editalId=${p.processo.edital.id}',
};

Licitacao _rascunhoMaisRecente(Processo processo) => processo.licitacoes
    .where((licitacao) => licitacao.status == 'draft')
    .reduce((a, b) {
      final comparacao = a.updatedAt.compareTo(b.updatedAt);
      return comparacao > 0 || (comparacao == 0 && a.id > b.id) ? a : b;
    });
