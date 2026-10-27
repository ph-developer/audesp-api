import 'package:audesp_api/features/ata/domain/ata_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ata aceita subconjunto dos itens da licitação', () {
    expect(AtaRules.validarItens([2, 8], numerosLicitacao: {1, 2, 8}), isNull);
  });

  test('ata cita item inexistente na licitação', () {
    expect(
      AtaRules.validarItens([2, 9], numerosLicitacao: {1, 2, 8}),
      contains('Item 9 não consta'),
    );
    expect(
      AtaRules.validarItens([2], numerosLicitacao: {}),
      contains('Item 2 não consta'),
    );
  });

  test(
    'ata dispensa referência ausente, mas mantém proibição de duplicados',
    () {
      expect(AtaRules.validarItens([2, 9]), isNull);
      expect(AtaRules.validarItens([2, 2]), contains('Item 2 repetido'));
      expect(
        AtaRules.validarItens([2, 2], numerosLicitacao: {2}),
        contains('Item 2 repetido'),
      );
    },
  );
}
