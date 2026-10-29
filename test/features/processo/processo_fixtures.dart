import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';

User usuarioFixture({int permissions = 0, bool isAdmin = false}) => User(
  id: 1,
  nome: 'Usuário de teste',
  email: 'teste@example.com',
  permissions: permissions,
  isAdmin: isAdmin,
  createdAt: DateTime(2026),
);

Processo processoFixture({
  int id = 1,
  String status = 'sent',
  bool srp = false,
  bool semPncp = true,
  String? codigo,
  String? objeto,
  double? valorTotal,
  EstimativaModel? estimativa,
  List<Licitacao> licitacoes = const [],
  List<Ata> atas = const [],
  List<Ajuste> ajustes = const [],
}) => Processo(
  edital: Edital(
    id: id,
    estimativaId: estimativa?.id,
    municipio: '1',
    entidade: '2',
    codigoEdital: codigo ?? 'edital-$id',
    semPncp: semPncp,
    retificacao: false,
    status: status,
    documentoJson: jsonEncode({
      'srp': srp,
      'modalidadeId': 6,
      'numeroCompra': '$id',
      'anoCompra': 2026,
      'objetoCompra': objeto ?? 'Objeto do edital $id',
      if (valorTotal != null)
        'itensCompra': [
          {'valorTotal': valorTotal},
        ],
    }),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026, 10, 28),
  ),
  licitacoes: licitacoes,
  estimativa: estimativa,
  atas: atas,
  ajustes: ajustes,
);

Licitacao licitacaoFixture(
  int id, {
  int editalId = 1,
  String status = 'draft',
  DateTime? updatedAt,
}) => Licitacao(
  id: id,
  editalId: editalId,
  municipio: '1',
  entidade: '2',
  codigoEdital: 'edital-$editalId',
  retificacao: false,
  status: status,
  documentoJson: '{}',
  createdAt: DateTime(2026),
  updatedAt: updatedAt ?? DateTime(2026, 10, 28),
);

Ata ataFixture(
  int id, {
  int editalId = 1,
  String status = 'draft',
  String? codigo,
  String documentoJson = '{}',
}) => Ata(
  id: id,
  editalId: editalId,
  municipio: '1',
  entidade: '2',
  codigoEdital: 'edital-$editalId',
  codigoAta: codigo ?? 'ata-$id',
  retificacao: false,
  status: status,
  documentoJson: documentoJson,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026, 10, 28),
);

Ajuste ajusteFixture(
  int id, {
  int editalId = 1,
  int? ataId,
  String status = 'draft',
  String? codigo,
  String documentoJson = '{}',
}) => Ajuste(
  id: id,
  editalId: editalId,
  ataId: ataId,
  municipio: '1',
  entidade: '2',
  codigoEdital: 'edital-$editalId',
  codigoContrato: codigo ?? 'ajuste-$id',
  retificacao: false,
  status: status,
  documentoJson: documentoJson,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026, 10, 28),
);
