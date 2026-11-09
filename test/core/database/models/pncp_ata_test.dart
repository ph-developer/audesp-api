import 'dart:convert';

import 'package:audesp_api/core/database/models/pncp_ata.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../features/pncp/pncp_ata_fixtures.dart';

void main() {
  for (final atualizacao in [false, true]) {
    test(
      'normaliza formato de ${atualizacao ? 'atualização' : 'compra'} sem perder resposta bruta',
      () {
        final json = ataPncpJson(atualizacao: atualizacao);
        final ata = PncpAta.fromApi(json);
        expect(ata.cnpj, '49576416000141');
        expect(ata.anoCompra, 2026);
        expect(ata.sequencialCompra, 1);
        expect(ata.sequencialAta, 1);
        expect(ata.numeroControle, '4957641600014110000012026000001');
        expect(ata.numeroControleCompra, '4957641600014110000012026');
        expect(ata.numeroAta, '72');
        expect(ata.anoAta, 2026);
        expect(ata.dataAssinatura, DateTime(2026, 2, 12));
        expect(ata.vigenciaInicio, DateTime(2026, 2, 12));
        expect(ata.vigenciaFim, DateTime(2027, 2, 12));
        expect(ata.dataPublicacao?.day, 19);
        expect(ata.objeto, 'REGISTRO DE PREÇOS para materiais');
        expect(ata.cancelada, isFalse);
        expect(jsonDecode(ata.dadosJson), json);
        final salva = ataPncpSalva(ata, id: 7, dispensada: true);
        expect(salva.id, 7);
        expect(salva.dados, json);
        expect(salva.vigenciaFim, ata.vigenciaFim);
        expect(salva.dispensadaPor, 7);
        expect(salva.dispensada, isTrue);
      },
    );
  }

  test('detalhe confere compra da URL e aceita numeroControlePncpCompra', () {
    final ata = PncpAta.fromApi(
      {
        ...ataPncpJson(sequencialCompra: 2, sequencialAta: 22),
        'numeroControlePncpCompra': '49576416000141-1-000002/2026',
      },
      cnpj: '49576416000141',
      anoCompra: 2026,
      sequencialCompra: 2,
    );
    expect(ata.sequencialCompra, 2);
    expect(ata.sequencialAta, 22);
    expect(
      () => PncpAta.fromApi(ata.dados, sequencialCompra: 1),
      throwsFormatException,
    );
    expect(
      () => PncpAta.fromApi(ata.dados, anoCompra: 2025),
      throwsFormatException,
    );
    expect(
      () => PncpAta.fromApi(ata.dados, cnpj: '46395000000139'),
      throwsFormatException,
    );
  });

  test(
    'cancelamento, datas ausentes e metadados opcionais não são inventados',
    () {
      final ata = PncpAta.fromApi({
        'numeroControlePNCP': '49576416000141-1-000001/2026-000001',
        'cancelado': true,
        'dataCancelamento': '2026-11-09',
      });
      expect(ata.cancelada, isTrue);
      expect(ata.dataCancelamento, DateTime(2026, 11, 9));
      expect(ata.numeroAta, isEmpty);
      expect(ata.anoAta, isNull);
      expect(ata.vigenciaInicio, isNull);
      expect(ata.dataPublicacao, isNull);
      expect(ataPncpSalva(ata).dataCancelamento, ata.dataCancelamento);
    },
  );

  test(
    'código ausente ou compra divergente não vira registro com chave vazia',
    () {
      expect(() => PncpAta.fromApi({}), throwsFormatException);
      expect(
        () => PncpAta.fromApi({
          ...ataPncpJson(),
          'numeroControlePNCPCompra': '49576416000141-1-000002/2026',
        }),
        throwsFormatException,
      );
    },
  );
}
