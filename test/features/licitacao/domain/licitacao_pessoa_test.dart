import 'package:audesp_api/features/licitacao/domain/licitacao_pessoa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizarNiPessoa', () {
    test('remove máscara e caracteres não numéricos de PJ e PF', () {
      expect(
        normalizarNiPessoa('PJ', ' 14.733.837/0001-54 '),
        '14733837000154',
      );
      expect(normalizarNiPessoa('PF', ' 330.206.793-89 '), '33020679389');
      expect(normalizarNiPessoa('PJ', 'AB123'), '123');
      expect(normalizarNiPessoa('PF', 'AB123'), '123');
    });

    test('preserva as letras do identificador PE do exemplo oficial', () {
      expect(
        normalizarNiPessoa('PE', ' 01234FG567890123 '),
        '01234FG567890123',
      );
    });

    test(
      'aplica somente trim a PE, preservando pontuação e espaços internos',
      () {
        expect(
          normalizarNiPessoa('PE', '  AB-12.34/FG 56  '),
          'AB-12.34/FG 56',
        );
      },
    );

    test('preserva identificador já normalizado', () {
      for (final tipo in ['PJ', 'PF', 'PE']) {
        expect(normalizarNiPessoa(tipo, '01234567890'), '01234567890');
      }
    });

    test('retorna vazio para texto vazio ou somente espaços', () {
      for (final tipo in ['PJ', 'PF', 'PE']) {
        expect(normalizarNiPessoa(tipo, ''), isEmpty);
        expect(normalizarNiPessoa(tipo, '   '), isEmpty);
      }
    });
  });
}
