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

  test('envio troca o nome documentado mantendo a ordem', () {
    final doc = AjusteDocumento.paraEnvio({
      'dataAssinatura': '2026-03-01',
      'dataVigenciaInicio': '2026-03-09',
      'dataVigenciaFim': '2027-03-09',
    });
    expect(doc.keys, [
      'dataAssinatura',
      'datavigenciaInicio',
      'dataVigenciaFim',
    ]);
    expect(doc['datavigenciaInicio'], '2026-03-09');
  });

  test('o nome aceito prevalece se os dois existirem', () {
    expect(
      AjusteDocumento.paraEnvio({
        'datavigenciaInicio': '2026-03-10',
        'dataVigenciaInicio': '2026-03-09',
      }),
      {'datavigenciaInicio': '2026-03-10'},
    );
  });

  test('JSON salvo é corrigido; outros textos seguem iguais', () {
    final corrigido = AjusteDocumento.paraEnvioJson(
      jsonEncode({'dataVigenciaInicio': '2026-03-09', 'vigenciaMeses': 12}),
    );
    expect(jsonDecode(corrigido), {
      'datavigenciaInicio': '2026-03-09',
      'vigenciaMeses': 12,
    });
    const semCampo = '{"vigenciaMeses": 12}';
    expect(AjusteDocumento.paraEnvioJson(semCampo), semCampo);
    expect(AjusteDocumento.paraEnvioJson('inválido'), 'inválido');
  });
}
