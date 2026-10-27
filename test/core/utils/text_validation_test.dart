import 'package:audesp_api/core/utils/text_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validarTamanhoMaximo', () {
    test('permite campos opcionais nulos ou vazios', () {
      for (final value in [null, '', '   ']) {
        expect(validarTamanhoMaximo(value, 30), isNull);
      }
    });

    for (final limite in [30, 50, 100, 5120]) {
      group('limite de $limite caracteres', () {
        test('aceita o limite e valores menores', () {
          expect(validarTamanhoMaximo('a' * (limite - 1), limite), isNull);
          expect(validarTamanhoMaximo('a' * limite, limite), isNull);
        });

        test('rejeita texto importado acima do limite', () {
          expect(
            validarTamanhoMaximo('a' * (limite + 1), limite),
            'Máximo $limite caracteres',
          );
        });

        test(
          'considera o texto sem espaços nas extremidades como no envio',
          () {
            expect(validarTamanhoMaximo(' ${'a' * limite} ', limite), isNull);
            expect(
              validarTamanhoMaximo(' ${'a' * (limite + 1)} ', limite),
              'Máximo $limite caracteres',
            );
          },
        );
      });
    }
  });
}
