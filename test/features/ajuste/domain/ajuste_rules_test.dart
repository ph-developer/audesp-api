import 'package:audesp_api/features/ajuste/domain/ajuste_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AjusteRules.exigeFonteRecursos', () {
    test('exige para despesa dos tipos de órgão previstos na v02', () {
      for (final codigo in [1, 10, 13, 20, 25]) {
        expect(
          AjusteRules.exigeFonteRecursos(
            codigoTipoOrgao: codigo,
            receita: false,
          ),
          isTrue,
          reason: 'CodigoTipoOrgao $codigo',
        );
      }
    });

    test('não exige para receita nem para órgão fora da regra', () {
      expect(
        AjusteRules.exigeFonteRecursos(codigoTipoOrgao: 1, receita: true),
        isFalse,
      );
      expect(
        AjusteRules.exigeFonteRecursos(codigoTipoOrgao: 2, receita: false),
        isFalse,
      );
      expect(
        AjusteRules.exigeFonteRecursos(codigoTipoOrgao: null, receita: false),
        isFalse,
      );
    });
  });

  group('AjusteRules.exigeDespesas', () {
    test('exige para empenho somente nos tipos municipais previstos', () {
      for (final codigo in [1, 10, 13, 20, 25]) {
        expect(
          AjusteRules.exigeDespesas(
            codigoTipoOrgao: codigo,
            tipoContratoId: 7,
            receita: true,
          ),
          isTrue,
          reason: 'CodigoTipoOrgao $codigo',
        );
      }

      expect(
        AjusteRules.exigeDespesas(
          codigoTipoOrgao: 3,
          tipoContratoId: 7,
          receita: true,
        ),
        isFalse,
      );
    });

    test('exige para despesa nos tipos de órgão previstos na v02', () {
      const codigos = [1, 2, 3, 4, 5, 6, 9, 10, 13, 19, 20, 25, 42, 43];

      for (final codigo in codigos) {
        expect(
          AjusteRules.exigeDespesas(
            codigoTipoOrgao: codigo,
            tipoContratoId: 1,
            receita: false,
          ),
          isTrue,
          reason: 'CodigoTipoOrgao $codigo',
        );
      }
    });

    test('não exige fora das duas condições', () {
      expect(
        AjusteRules.exigeDespesas(
          codigoTipoOrgao: 8,
          tipoContratoId: 1,
          receita: false,
        ),
        isFalse,
      );
      expect(
        AjusteRules.exigeDespesas(
          codigoTipoOrgao: 2,
          tipoContratoId: 1,
          receita: true,
        ),
        isFalse,
      );
      expect(
        AjusteRules.exigeDespesas(
          codigoTipoOrgao: null,
          tipoContratoId: 7,
          receita: false,
        ),
        isFalse,
      );
    });
  });

  group('AjusteRules.validarCodigoContratoSemPncp', () {
    test('aceita código numérico local', () {
      expect(AjusteRules.validarCodigoContratoSemPncp('202304567'), isNull);
    });

    test('aceita código alfanumérico local', () {
      expect(AjusteRules.validarCodigoContratoSemPncp('CT-001/2026'), isNull);
    });

    test('rejeita nulo, vazio ou só espaços', () {
      for (final value in [null, '', '   ']) {
        expect(
          AjusteRules.validarCodigoContratoSemPncp(value),
          'Informe o Código do Contrato',
        );
      }
    });

    test('rejeita código com 26 caracteres', () {
      expect(
        AjusteRules.validarCodigoContratoSemPncp('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
        'Máximo 25 caracteres',
      );
    });

    test('aceita código com exatamente 25 caracteres', () {
      expect(
        AjusteRules.validarCodigoContratoSemPncp('ABCDEFGHIJKLMNOPQRSTUVWXY'),
        isNull,
      );
    });
  });

  group('AjusteRules.validarCodigoContrato e isCodigoContratoValido', () {
    test('aceita contrato PNCP válido de 25 dígitos com dígito 2 na 15ª posição (sem máscara)', () {
      // 14 dígitos de CNPJ (12345678000195) + '2' + 6 dígitos sequencial (000001) + 4 dígitos ano (2026) = 25 dígitos
      const validRaw = '1234567800019520000012026';
      expect(AjusteRules.validarCodigoContrato(validRaw), isNull);
      expect(AjusteRules.isCodigoContratoValido(validRaw), isTrue);
    });

    test('aceita contrato PNCP válido formatado com máscara', () {
      const validMasked = '12345678000195-2-000001/2026';
      expect(AjusteRules.validarCodigoContrato(validMasked), isNull);
      expect(AjusteRules.isCodigoContratoValido(validMasked), isTrue);
    });

    test('rejeita contrato cujo 15º dígito não é 2 (ex.: marcador 1 de compra/edital)', () {
      // 15º dígito é '1' (Edital/Licitação ao invés de Contrato)
      const editalRaw = '1234567800019510000012026';
      final errorRaw = AjusteRules.validarCodigoContrato(editalRaw);
      expect(errorRaw, 'O 15º dígito do ID do Contrato PNCP deve ser 2 (marcador de contrato)');
      expect(AjusteRules.isCodigoContratoValido(editalRaw), isFalse);

      const editalMasked = '12345678000195-1-000001/2026';
      final errorMasked = AjusteRules.validarCodigoContrato(editalMasked);
      expect(errorMasked, 'O 15º dígito do ID do Contrato PNCP deve ser 2 (marcador de contrato)');
      expect(AjusteRules.isCodigoContratoValido(editalMasked), isFalse);
    });

    test('rejeita contrato com outros dígitos na 15ª posição', () {
      const outroRaw = '1234567800019530000012026';
      expect(
        AjusteRules.validarCodigoContrato(outroRaw),
        'O 15º dígito do ID do Contrato PNCP deve ser 2 (marcador de contrato)',
      );
      expect(AjusteRules.isCodigoContratoValido(outroRaw), isFalse);
    });

    test('rejeita nulo ou vazio', () {
      expect(AjusteRules.validarCodigoContrato(null), 'Informe o ID do Contrato PNCP');
      expect(AjusteRules.validarCodigoContrato(''), 'Informe o ID do Contrato PNCP');
      expect(AjusteRules.validarCodigoContrato('   '), 'Informe o ID do Contrato PNCP');
      expect(AjusteRules.isCodigoContratoValido(null), isFalse);
      expect(AjusteRules.isCodigoContratoValido(''), isFalse);
    });

    test('rejeita contrato com menos de 25 dígitos', () {
      const incompleto = '12345678000195200000120';
      expect(
        AjusteRules.validarCodigoContrato(incompleto),
        'ID do Contrato PNCP incompleto (25 dígitos)',
      );
      expect(AjusteRules.isCodigoContratoValido(incompleto), isFalse);
    });

    test('rejeita contrato com mais de 25 dígitos', () {
      const longo = '123456780001952000001202699';
      expect(
        AjusteRules.validarCodigoContrato(longo),
        'ID do Contrato PNCP deve ter no máximo 25 dígitos',
      );
      expect(AjusteRules.isCodigoContratoValido(longo), isFalse);
    });
  });
}
