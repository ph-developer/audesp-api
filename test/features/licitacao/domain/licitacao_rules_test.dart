import 'package:audesp_api/features/licitacao/domain/licitacao_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoje = DateTime(2026, 10, 27);
  group('LicitacaoRules.validarPercentualGarantia', () {
    test('exige percentual quando a garantia é exigida', () {
      expect(
        LicitacaoRules.validarPercentualGarantia(
          exigenciaGarantiaLicitantes: 1,
          percentualValor: null,
        ),
        'Informe o percentual da garantia quando a exigência for "Sim".',
      );
    });

    test('aceita zero, cem e percentuais fracionários', () {
      for (final percentual in [0, 0.5, 99.9999, 100]) {
        expect(
          LicitacaoRules.validarPercentualGarantia(
            exigenciaGarantiaLicitantes: 1,
            percentualValor: percentual,
          ),
          isNull,
        );
      }
    });

    test('rejeita valores fora do intervalo ou não finitos', () {
      for (final percentual in [
        -0.0001,
        100.0001,
        double.nan,
        double.infinity,
      ]) {
        expect(
          LicitacaoRules.validarPercentualGarantia(
            exigenciaGarantiaLicitantes: 1,
            percentualValor: percentual,
          ),
          'O percentual da garantia deve estar entre 0 e 100.',
        );
      }
    });

    test('permite percentual ausente quando a garantia não é exigida', () {
      for (final exigencia in [2, 3, null]) {
        expect(
          LicitacaoRules.validarPercentualGarantia(
            exigenciaGarantiaLicitantes: exigencia,
            percentualValor: null,
          ),
          isNull,
        );
      }
    });
  });

  group('LicitacaoRules.validarNomeIndice', () {
    test('exige de 3 a 50 caracteres para Outro', () {
      for (final nome in [null, '', '   ', 'ab', ' ab ', 'a' * 51]) {
        expect(
          LicitacaoRules.validarNomeIndice(tipoIndice: 8, nomeIndice: nome),
          'Informe o nome do índice "Outro" com 3 a 50 caracteres.',
        );
      }
    });

    test('aceita os limites após remover espaços nas extremidades', () {
      for (final nome in ['abc', 'a' * 50, ' abc ', ' ${'a' * 50} ']) {
        expect(
          LicitacaoRules.validarNomeIndice(tipoIndice: 8, nomeIndice: nome),
          isNull,
        );
      }
    });

    test('mantém o nome opcional nos demais tipos', () {
      for (final tipo in [1, 2, 3, 4, 5, 6, 7, null]) {
        expect(
          LicitacaoRules.validarNomeIndice(tipoIndice: tipo, nomeIndice: null),
          isNull,
        );
      }
    });
  });

  group('LicitacaoRules.validarEnvio', () {
    test('bloqueia documento final sem percentual da garantia exigida', () {
      expect(
        LicitacaoRules.validarEnvio({
          'exigenciaGarantiaLicitantes': 1,
        }, hoje: hoje),
        'Informe o percentual da garantia quando a exigência for "Sim".',
      );
    });

    test('bloqueia percentual fora do intervalo no documento final', () {
      expect(
        LicitacaoRules.validarEnvio({
          'exigenciaGarantiaLicitantes': 1,
          'percentualValor': 101,
        }, hoje: hoje),
        'O percentual da garantia deve estar entre 0 e 100.',
      );
    });

    test('bloqueia índice Outro de rascunho antigo sem nome válido', () {
      for (final nome in [null, '', 'ab', 'a' * 51]) {
        expect(
          LicitacaoRules.validarEnvio({
            'exigenciaGarantiaLicitantes': 2,
            'indicesEconomicos': [
              {'tipoIndice': 1, 'valorIndice': 1.5},
              {'tipoIndice': 8, 'valorIndice': 1.0, 'nomeIndice': ?nome},
            ],
          }, hoje: hoje),
          'Informe o nome do índice "Outro" com 3 a 50 caracteres.',
        );
      }
    });

    test('aceita documento final com garantia e índices válidos', () {
      expect(
        LicitacaoRules.validarEnvio({
          'exigenciaGarantiaLicitantes': 1,
          'percentualValor': 0,
          'indicesEconomicos': [
            {'tipoIndice': 1, 'valorIndice': 1.5},
            {'tipoIndice': 8, 'valorIndice': 1.0, 'nomeIndice': 'Outro índice'},
          ],
        }, hoje: hoje),
        isNull,
      );
    });

    test('aceita documento sem garantia exigida nem índices', () {
      expect(
        LicitacaoRules.validarEnvio({
          'exigenciaGarantiaLicitantes': 2,
        }, hoje: hoje),
        isNull,
      );
    });
  });
}
