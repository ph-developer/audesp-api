import 'package:audesp_api/features/estimativa/models/estimativa_fornecedor_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_item_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_lote_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_orcamento_model.dart';
import 'package:audesp_api/features/estimativa/services/estimativa_html_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cálculo de Lote - Menor Preço Unitário vs Menor Preço Global', () {
    late EstimativaFornecedor fA;
    late EstimativaFornecedor fB;
    late EstimativaItem item1;
    late EstimativaItem item2;
    late EstimativaLote lote;

    setUp(() {
      fA = EstimativaFornecedor(
        id: 'fA',
        razaoSocial: 'Empresa A',
        cnpj: '11111111000111',
        data: '01/01/2026',
      );
      fB = EstimativaFornecedor(
        id: 'fB',
        razaoSocial: 'Empresa B',
        cnpj: '22222222000122',
        data: '01/01/2026',
      );

      // Empresa A: Item 1 = R$ 10.00 (qtd 10 -> R$ 100), Item 2 = R$ 50.00 (qtd 2 -> R$ 100). Total Lote A = R$ 200.00
      // Empresa B: Item 1 = R$ 15.00 (qtd 10 -> R$ 150), Item 2 = R$ 20.00 (qtd 2 -> R$ 40). Total Lote B = R$ 190.00
      item1 = EstimativaItem(
        numero: 1,
        descricao: 'Item 1',
        unidade: 'UN',
        quantidade: 10,
        orcamentos: [
          EstimativaOrcamento(fornecedorId: 'fA', valorUnitario: 10.0),
          EstimativaOrcamento(fornecedorId: 'fB', valorUnitario: 15.0),
        ],
      );

      item2 = EstimativaItem(
        numero: 2,
        descricao: 'Item 2',
        unidade: 'UN',
        quantidade: 2,
        orcamentos: [
          EstimativaOrcamento(fornecedorId: 'fA', valorUnitario: 50.0),
          EstimativaOrcamento(fornecedorId: 'fB', valorUnitario: 20.0),
        ],
      );

      lote = EstimativaLote(
        numero: 1,
        descricao: 'Lote 1',
        itens: [item1, item2],
      );
    });

    test('Menor Preço (Unitário) calcula a soma dos menores preços de itens avulsos', () {
      // Item 1 min: R$ 10.00 * 10 = R$ 100.00
      // Item 2 min: R$ 20.00 * 2 = R$ 40.00
      // Total lote: R$ 140.00
      final totalUnitario = lote.getValorTotal('min');
      expect(totalUnitario, 140.0);
    });

    test('Menor Preço (Global) calcula o menor valor global de uma única empresa', () {
      // Empresa A: 10*10 + 2*50 = 200.00
      // Empresa B: 10*15 + 2*20 = 190.00
      // Vencedor global: Empresa B (R$ 190.00)
      expect(lote.getFornecedorMenorPrecoGlobalId(), 'fB');
      final totalGlobal = lote.getValorTotal('min_global');
      expect(totalGlobal, 190.0);

      // Valores de referência dos itens refletem a Empresa B
      final fVencedor = lote.getFornecedorMenorPrecoGlobalId();
      expect(
        item1.getValorReferenciaUnitario('min_global', fornecedorVencedorId: fVencedor),
        15.0,
      );
      expect(
        item2.getValorReferenciaUnitario('min_global', fornecedorVencedorId: fVencedor),
        20.0,
      );
    });

    test('Desconsidera fornecedor desclassificado no cálculo global do lote', () {
      final fDesclassificado = EstimativaFornecedor(
        id: 'fB',
        razaoSocial: 'Empresa B',
        cnpj: '22222222000122',
        data: '01/01/2026',
        desclassificado: true,
      );

      final totalSemB = lote.getValorTotal(
        'min_global',
        desclassificadosIds: [fDesclassificado.id],
      );

      // Sem Empresa B, Empresa A vence com R$ 200.00
      expect(totalSemB, 200.0);
    });

    test('EstimativaModel valorTotalGlobal calcula corretamente por lote', () {
      final estimativaUnitario = EstimativaModel(
        id: 1,
        numero: 1,
        ano: 2026,
        objeto: 'Teste',
        tipoEstimativa: 'lote',
        calculoGlobal: 'min',
        fornecedores: [fA, fB],
        lotes: [lote],
      );
      expect(estimativaUnitario.valorTotalGlobal, 140.0);

      final estimativaGlobal = EstimativaModel(
        id: 1,
        numero: 1,
        ano: 2026,
        objeto: 'Teste',
        tipoEstimativa: 'lote',
        calculoGlobal: 'min_global',
        fornecedores: [fA, fB],
        lotes: [lote],
      );
      expect(estimativaGlobal.valorTotalGlobal, 190.0);
    });

    test('EstimativaHtmlService exibe rótulo correto para min_global', () {
      final estimativaGlobal = EstimativaModel(
        id: 1,
        numero: 1,
        ano: 2026,
        objeto: 'Teste',
        tipoEstimativa: 'lote',
        calculoGlobal: 'min_global',
        fornecedores: [fA, fB],
        lotes: [lote],
      );

      final html = EstimativaHtmlService.gerarHtmlEstimativa(estimativaGlobal);
      expect(html.contains('Menor Preço (Global)'), isTrue);
      expect(html.contains('Vencedor do Lote:</strong> Empresa B (22.222.222/0001-22)'), isTrue);
      expect(html.contains('Subtotal do Lote: R\$&nbsp;190,00') || html.contains('190,00'), isTrue);
    });

    test('EstimativaHtmlService exibe observacao de Banco de Precos (singular)', () {
      final fBP = EstimativaFornecedor(
        id: 'fBP',
        razaoSocial: 'Banco de Precos SA',
        cnpj: '33333333000133',
        data: '01/01/2026',
        bancoDePrecos: true,
      );
      final est = EstimativaModel(
        id: 1,
        numero: 1,
        ano: 2026,
        objeto: 'Teste',
        fornecedores: [fA, fBP],
        itens: [item1],
      );

      final html = EstimativaHtmlService.gerarHtmlEstimativa(est);
      expect(html.contains('OBSERVAÇÃO:</strong> A razão social Banco de Precos SA, corresponde a plataforma de Banco de Preços'), isTrue);
    });

    test('EstimativaHtmlService exibe observacao de Banco de Precos (plural)', () {
      final fBP1 = EstimativaFornecedor(
        id: 'fBP1',
        razaoSocial: 'Plataforma Alfa',
        cnpj: '33333333000133',
        data: '01/01/2026',
        bancoDePrecos: true,
      );
      final fBP2 = EstimativaFornecedor(
        id: 'fBP2',
        razaoSocial: 'Plataforma Beta',
        cnpj: '44444444000144',
        data: '01/01/2026',
        bancoDePrecos: true,
      );
      final est = EstimativaModel(
        id: 1,
        numero: 1,
        ano: 2026,
        objeto: 'Teste',
        fornecedores: [fBP1, fBP2],
        itens: [item1],
      );

      final html = EstimativaHtmlService.gerarHtmlEstimativa(est);
      expect(html.contains('OBSERVAÇÃO:</strong> As razões sociais Plataforma Alfa e Plataforma Beta, correspondem a plataformas de Banco de Preços'), isTrue);
    });
  });
}

