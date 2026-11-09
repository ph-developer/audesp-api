import 'dart:convert';
import 'dart:io';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/pncp/domain/pncp_ata_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pncp_ata_fixtures.dart';
import '../pncp_fixtures.dart' show editalFixture;

void main() {
  final edital = editalFixture(codigoEdital: 'CODIGO-LOCAL');
  for (final atualizacao in [false, true]) {
    test(
      'mapeia referências e datas do formato $atualizacao usando código do edital local',
      () {
        final ata = PncpAta.fromApi(ataPncpJson(atualizacao: atualizacao));
        final doc = PncpAtaMapper.documento(ata, edital: edital);
        expect(doc, {
          'descritor': {
            'codigoAta': '4957641600014110000012026000001',
            'codigoEdital': 'CODIGO-LOCAL',
            'anoCompra': 2026,
            'retificacao': false,
          },
          'numeroItem': <int>[],
          'numeroAtaRegistroPreco': '72',
          'anoAta': 2026,
          'dataAssinatura': '2026-02-12',
          'dataVigenciaInicio': '2026-02-12',
          'dataVigenciaFim': '2027-02-12',
        });
        final schema =
            jsonDecode(
                  File(
                    'docs/tcesp/ata-20261015/ata_schema.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final campos = (schema['properties'] as Map).keys;
        expect(doc.keys.every(campos.contains), isTrue);
        final descritor =
            (schema['properties']['descritor']['properties'] as Map).keys;
        expect(
          (doc['descritor'] as Map).keys.every(descritor.contains),
          isTrue,
        );
      },
    );
  }

  test(
    'dados ausentes ou fora do schema ficam em branco, sem deduzir ano nem itens',
    () {
      final ata = PncpAta.fromApi({
        'numeroControlePNCP': '49576416000141-1-000001/2025-000001',
      });
      expect(PncpAtaMapper.documento(ata, edital: edital), {
        'descritor': {
          'codigoAta': ata.numeroControle,
          'codigoEdital': 'CODIGO-LOCAL',
          'anoCompra': 2025,
          'retificacao': false,
        },
        'numeroItem': <int>[],
      });
      final fora = ataPncpFixture(
        alteracoes: {
          'numeroAtaRegistroPreco': 'a' * 31,
          'anoAta': 2101,
          'numeroItem': [1, 2],
          'possibilidadeAdesao': true,
        },
      );
      final doc = PncpAtaMapper.documento(fora, edital: edital);
      expect(doc.containsKey('numeroAtaRegistroPreco'), isFalse);
      expect(doc.containsKey('anoAta'), isFalse);
      expect(doc['numeroItem'], isEmpty);
      expect(doc.containsKey('possibilidadeAdesao'), isFalse);
    },
  );
}
