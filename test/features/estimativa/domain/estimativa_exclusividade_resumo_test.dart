import 'package:audesp_api/features/estimativa/domain/estimativa_exclusividade_resumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula valor e percentual selecionados', () {
    final resumo = EstimativaExclusividadeResumo.calcular([
      (valor: 100.0, selecionado: true),
      (valor: 200.0, selecionado: false),
      (valor: 300.0, selecionado: true),
    ]);

    expect(resumo.valorTotal, 600);
    expect(resumo.valorSelecionado, 400);
    expect(resumo.percentualSelecionado, closeTo(66.6667, 0.0001));
  });

  test('percentual é zero quando o valor total é zero', () {
    final resumo = EstimativaExclusividadeResumo.calcular([
      (valor: 0.0, selecionado: true),
    ]);

    expect(resumo.valorTotal, 0);
    expect(resumo.valorSelecionado, 0);
    expect(resumo.percentualSelecionado, 0);
  });
}
