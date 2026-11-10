import 'dart:convert';

import 'package:audesp_api/features/ajuste/domain/ajuste_documento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê o início da vigência pelos dois nomes', () {
    expect(
      AjusteDocumento.vigenciaInicio({'datavigenciaInicio': '2026-03-09'}),
      '2026-03-09',
    );
    expect(
      AjusteDocumento.vigenciaInicio({'dataVigenciaInicio': '2026-03-09'}),
      '2026-03-09',
    );
    expect(AjusteDocumento.vigenciaInicio({}), isNull);
  });

  test('envia a mesma data nas duas grafias a partir de qualquer uma', () {
    for (final campo in ['datavigenciaInicio', 'dataVigenciaInicio']) {
      final enviado = AjusteDocumento.paraEnvioJson(
        jsonEncode({
          'dataAssinatura': '2026-06-09',
          campo: '2026-06-09',
          'dataVigenciaFim': '2026-07-24',
        }),
      );
      expect(jsonDecode(enviado), {
        'dataAssinatura': '2026-06-09',
        'datavigenciaInicio': '2026-06-09',
        'dataVigenciaInicio': '2026-06-09',
        'dataVigenciaFim': '2026-07-24',
      });
    }
  });

  test('a data do campo com v minúsculo prevalece em caso de conflito', () {
    expect(
      AjusteDocumento.paraEnvio({
        'datavigenciaInicio': '2026-03-10',
        'dataVigenciaInicio': '2026-03-09',
      }),
      {'datavigenciaInicio': '2026-03-10', 'dataVigenciaInicio': '2026-03-10'},
    );
  });

  test('preserva JSON sem data, já normalizado ou inválido', () {
    for (final json in [
      '{"vigenciaMeses": 12}',
      '{"dataVigenciaInicio": ""}',
      '{"datavigenciaInicio": "2026-03-09", "dataVigenciaInicio": "2026-03-09"}',
      'inválido',
    ]) {
      expect(AjusteDocumento.paraEnvioJson(json), json);
    }
  });
}
