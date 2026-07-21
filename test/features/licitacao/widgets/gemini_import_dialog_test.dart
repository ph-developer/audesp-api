import 'package:audesp_api/features/licitacao/widgets/gemini_import_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('importação Gemini não solicita Audiência Pública', () {
    final fieldKeys = kLicitacaoGeminiFields.map((field) => field.key);

    expect(fieldKeys, isNot(contains('audienciaPublica')));
  });
}
