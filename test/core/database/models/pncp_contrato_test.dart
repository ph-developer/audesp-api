import 'package:audesp_api/core/database/models/pncp_contrato.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../features/pncp/pncp_fixtures.dart';

void main() {
  test('fromApi normaliza referências e preserva a resposta bruta', () {
    final json = contratoPncpJson()
      ..['numeroControlePncpAta'] = '46395000000139-1-000352/2026-000001';
    final contrato = PncpContrato.fromApi(json);
    expect(contrato.id, 0);
    expect(contrato.cnpj, '46395000000139');
    expect(contrato.numeroControle, '4639500000013920000022026');
    expect(contrato.numeroControleCompra, '4639500000013910003522026');
    expect(contrato.numeroControleAta, '4639500000013910003522026000001');
    expect(contrato.tipoContratoId, 8);
    expect(contrato.numeroContrato, '3');
    expect(contrato.valorGlobal, 16200);
    expect(contrato.dataAssinatura, DateTime(2026, 3, 9));
    expect(contrato.vigenciaFim, DateTime(2027, 3, 9));
    expect(contrato.dataPublicacao, DateTime(2026, 2, 6, 10, 42, 48));
    expect(contrato.dados, json);
  });

  test('fromMap lê decimais, datas em segundos e dispensa', () {
    final contrato = contratoPncpFixture(dispensado: true);
    expect(contrato.id, 1);
    expect(contrato.valorGlobal, 16200);
    expect(contrato.dataAssinatura, DateTime(2026, 3, 9));
    expect(contrato.vigenciaInicio, DateTime(2026, 3, 9));
    expect(contrato.dispensado, isTrue);
    expect(contrato.dispensadaPor, 7);
    expect(contrato.createdAt, DateTime(2026, 11, 9));
    expect(contrato.updatedAt, DateTime(2026, 11, 9));
    expect(contrato.motivoDispensa, 'Enviado por outro sistema');
  });

  test('referências vazias viram null e ausências não criam dados', () {
    final contrato = PncpContrato.fromApi({
      'numeroControlePncpCompra': ' ',
      'numeroControlePncpAta': '',
      'dataAssinatura': 'inválida',
    });
    expect(contrato.numeroControleCompra, isNull);
    expect(contrato.numeroControleAta, isNull);
    expect(contrato.frutoAdesao, isFalse);
    expect(contrato.dataAssinatura, isNull);
    expect(contrato.valorGlobal, isNull);
  });
}
