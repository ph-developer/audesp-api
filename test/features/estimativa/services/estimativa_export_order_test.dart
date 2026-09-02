import 'package:audesp_api/features/estimativa/models/estimativa_fornecedor_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_item_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_orcamento_model.dart';
import 'package:audesp_api/features/estimativa/services/estimativa_html_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EstimativaHtmlService gera orçamentos ordenados de forma crescente por valor', () {
    final f1 = EstimativaFornecedor(
      id: 'f1',
      razaoSocial: 'Fornecedor Menor',
      cnpj: '11111111000111',
      data: '01/01/2026',
    );
    final f2 = EstimativaFornecedor(
      id: 'f2',
      razaoSocial: 'Fornecedor Maior',
      cnpj: '22222222000122',
      data: '02/01/2026',
    );
    final f3 = EstimativaFornecedor(
      id: 'f3',
      razaoSocial: 'Fornecedor Medio',
      cnpj: '33333333000133',
      data: '03/01/2026',
    );

    final item = EstimativaItem(
      numero: 1,
      descricao: 'Item Teste',
      unidade: 'UN',
      quantidade: 10,
      orcamentos: [
        EstimativaOrcamento(fornecedorId: 'f1', valorUnitario: 10.0),
        EstimativaOrcamento(fornecedorId: 'f2', valorUnitario: 30.0),
        EstimativaOrcamento(fornecedorId: 'f3', valorUnitario: 20.0),
      ],
    );

    final estimativa = EstimativaModel(
      id: 1,
      numero: 1,
      ano: 2026,
      objeto: 'Objeto Teste',
      fornecedores: [f1, f2, f3],
      itens: [item],
    );

    final html = EstimativaHtmlService.gerarHtmlEstimativa(estimativa);

    final posMaior = html.indexOf('Fornecedor Maior');
    final posMedio = html.indexOf('Fornecedor Medio');
    final posMenor = html.indexOf('Fornecedor Menor');

    expect(posMaior, isNot(-1));
    expect(posMedio, isNot(-1));
    expect(posMenor, isNot(-1));

    // Ordem crescente: Menor (10.0) -> Médio (20.0) -> Maior (30.0)
    expect(posMenor < posMedio, isTrue);
    expect(posMedio < posMaior, isTrue);
  });
}
