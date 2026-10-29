import 'package:audesp_api/features/pncp/domain/pncp_edital_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pncp_fixtures.dart';

void main() {
  test('monta o cabeçalho do edital sem trazer itens', () {
    final doc = PncpEditalMapper.documento(compraPncpJson());

    expect(doc['descritor'], {
      'codigoEdital': '4639500000013910000022026',
      'retificacao': false,
    });
    expect(doc['publicidade'], {
      'houvePublicacao': true,
      'publicacoes': [
        {
          'dataPublicacao': '2025-10-17',
          'veiculoPublicacao': 5,
          'idContratacaoPNCP': '4639500000013910000022026',
        },
      ],
    });
    expect(doc['tipoInstrumentoConvocatorioId'], 3);
    expect(doc['modalidadeId'], 8);
    expect(doc['modoDisputaId'], 5);
    expect(doc['numeroCompra'], '125');
    expect(doc['anoCompra'], 2026);
    expect(doc['numeroProcesso'], '6077.2025/0000093-5');
    expect(doc['objetoCompra'], 'Hospedagem e manutenção evolutiva do SMAE');
    expect(doc['srp'], isFalse);
    expect(doc['amparoLegalId'], 45);
    expect(doc['itensCompra'], isEmpty);
    // Campos nulos no PNCP não entram no documento.
    expect(doc.containsKey('dataAberturaProposta'), isFalse);
    expect(doc.containsKey('linkSistemaOrigem'), isFalse);
    expect(doc.containsKey('informacaoComplementar'), isFalse);
  });

  test('formata as datas de proposta como o formulário do edital', () {
    final doc = PncpEditalMapper.documento({
      ...compraPncpJson(),
      'dataAberturaProposta': '2026-11-03T09:00:00',
      'dataEncerramentoProposta': '2026-11-17T10:30:00',
      'dataPublicacaoPncp': null,
    });
    expect(doc['dataAberturaProposta'], '2026-11-03T09:00:00');
    expect(doc['dataEncerramentoProposta'], '2026-11-17T10:30:00');
    expect(doc['publicidade'], {'houvePublicacao': false});
  });
}
