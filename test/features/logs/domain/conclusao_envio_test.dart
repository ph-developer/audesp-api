import 'package:audesp_api/features/logs/domain/conclusao_envio.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:flutter_test/flutter_test.dart';

const _oficial = 'https://audesp.tce.sp.gov.br';
const _piloto = 'https://audesp-piloto.tce.sp.gov.br';

EnvioResumo _envio(
  int id, {
  int statusCode = 200,
  String? statusProtocolo,
  String baseUrl = _oficial,
}) => EnvioResumo(
  id: id,
  statusCode: statusCode,
  protocolo: statusCode == 200 ? 'P$id' : null,
  statusProtocolo: statusProtocolo,
  timestamp: DateTime(2026, 11, 1),
  descritor: const {},
  endpoint: '$baseUrl/recepcao-fase-4/f4/enviar-edital',
);

ConclusaoEnvio _de(String status, List<EnvioResumo> envios) =>
    ConclusaoEnvio.de(status: status, envios: envios, baseUrl: _oficial);

void main() {
  group('sem envio aceito', () {
    test('documento enviado sem log (legado) conta como concluído', () {
      expect(_de('sent', []).concluida, isTrue);
    });

    test('legado vale mesmo com tentativas que falharam', () {
      expect(_de('sent', [_envio(1, statusCode: 500)]).concluida, isTrue);
    });

    test('rascunho não foi enviado', () {
      expect(_de('draft', []).situacao, SituacaoConclusao.naoEnviado);
      expect(
        _de('draft', [_envio(1, statusCode: 400)]).situacao,
        SituacaoConclusao.naoEnviado,
      );
    });
  });

  group('com envios aceitos', () {
    test('armazenado conclui', () {
      final conclusao = _de('sent', [_envio(1, statusProtocolo: 'Armazenado')]);
      expect(conclusao.concluida, isTrue);
      expect(conclusao.envio?.id, 1);
      expect(conclusao.motivo('edital'), isNull);
    });

    test('substituído conta como armazenado', () {
      expect(
        _de('sent', [_envio(1, statusProtocolo: 'Substituído')]).concluida,
        isTrue,
      );
    });

    test('retificação posterior em análise não desfaz a conclusão', () {
      expect(
        _de('draft', [
          _envio(2, statusProtocolo: 'Recebido'),
          _envio(1, statusProtocolo: 'Armazenado'),
        ]).concluida,
        isTrue,
      );
    });

    test('em análise mostra a situação do protocolo', () {
      final conclusao = _de('sent', [_envio(1, statusProtocolo: 'Recebido')]);
      expect(conclusao.situacao, SituacaoConclusao.emAnalise);
      expect(
        conclusao.motivo('edital'),
        'O protocolo do edital ainda não foi armazenado pelo AUDESP '
        '(situação: Recebido).',
      );
    });

    test('rejeitado e excluído usam o último envio aceito', () {
      expect(
        _de('sent', [
          _envio(3, statusCode: 500),
          _envio(2, statusProtocolo: 'Rejeitado'),
          _envio(1, statusProtocolo: 'Recebido'),
        ]).situacao,
        SituacaoConclusao.rejeitado,
      );
      expect(
        _de('sent', [_envio(1, statusProtocolo: 'Excluído')]).situacao,
        SituacaoConclusao.excluido,
      );
    });

    test('envio só em outro ambiente não conta como enviado', () {
      final conclusao = _de('sent', [
        _envio(1, statusProtocolo: 'Armazenado', baseUrl: _piloto),
      ]);
      expect(conclusao.situacao, SituacaoConclusao.naoEnviado);
    });
  });

  test('motivo concorda com o gênero do documento', () {
    expect(
      _de('draft', []).motivo('licitação do edital', feminino: true),
      'A licitação do edital ainda não foi enviada ao AUDESP.',
    );
    expect(
      _de('sent', [
        _envio(1, statusProtocolo: 'Rejeitado'),
      ]).motivo('licitação', feminino: true),
      'O protocolo da licitação foi rejeitado pelo AUDESP. Corrija e reenvie.',
    );
  });
}
