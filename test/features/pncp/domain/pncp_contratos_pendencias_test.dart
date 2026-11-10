import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/pendencias/domain/pendencias_modulos.dart';
import 'package:audesp_api/features/pncp/domain/pncp_contratos_pendencias.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pendencias/pendencias_fixtures.dart';
import '../../processo/processo_fixtures.dart';
import '../pncp_fixtures.dart';

const _cnpj = '46395000000139';
const _compra = '46395000000139-1-000352/2026';

Processo _processo({
  bool srp = false,
  bool oculto = false,
  String status = 'sent',
}) => processoFixture(
  codigo: _compra,
  srp: srp,
  oculto: oculto,
  status: status,
  semPncp: false,
  licitacoes: [licitacaoFixture(1, status: 'sent')],
);

List<PendenciaContratoPncp> _classificar({
  PncpContrato? contrato,
  List<Processo>? processos,
  List<Ajuste> ajustes = const [],
}) => PncpContratosPendencias.classificar(
  contratos: [contrato ?? contratoPncpFixture()],
  processos: processos ?? [_processo()],
  ajustes: ajustes,
  cnpj: _cnpj,
);

void main() {
  test('compra casa com edital e licitação concluídos', () {
    final p = _classificar().single;
    expect(p.liberado, isTrue);
    expect(p.edital?.id, 1);
    expect(p.adesaoParticipacao, isFalse);
  });

  for (final status in ['draft', 'sent']) {
    test('ajuste $status já lançado casa com contrato mascarado', () {
      expect(
        _classificar(
          ajustes: [
            ajusteFixture(
              5,
              status: status,
              codigo: '46395000000139-2-000002/2026',
            ),
          ],
        ),
        isEmpty,
      );
    });
  }

  test('publicação PNCP também casa quando código local é diferente', () {
    final edital = editalFixture(
      codigoEdital: 'CODIGO-LOCAL',
      documento: {
        'publicidade': {
          'publicacoes': [
            {'idContratacaoPNCP': _compra},
          ],
        },
      },
    );
    final p = _classificar(
      processos: [
        Processo(edital: edital, licitacoes: [], atas: [], ajustes: []),
      ],
    ).single;
    expect(p.edital, same(edital));
    expect(p.motivoBloqueio, contains('edital'));
    expect(p.motivoBloqueio, isNot(contains('ainda não está no sistema')));
  });

  for (final dispensado in [false, true]) {
    test(
      'ata, SRP e ocultos são ignorados, mesmo dispensados ($dispensado)',
      () {
        final contrato = contratoPncpFixture(dispensado: dispensado);
        expect(
          _classificar(contrato: contrato, processos: [_processo(srp: true)]),
          isEmpty,
        );
        expect(
          _classificar(
            contrato: contrato,
            processos: [_processo(oculto: true)],
          ),
          isEmpty,
        );
        expect(
          _classificar(
            contrato: contratoPncpFixture(
              dispensado: dispensado,
              alteracoes: {
                'numeroControlePncpAta': '46395000000139-1-000352/2026-000001',
                'frutoAdesao': true,
              },
            ),
            processos: [],
          ),
          isEmpty,
        );
      },
    );
  }

  test('oculto e SRP prevalecem sobre adesão', () {
    final contrato = contratoPncpFixture(alteracoes: {'frutoAdesao': true});
    expect(
      _classificar(contrato: contrato, processos: [_processo(oculto: true)]),
      isEmpty,
    );
    expect(
      _classificar(contrato: contrato, processos: [_processo(srp: true)]),
      isEmpty,
    );
  });

  test('fruto de adesão dispensa conclusão do edital e vínculo local', () {
    final contrato = contratoPncpFixture(alteracoes: {'frutoAdesao': true});
    final semLocal = _classificar(contrato: contrato, processos: []).single;
    expect(semLocal.liberado, isTrue);
    expect(semLocal.adesaoParticipacao, isTrue);
    expect(semLocal.edital, isNull);
    final comLocal = _classificar(
      contrato: contrato,
      processos: [_processo(status: 'draft')],
    ).single;
    expect(comLocal.liberado, isTrue);
    expect(comLocal.edital?.id, 1);
  });

  test('compra de outro CNPJ é adesão mesmo sem flag no PNCP', () {
    final p = _classificar(
      contrato: contratoPncpFixture(
        alteracoes: {
          'numeroControlePncpCompra': '49576416000141-1-000352/2026',
        },
      ),
      processos: [],
    ).single;
    expect(p.liberado, isTrue);
    expect(p.adesaoParticipacao, isTrue);
  });

  test('compra própria sem edital e ausência de compra bloqueiam', () {
    expect(
      _classificar(processos: []).single.motivoBloqueio,
      'O edital desta compra ainda não está no sistema.',
    );
    for (final adesao in [false, true]) {
      expect(
        _classificar(
          contrato: contratoPncpFixture(
            alteracoes: {
              'numeroControlePncpCompra': null,
              'frutoAdesao': adesao,
            },
          ),
        ).single.motivoBloqueio,
        'O contrato não informa a compra no PNCP.',
      );
    }
  });

  test('bloqueio usa o protocolo do ambiente e mantém conclusão anterior', () {
    final processo = _processo();
    final edital = processo.edital;
    final licitacao = processo.licitacoes.single;
    final envioEdital = envioFixture(edital, situacao: 'Armazenado');
    final recebido = envioFixture(licitacao, situacao: 'Recebido');
    List<PendenciaContratoPncp> avaliar({
      required String ambiente,
      bool armazenado = false,
    }) => _classificar(
      processos: [
        Processo(
          edital: edital,
          licitacoes: [licitacao],
          atas: [],
          ajustes: [],
          envios: EnviosProcesso(
            baseUrl: ambiente,
            editais: EnviosIndex([envioEdital]),
            licitacoes: EnviosIndex([
              recebido,
              if (armazenado)
                envioFixture(licitacao, id: 2, situacao: 'Armazenado'),
              if (armazenado)
                envioFixture(
                  licitacao,
                  id: 3,
                  situacao: 'Rejeitado',
                  retificacao: true,
                ),
            ]),
          ),
        ),
      ],
    );
    expect(
      avaliar(ambiente: ambientePendencias).single.motivoBloqueio,
      contains('Recebido'),
    );
    expect(
      avaliar(ambiente: ambientePendencias, armazenado: true).single.liberado,
      isTrue,
    );
    expect(
      avaliar(
        ambiente: 'https://audesp.tce.sp.gov.br',
        armazenado: true,
      ).single.liberado,
      isFalse,
    );
  });

  test(
    'só liberados e protocolos contam; dispensa permanece disponível na aba',
    () {
      final processo = _processo();
      final liberado = contratoPncpFixture();
      final bloqueado = contratoPncpFixture(
        id: 2,
        alteracoes: {
          'numeroControlePNCP': '46395000000139-2-000003/2026',
          'numeroControlePncpCompra': null,
        },
      );
      final dispensado = contratoPncpFixture(
        id: 3,
        dispensado: true,
        alteracoes: {'numeroControlePNCP': '46395000000139-2-000004/2026'},
      );
      final docs = DocumentosProcesso(
        editais: [processo.edital],
        licitacoes: processo.licitacoes,
      );
      PendenciasModulos para(int permissao) => PendenciasRules.paraUsuario(
        user: usuarioFixture(permissions: permissao),
        documentos: docs,
        envios: EnviosProcesso.vazio,
        contratos: [bloqueado, dispensado, liberado],
        cnpj: _cnpj,
      );
      final resultado = para(AppPermissions.ajuste);
      expect(resultado.contagens['/ajuste'], 1);
      expect(resultado.contratosAjuste.single.contrato, same(liberado));
      expect(resultado.contratosBloqueados.single.contrato, same(bloqueado));
      expect(resultado.contratosDispensados.single.contrato, same(dispensado));
      final semPermissao = para(AppPermissions.edital);
      expect(semPermissao.contagens['/ajuste'], 0);
      expect(semPermissao.contratosBloqueados, isEmpty);
      expect(semPermissao.contratosDispensados, isEmpty);
    },
  );

  group('editais publicados antes de 02/02/2026', () {
    for (final dispensado in [false, true]) {
      test('compra de 2025 nunca aparece (dispensado: $dispensado)', () {
        expect(
          _classificar(
            contrato: contratoPncpFixture(
              dispensado: dispensado,
              alteracoes: {'numeroControlePncpCompra': '$_cnpj-1-000352/2025'},
            ),
          ),
          isEmpty,
        );
      });
    }

    test('usa a publicação da compra conhecida', () {
      final compra = PncpCompra(
        id: 1,
        cnpj: _cnpj,
        ano: 2026,
        sequencial: 352,
        numeroControle: '4639500000013910003522026',
        dataPublicacao: DateTime(2026, 1, 15),
        dadosJson: '{}',
      );
      expect(
        PncpContratosPendencias.classificar(
          contratos: [contratoPncpFixture()],
          processos: [_processo()],
          ajustes: const [],
          cnpj: _cnpj,
          compras: [compra],
        ),
        isEmpty,
      );
    });

    test('contrato assinado antes do corte sem compra conhecida', () {
      expect(
        _classificar(
          contrato: contratoPncpFixture(
            alteracoes: {'dataAssinatura': '2026-01-09'},
          ),
        ),
        isEmpty,
      );
    });
  });
}
