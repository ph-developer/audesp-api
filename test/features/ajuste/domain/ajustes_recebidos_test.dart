import 'package:audesp_api/features/ajuste/domain/ajustes_recebidos.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pendencias/pendencias_fixtures.dart';
import '../../processo/processo_fixtures.dart';

void main() {
  test('lista só ajustes enviados com o último protocolo Recebido', () {
    final recebido = ajusteFixture(1, status: 'sent', codigo: 'C1');
    final pendente = ajusteFixture(2, status: 'sent', codigo: 'C2');
    final rascunho = ajusteFixture(3, codigo: 'C3');
    final oculto = ajusteFixture(4, editalId: 9, status: 'sent', codigo: 'C4');
    final armazenado = ajusteFixture(5, status: 'sent', codigo: 'C5');
    final adesao = ajusteFixture(
      6,
      editalId: null,
      status: 'sent',
      codigo: 'C6',
    );
    final documentos = DocumentosProcesso(
      editais: [
        processoFixture().edital,
        processoFixture(id: 9, oculto: true).edital,
      ],
      ajustes: [recebido, pendente, rascunho, oculto, armazenado, adesao],
    );
    final envios = EnviosProcesso(
      editais: EnviosIndex.vazio,
      licitacoes: EnviosIndex.vazio,
      atas: EnviosIndex.vazio,
      ajustes: EnviosIndex([
        envioFixture(recebido, id: 1),
        envioFixture(pendente, id: 2, situacao: 'Pendente'),
        envioFixture(rascunho, id: 3),
        envioFixture(oculto, id: 4),
        // Retificação em análise não desfaz o armazenado.
        envioFixture(armazenado, id: 6),
        envioFixture(armazenado, id: 5, situacao: 'Armazenado'),
        envioFixture(adesao, id: 7),
      ]),
      baseUrl: ambientePendencias,
    );

    final lista = AjusteRecebido.listar(documentos, envios);
    expect(lista.map((r) => r.ajuste.id), [1, 6]);
    expect(lista.first.envio.id, 1);
  });

  test('envio em outro ambiente não conta', () {
    final ajuste = ajusteFixture(1, status: 'sent', codigo: 'C1');
    final envios = EnviosProcesso(
      editais: EnviosIndex.vazio,
      licitacoes: EnviosIndex.vazio,
      atas: EnviosIndex.vazio,
      ajustes: EnviosIndex([
        envioFixture(ajuste, ambiente: 'https://audesp.tce.sp.gov.br'),
      ]),
      baseUrl: ambientePendencias,
    );
    expect(
      AjusteRecebido.listar(DocumentosProcesso(ajustes: [ajuste]), envios),
      isEmpty,
    );
  });

  test('rejeitado só pela RN012 com o nome documentado entra no reenvio', () {
    const antigo = '{"dataVigenciaInicio": "2026-03-09"}';
    const novo = '{"datavigenciaInicio": "2026-03-09"}';
    final soVigencia = ajusteFixture(
      1,
      status: 'sent',
      codigo: 'C1',
      documentoJson: antigo,
    );
    final outrosErros = ajusteFixture(
      2,
      status: 'sent',
      codigo: 'C2',
      documentoJson: antigo,
    );
    final jaCorrigido = ajusteFixture(
      3,
      status: 'sent',
      codigo: 'C3',
      documentoJson: novo,
    );
    final semCodigo = ajusteFixture(
      4,
      status: 'sent',
      codigo: 'C4',
      documentoJson: antigo,
    );
    final envios = EnviosProcesso(
      editais: EnviosIndex.vazio,
      licitacoes: EnviosIndex.vazio,
      atas: EnviosIndex.vazio,
      ajustes: EnviosIndex([
        envioFixture(
          soVigencia,
          id: 1,
          situacao: 'Rejeitado',
          codigosErro: ['RN012_AJUSTE'],
        ),
        envioFixture(
          outrosErros,
          id: 2,
          situacao: 'Rejeitado',
          codigosErro: ['RN012_AJUSTE', 'RN020_AJUSTE'],
        ),
        envioFixture(
          jaCorrigido,
          id: 3,
          situacao: 'Rejeitado',
          codigosErro: ['RN012_AJUSTE'],
        ),
        envioFixture(semCodigo, id: 4, situacao: 'Rejeitado'),
      ]),
      baseUrl: ambientePendencias,
    );

    final lista = AjusteRecebido.listar(
      DocumentosProcesso(
        editais: [processoFixture().edital],
        ajustes: [soVigencia, outrosErros, jaCorrigido, semCodigo],
      ),
      envios,
    );
    expect(lista.map((r) => r.ajuste.id), [1]);
    expect(lista.single.motivo, MotivoReenvio.vigenciaRejeitada);
  });
}
