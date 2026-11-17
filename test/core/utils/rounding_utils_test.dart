import 'package:audesp_api/core/utils/rounding_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('arredondarParaCima', () {
    test('não acrescenta um centavo ao produto de 85.680 por 3,58', () {
      expect(arredondarParaCima(85680 * 3.58, 2), 306734.40);
    });

    test('não acrescenta uma fração ao produto com quatro casas', () {
      expect(arredondarParaCima(85680 * 3.5807, 4), 306794.3760);
    });

    test('continua absorvendo resíduos em valores menores', () {
      expect(arredondarParaCima(6 * 477.6, 2), 2865.60);
      expect(arredondarParaCima(0.1 + 0.2, 2), 0.30);
    });

    test('preserva zero e valores que já têm a precisão desejada', () {
      expect(arredondarParaCima(0, 2), 0);
      expect(arredondarParaCima(3.58, 2), 3.58);
      expect(arredondarParaCima(3.5807, 4), 3.5807);
    });

    test('arredonda frações reais para cima, mesmo abaixo de meia unidade', () {
      expect(arredondarParaCima(1.231, 2), 1.24);
      expect(arredondarParaCima(1.23451, 4), 1.2346);
    });

    test('não confunde frações reais pequenas com resíduos numéricos', () {
      expect(arredondarParaCima(1.2300000001, 2), 1.24);
      expect(arredondarParaCima(306734.400001, 2), 306734.41);
      expect(arredondarParaCima(306794.376001, 4), 306794.3761);
    });

    test('mantém o arredondamento para cima em valores negativos', () {
      expect(arredondarParaCima(-1.231, 2), -1.23);
      expect(arredondarParaCima(-1.23451, 4), -1.2345);
    });
  });
}
