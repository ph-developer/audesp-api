import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';

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
