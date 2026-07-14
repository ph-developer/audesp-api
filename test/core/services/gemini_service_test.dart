import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/services/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppSettingsDao implements AppSettingsDao {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  late GeminiService service;

  setUp(() {
    service = GeminiService(_FakeAppSettingsDao());
  });

  test('ignora itens com valor zero no orçamento único', () {
    final result = service.parseOrcamentoResult('''
{
  "razaoSocial": "Fornecedor",
  "itens": [
    {"id": "1", "valorUnitario": 0},
    {"id": "2", "valorUnitario": 12.5}
  ]
}
''');

    expect(result.itens, {'2': 12.5});
  });

  test('ignora itens e fornecedores somente com valores zero no múltiplo', () {
    final results = service.parseMultiOrcamentoResult('''
{
  "empresas": [
    {
      "razaoSocial": "Sem cotação",
      "itens": [{"id": "1", "valorUnitario": 0}]
    },
    {
      "razaoSocial": "Com cotação",
      "itens": [
        {"id": "1", "valorUnitario": 0},
        {"id": "2", "valorUnitario": 20}
      ]
    }
  ]
}
''');

    expect(results, hasLength(1));
    expect(results.single.razaoSocial, 'Com cotação');
    expect(results.single.itens, {'2': 20});
  });
}
