import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';

const ambientePendencias = 'https://audesp-piloto.tce.sp.gov.br';

EnvioResumo envioFixture(
  Object documento, {
  int id = 1,
  String situacao = 'Recebido',
  String ambiente = ambientePendencias,
  bool? retificacao,
  List<String> codigosErro = const [],
}) {
  final descritor = switch (documento) {
    Edital e => DescritorEnvio.edital(
      municipio: e.municipio,
      entidade: e.entidade,
      codigoEdital: e.codigoEdital,
      retificacao: e.retificacao,
    ),
    Licitacao l => DescritorEnvio.licitacao(
      municipio: l.municipio,
      entidade: l.entidade,
      codigoEdital: l.codigoEdital,
      retificacao: l.retificacao,
    ),
    Ata a => DescritorEnvio.ata(
      municipio: a.municipio,
      entidade: a.entidade,
      codigoEdital: a.codigoEdital,
      codigoAta: a.codigoAta,
      retificacao: a.retificacao,
    ),
    Ajuste a => DescritorEnvio.ajuste(
      municipio: a.municipio,
      entidade: a.entidade,
      codigoEdital: a.codigoEdital,
      codigoAta: a.codigoAta,
      codigoContrato: a.codigoContrato,
      retificacao: a.retificacao,
    ),
    _ => throw ArgumentError('Documento sem descritor.'),
  };
  return EnvioResumo(
    id: id,
    statusCode: 200,
    protocolo: 'P$id',
    statusProtocolo: situacao,
    timestamp: DateTime(2026, 11, 9).add(Duration(seconds: id)),
    descritor: {...descritor, 'retificacao': ?retificacao},
    endpoint: '$ambiente/f4/enviar',
    codigosErro: codigosErro,
  );
}

EnviosProcesso enviosFixture(
  DocumentosProcesso documentos, {
  String situacao = 'Recebido',
  String ambiente = ambientePendencias,
}) {
  EnviosIndex index(Iterable<Object> docs) => EnviosIndex([
    for (final (i, doc) in docs.indexed)
      envioFixture(doc, id: i + 1, situacao: situacao, ambiente: ambiente),
  ]);
  return EnviosProcesso(
    editais: index(documentos.editais),
    licitacoes: index(documentos.licitacoes),
    atas: index(documentos.atas),
    ajustes: index(documentos.ajustes),
    baseUrl: ambientePendencias,
  );
}
