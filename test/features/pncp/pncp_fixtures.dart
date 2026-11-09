import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';

Map<String, dynamic> contratoPncpJson({
  int sequencial = 2,
  int ano = 2026,
  String cnpj = '46395000000139',
}) => {
  'numeroControlePNCP': '$cnpj-2-${sequencial.toString().padLeft(6, '0')}/$ano',
  'numeroControlePncpCompra': '$cnpj-1-000352/2025',
  'numeroControlePncpAta': null,
  'anoContrato': ano,
  'sequencialContrato': sequencial,
  'frutoAdesao': false,
  'numeroContratoEmpenho': '3',
  'tipoContrato': {'id': 8, 'nome': 'Outros'},
  'categoriaProcesso': {'id': 8, 'nome': 'Serviços'},
  'niFornecedor': '24.195.949/0001-52',
  'tipoPessoa': 'PJ',
  'nomeRazaoSocialFornecedor': 'Fornecedor de teste LTDA',
  'objetoContrato': 'Prestação de serviços de manutenção',
  'processo': '329',
  'receita': false,
  'dataAssinatura': '2026-01-09',
  'dataVigenciaInicio': '2026-01-09',
  'dataVigenciaFim': '2027-01-09',
  'dataPublicacaoPncp': '2026-02-06T10:42:48',
  'dataAtualizacao': '2026-05-20T10:50:21',
  'valorInicial': 16200.0,
  'valorGlobal': 16200.0,
  'valorAcumulado': 16200.0,
  'numeroParcelas': 1,
  'valorParcela': 16200.0,
};

PncpContrato contratoPncpFixture({
  int id = 1,
  bool dispensado = false,
  Map<String, dynamic> alteracoes = const {},
}) {
  final contrato = PncpContrato.fromApi({...contratoPncpJson(), ...alteracoes});
  int? epoch(DateTime? data) =>
      data == null ? null : data.millisecondsSinceEpoch ~/ 1000;
  return PncpContrato.fromMap({
    'id': id,
    'cnpj': contrato.cnpj,
    'ano': contrato.ano,
    'sequencial': contrato.sequencial,
    'numero_controle': contrato.numeroControle,
    'numero_controle_compra': contrato.numeroControleCompra,
    'numero_controle_ata': contrato.numeroControleAta,
    'fruto_adesao': contrato.frutoAdesao ? 1 : 0,
    'numero_contrato': contrato.numeroContrato,
    'tipo_contrato_id': contrato.tipoContratoId,
    'ni_fornecedor': contrato.niFornecedor,
    'nome_fornecedor': contrato.nomeFornecedor,
    'objeto': contrato.objeto,
    'valor_global': contrato.valorGlobal?.toStringAsFixed(4),
    'data_assinatura': epoch(contrato.dataAssinatura),
    'vigencia_inicio': epoch(contrato.vigenciaInicio),
    'vigencia_fim': epoch(contrato.vigenciaFim),
    'data_publicacao': epoch(contrato.dataPublicacao),
    'dados_json': contrato.dadosJson,
    'dispensada_em': dispensado ? epoch(DateTime(2026, 11, 9)) : null,
    'dispensada_por': dispensado ? 7 : null,
    'motivo_dispensa': dispensado ? 'Enviado por outro sistema' : null,
    'created_at': epoch(DateTime(2026, 11, 9)),
    'updated_at': epoch(DateTime(2026, 11, 9)),
  });
}

/// Resposta real de /v1/orgaos/{cnpj}/compras/{ano}/{sequencial}, reduzida.
Map<String, dynamic> compraPncpJson({
  int sequencial = 2,
  int ano = 2026,
  String cnpj = '46395000000139',
}) => {
  'valorTotalEstimado': 6000000.0,
  'numeroControlePNCP': '$cnpj-1-${sequencial.toString().padLeft(6, '0')}/$ano',
  'linkSistemaOrigem': null,
  'anoCompra': ano,
  'sequencialCompra': sequencial,
  'numeroCompra': '125',
  'processo': '6077.2025/0000093-5  ',
  'orgaoEntidade': {'cnpj': cnpj, 'razaoSocial': 'MUNICIPIO DE SAO PAULO'},
  'modalidadeId': 8,
  'modalidadeNome': 'Dispensa',
  'justificativaPresencial': null,
  'modoDisputaId': 5,
  'tipoInstrumentoConvocatorioCodigo': 3,
  'amparoLegal': {'nome': 'Lei 14.133/2021, Art. 75, XV', 'codigo': 45},
  'objetoCompra': 'Hospedagem e manutenção evolutiva do SMAE',
  'informacaoComplementar': null,
  'srp': false,
  'dataPublicacaoPncp': '2025-10-17T16:32:28',
  'dataAberturaProposta': null,
  'dataEncerramentoProposta': null,
};

Edital editalFixture({
  int id = 1,
  String codigoEdital = '',
  Map<String, dynamic> documento = const {},
}) => Edital(
  id: id,
  municipio: '1',
  entidade: '2',
  codigoEdital: codigoEdital,
  retificacao: false,
  status: 'draft',
  documentoJson: jsonEncode(documento),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
