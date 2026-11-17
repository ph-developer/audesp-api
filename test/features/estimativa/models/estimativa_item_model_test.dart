import 'package:audesp_api/features/estimativa/models/estimativa_item_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_lote_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_orcamento_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final item = EstimativaItem(
    numero: 24,
    descricao: 'Fralda descartável para adulto',
    unidade: 'fralda',
    quantidade: 85680,
    orcamentos: [EstimativaOrcamento(fornecedorId: 'f1', valorUnitario: 3.58)],
  );

  for (final calculo in ['min', 'avg', 'median', 'desc', 'min_global']) {
    test('total de 85.680 fraldas a 3,58 é 306.734,40 usando $calculo', () {
      expect(
        item.getValorReferenciaUnitario(calculo, fornecedorVencedorId: 'f1'),
        3.58,
      );
      expect(
        item.getValorTotal(calculo, fornecedorVencedorId: 'f1'),
        306734.40,
      );
    });
  }

  test('cálculo mensal não acrescenta centavos ao mês nem ao total', () {
    final mensal = item.copyWith(
      tipoFornecimento: 'mensal',
      quantidadeMeses: 12,
    );

    expect(mensal.getValorMensal('min'), 306734.40);
    expect(mensal.getValorTotal('min'), 3680812.80);
  });

  test('respeita quatro casas decimais sem acrescentar uma fração', () {
    final quatroCasas = item.copyWith(
      orcamentos: [
        EstimativaOrcamento(fornecedorId: 'f1', valorUnitario: 3.5807),
      ],
    );

    expect(quatroCasas.getValorTotal('min', casasDecimais: 4), 306794.3760);
  });

  test(
    'quantidade fracionada com fração real de centavo arredonda para cima',
    () {
      expect(item.copyWith(quantidade: 0.3).getValorTotal('min'), 1.08);
    },
  );

  for (final tipoEstimativa in ['item', 'lote']) {
    test('total global por $tipoEstimativa usa o valor corrigido do item', () {
      final estimativa = EstimativaModel(
        id: 1,
        numero: 1,
        ano: 2026,
        objeto: 'Fraldas descartáveis',
        tipoEstimativa: tipoEstimativa,
        calculoGlobal: 'min',
        itens: [item],
        lotes: [
          EstimativaLote(numero: 1, descricao: 'Fraldas', itens: [item]),
        ],
      );

      expect(estimativa.valorTotalGlobal, 306734.40);
    });
  }
}
