import 'package:audesp_api/core/database/models/pncp_ata.dart';

Map<String, dynamic> ataPncpJson({
  String cnpj = '49576416000141',
  int anoCompra = 2026,
  int sequencialCompra = 1,
  int sequencialAta = 1,
  bool atualizacao = false,
}) {
  final compra =
      '$cnpj-1-${sequencialCompra.toString().padLeft(6, '0')}/$anoCompra';
  return {
    atualizacao ? 'numeroControlePNCPAta' : 'numeroControlePNCP':
        '$compra-${sequencialAta.toString().padLeft(6, '0')}',
    if (atualizacao) 'numeroControlePNCPCompra': compra,
    if (!atualizacao) 'sequencialAta': sequencialAta,
    'numeroAtaRegistroPreco': '72',
    'anoAta': 2026,
    'cancelado': false,
    'dataCancelamento': null,
    'dataAssinatura': '2026-02-12',
    atualizacao ? 'vigenciaInicio' : 'dataVigenciaInicio': '2026-02-12',
    atualizacao ? 'vigenciaFim' : 'dataVigenciaFim': '2027-02-12',
    'dataPublicacaoPncp': atualizacao ? '2026-02-19' : '2026-02-19T10:48:58',
    'dataAtualizacao': atualizacao ? '2026-11-03' : '2026-06-02T09:31:50',
    atualizacao ? 'objetoContratacao' : 'objetoCompra':
        'REGISTRO DE PREÇOS para materiais',
    if (atualizacao) 'cnpjOrgao': cnpj else 'orgaoEntidade': {'cnpj': cnpj},
    'possibilidadeAdesao': false,
  };
}

PncpAta ataPncpFixture({
  int id = 1,
  bool dispensada = false,
  Map<String, dynamic> alteracoes = const {},
}) => ataPncpSalva(
  PncpAta.fromApi({...ataPncpJson(), ...alteracoes}),
  id: id,
  dispensada: dispensada,
);

PncpAta ataPncpSalva(PncpAta ata, {int id = 1, bool dispensada = false}) {
  int? epoch(DateTime? data) =>
      data == null ? null : data.millisecondsSinceEpoch ~/ 1000;
  return PncpAta.fromMap({
    'id': id,
    'cnpj': ata.cnpj,
    'ano_compra': ata.anoCompra,
    'sequencial_compra': ata.sequencialCompra,
    'sequencial_ata': ata.sequencialAta,
    'numero_controle': ata.numeroControle,
    'numero_controle_compra': ata.numeroControleCompra,
    'numero_ata': ata.numeroAta,
    'ano_ata': ata.anoAta,
    'cancelada': ata.cancelada ? 1 : 0,
    'data_cancelamento': epoch(ata.dataCancelamento),
    'data_assinatura': epoch(ata.dataAssinatura),
    'vigencia_inicio': epoch(ata.vigenciaInicio),
    'vigencia_fim': epoch(ata.vigenciaFim),
    'data_publicacao': epoch(ata.dataPublicacao),
    'objeto': ata.objeto,
    'dados_json': ata.dadosJson,
    'dispensada_em': dispensada ? epoch(DateTime(2026, 11, 9)) : null,
    'dispensada_por': dispensada ? 7 : null,
    'motivo_dispensa': dispensada ? 'Enviada por outro sistema' : null,
    'created_at': epoch(DateTime(2026, 11, 9)),
    'updated_at': epoch(DateTime(2026, 11, 9)),
  });
}
