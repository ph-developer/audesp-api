import 'package:audesp_api/core/database/models/pncp_compra.dart';
import 'package:audesp_api/features/pncp/domain/pncp_pendencias.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pncp_fixtures.dart';

PncpCompra _compra(int sequencial, {bool dispensada = false}) {
  final compra = PncpCompra.fromApi(compraPncpJson(sequencial: sequencial));
  return PncpCompra(
    id: sequencial,
    cnpj: compra.cnpj,
    ano: compra.ano,
    sequencial: compra.sequencial,
    numeroControle: compra.numeroControle,
    dadosJson: compra.dadosJson,
    dispensadaEm: dispensada ? DateTime(2026, 10, 1) : null,
  );
}

void main() {
  test('número de controle vem só com dígitos e o CNPJ do prefixo', () {
    final compra = _compra(7);
    expect(compra.numeroControle, '4639500000013910000072026');
    expect(compra.cnpj, '46395000000139');
    expect(compra.valorTotalEstimado, isNull);
    final api = PncpCompra.fromApi(compraPncpJson());
    expect(api.valorTotalEstimado, 6000000);
    expect(api.dataPublicacao, DateTime(2025, 10, 17, 16, 32, 28));
  });

  test('compra com edital, com ou sem máscara, sai das pendências', () {
    final compras = [_compra(1), _compra(2), _compra(3), _compra(4)];
    final editais = [
      // Código do edital sem máscara (como é salvo).
      editalFixture(id: 1, codigoEdital: '4639500000013910000012026'),
      // Código local, mas com a publicação no PNCP mascarada.
      editalFixture(
        id: 2,
        codigoEdital: 'LOCAL-2',
        documento: {
          'publicidade': {
            'publicacoes': [
              {'idContratacaoPNCP': '46395000000139-1-000002/2026'},
            ],
          },
        },
      ),
    ];
    expect(PncpPendencias.semEdital(compras, editais).map((c) => c.id), [3, 4]);
  });

  test('dispensadas ficam fora das pendências e podem ser listadas', () {
    final compras = [_compra(1, dispensada: true), _compra(2)];
    expect(PncpPendencias.semEdital(compras, []).map((c) => c.id), [2]);
    expect(PncpPendencias.dispensadas(compras, []).map((c) => c.id), [1]);
    final comEdital = [
      editalFixture(codigoEdital: '4639500000013910000012026'),
    ];
    expect(PncpPendencias.dispensadas(compras, comEdital), isEmpty);
  });

  test('compras publicadas antes de 02/02/2026 nunca aparecem', () {
    PncpCompra compra(int seq, DateTime publicacao, {bool dispensada = false}) {
      final base = _compra(seq, dispensada: dispensada);
      return PncpCompra(
        id: base.id,
        cnpj: base.cnpj,
        ano: base.ano,
        sequencial: base.sequencial,
        numeroControle: base.numeroControle,
        dadosJson: base.dadosJson,
        dataPublicacao: publicacao,
        dispensadaEm: base.dispensadaEm,
      );
    }

    final compras = [
      compra(1, DateTime(2026, 2, 1)),
      compra(2, DateTime(2026, 2, 2)),
      compra(3, DateTime(2026, 1, 10), dispensada: true),
    ];
    expect(PncpPendencias.semEdital(compras, const []).map((c) => c.id), [2]);
    expect(PncpPendencias.dispensadas(compras, const []), isEmpty);
  });
}
