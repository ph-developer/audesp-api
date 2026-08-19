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
}
