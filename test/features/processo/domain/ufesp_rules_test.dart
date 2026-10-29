import 'package:audesp_api/features/processo/domain/ufesp_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pncp/pncp_fixtures.dart';

void main() {
  test('limite padrão é 2.500 UFESP de R\$ 38,42', () {
    expect(const UfespConfig().limite, closeTo(96050, 0.001));
  });

  test('abaixo do limite o envio não é obrigatório', () {
    const config = UfespConfig();
    expect(config.envioObrigatorio(96049.99), isFalse);
    expect(config.envioObrigatorio(96050), isTrue);
    expect(config.envioObrigatorio(200000), isTrue);
  });

  test('sem valor estimado não indica nada', () {
    const config = UfespConfig();
    expect(config.envioObrigatorio(null), isTrue);
    expect(config.envioObrigatorio(0), isTrue);
  });

  test('lê a configuração salva e usa o padrão quando inválida', () {
    final config = UfespConfig.fromSettings(valor: '40,5', quantidade: '1000');
    expect(config.limite, 40500);
    final padrao = UfespConfig.fromSettings(valor: 'x', quantidade: null);
    expect(padrao.valorUfesp, UfespConfig.valorPadrao);
    expect(padrao.quantidadeMinima, UfespConfig.quantidadePadrao);
  });

  test('valor do edital soma o total dos itens', () {
    final edital = editalFixture(
      documento: {
        'itensCompra': [
          {'valorTotal': 60000.5},
          {'valorTotal': 30000},
          {'descricao': 'sem valor'},
        ],
      },
    );
    expect(edital.valorTotalEstimado, 90000.5);
    expect(editalFixture().valorTotalEstimado, 0);
  });
}
