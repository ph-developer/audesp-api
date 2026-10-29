import 'package:audesp_api/features/edital/domain/edital_itens_resumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('soma valores, conta tipos e agrupa por benefício', () {
    final resumo = EditalItensResumo.calcular([
      {
        'materialOuServico': 'M',
        'tipoBeneficioId': 4,
        'valorTotal': 600.0,
        'orcamentoSigiloso': true,
      },
      {'materialOuServico': 'S', 'tipoBeneficioId': 1, 'valorTotal': 300},
      {'materialOuServico': 'M', 'tipoBeneficioId': 3, 'valorTotal': 100.0},
      {'materialOuServico': 'M', 'tipoBeneficioId': 4, 'valorTotal': 0.0},
      {'materialOuServico': 'M'},
    ]);

    expect(resumo.quantidadeItens, 5);
    expect(resumo.materiais, 4);
    expect(resumo.servicos, 1);
    expect(resumo.semValor, 2);
    expect(resumo.sigilosos, 1);
    expect(resumo.valorTotal, 1000);
    expect(resumo.porBeneficio.keys, [1, 3, 4]);
    expect(resumo.porBeneficio[4], (itens: 2, valor: 600.0));
    expect(resumo.valorMeEpp, 400);
    expect(resumo.percentual(resumo.valorMeEpp), 40);
  });

  test('lista vazia não divide por zero', () {
    final resumo = EditalItensResumo.calcular([]);
    expect(resumo.valorTotal, 0);
    expect(resumo.percentual(10), 0);
    expect(resumo.porBeneficio, isEmpty);
  });
}
