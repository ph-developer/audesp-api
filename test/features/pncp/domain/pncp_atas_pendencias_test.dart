import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/pendencias/domain/pendencias_modulos.dart';
import 'package:audesp_api/features/pncp/domain/pncp_atas_pendencias.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pendencias/pendencias_fixtures.dart';
import '../../processo/processo_fixtures.dart';
import '../pncp_ata_fixtures.dart';
import '../pncp_fixtures.dart' show editalFixture;

const _compra = '49576416000141-1-000001/2026';
Processo _processo({
  bool srp = true,
  bool oculto = false,
  String status = 'sent',
  List<Licitacao>? licitacoes,
  EnviosProcesso? envios,
}) => processoFixture(
  codigo: _compra,
  srp: srp,
  oculto: oculto,
  status: status,
  semPncp: false,
  licitacoes: licitacoes ?? [licitacaoFixture(1, status: 'sent')],
  envios: envios,
);
List<PendenciaAtaPncp> _classificar({
  PncpAta? ata,
  List<Processo>? processos,
  List<Ata> atas = const [],
}) => PncpAtasPendencias.classificar(
  atasPncp: [ata ?? ataPncpFixture()],
  processos: processos ?? [_processo()],
  atas: atas,
);

void main() {
  test(
    'libera com edital SRP e licitação concluídos, independentemente do SRP no PNCP',
    () {
      final pendencia = _classificar(
        ata: ataPncpFixture(alteracoes: {'srp': false}),
      ).single;
      expect(pendencia.liberada, isTrue);
      expect(pendencia.edital?.codigoEdital, _compra);
    },
  );

  for (final status in ['draft', 'sent']) {
    test(
      'ata $status local casa por código com máscara e retira a pendência',
      () {
        expect(
          _classificar(
            atas: [
              ataFixture(
                9,
                status: status,
                codigo: '49576416000141-1-000001/2026-000001',
              ),
            ],
          ),
          isEmpty,
        );
      },
    );
  }

  test(
    'publicação do edital também corresponde mesmo com código local diferente',
    () {
      final edital = editalFixture(
        codigoEdital: 'LOCAL',
        documento: {
          'publicidade': {
            'publicacoes': [
              {'idContratacaoPNCP': _compra},
            ],
          },
        },
      );
      final pendencia = _classificar(
        processos: [
          Processo(edital: edital, licitacoes: [], atas: [], ajustes: []),
        ],
      ).single;
      expect(pendencia.edital, same(edital));
      expect(
        pendencia.motivoBloqueio,
        isNot(contains('ainda não está no sistema')),
      );
    },
  );

  test(
    'sem edital local, não SRP, edital em rascunho e licitação ausente bloqueiam',
    () {
      expect(
        _classificar(processos: []).single.motivoBloqueio,
        'O edital desta compra ainda não está no sistema.',
      );
      expect(
        _classificar(processos: [_processo(srp: false)]).single.motivoBloqueio,
        'Ata de registro de preços exige edital SRP.',
      );
      expect(
        _classificar(processos: [_processo(status: 'draft')]).single.liberada,
        isFalse,
      );
      expect(
        _classificar(
          processos: [_processo(licitacoes: [])],
        ).single.motivoBloqueio,
        'O edital ainda não tem licitação.',
      );
    },
  );

  for (final dispensada in [false, true]) {
    test('edital oculto nunca aparece, inclusive dispensa $dispensada', () {
      expect(
        _classificar(
          ata: ataPncpFixture(dispensada: dispensada),
          processos: [_processo(), _processo(oculto: true)],
        ),
        isEmpty,
      );
    });
  }

  test('cancelada não gera pendência, mas dispensa continua restaurável', () {
    expect(
      _classificar(ata: ataPncpFixture(alteracoes: {'cancelado': true})),
      isEmpty,
    );
    final pendencia = _classificar(
      ata: ataPncpFixture(dispensada: true, alteracoes: {'cancelado': true}),
    ).single;
    expect(pendencia.liberada, isFalse);
    expect(pendencia.motivoBloqueio, 'A ata foi cancelada no PNCP.');
    expect(pendencia.ata.dispensada, isTrue);
  });

  test(
    'conclusão depende do ambiente, conserva armazenamento anterior à retificação',
    () {
      final processo = _processo();
      final edital = processo.edital;
      final licitacao = processo.licitacoes.single;
      List<PendenciaAtaPncp> avaliar({
        required String ambiente,
        bool armazenado = false,
      }) => _classificar(
        processos: [
          _processo(
            envios: EnviosProcesso(
              baseUrl: ambiente,
              editais: EnviosIndex([
                envioFixture(edital, situacao: 'Armazenado'),
              ]),
              licitacoes: EnviosIndex([
                envioFixture(licitacao),
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
        avaliar(ambiente: ambientePendencias, armazenado: true).single.liberada,
        isTrue,
      );
      expect(
        avaliar(
          ambiente: 'https://audesp.tce.sp.gov.br',
          armazenado: true,
        ).single.liberada,
        isFalse,
      );
    },
  );

  test(
    'somente liberadas e protocolos contam; mantém bloqueadas/dispensas e respeita permissão',
    () {
      final processo = _processo();
      final local = ataFixture(9, status: 'sent');
      final docs = DocumentosProcesso(
        editais: [processo.edital],
        licitacoes: processo.licitacoes,
        atas: [local],
      );
      final envios = EnviosProcesso(
        atas: EnviosIndex([envioFixture(local)]),
        baseUrl: ambientePendencias,
      );
      final liberada = ataPncpFixture();
      final bloqueada = ataPncpFixture(
        id: 2,
        alteracoes: ataPncpJson(sequencialCompra: 2),
      );
      final dispensada = ataPncpFixture(
        id: 3,
        dispensada: true,
        alteracoes: ataPncpJson(sequencialAta: 3),
      );
      final cancelada = ataPncpFixture(
        id: 4,
        dispensada: true,
        alteracoes: {...ataPncpJson(sequencialAta: 4), 'cancelado': true},
      );
      PendenciasModulos para(int permissao) => PendenciasRules.paraUsuario(
        user: usuarioFixture(permissions: permissao),
        documentos: docs,
        envios: envios,
        atasPncp: [bloqueada, dispensada, liberada, cancelada],
      );
      final resultado = para(AppPermissions.ata);
      expect(resultado.contagens['/ata'], 2);
      expect(resultado.atasPncp.single.ata, same(liberada));
      expect(resultado.atasBloqueadas.single.ata, same(bloqueada));
      expect(resultado.atasDispensadas.map((p) => p.ata), [
        dispensada,
        cancelada,
      ]);
      final semPermissao = para(AppPermissions.ajuste);
      expect(semPermissao.contagens['/ata'], 0);
      expect(semPermissao.atasPncp, isEmpty);
      expect(semPermissao.atasBloqueadas, isEmpty);
      expect(semPermissao.atasDispensadas, isEmpty);
    },
  );

  group('editais publicados antes de 02/02/2026', () {
    for (final dispensada in [false, true]) {
      test('ata de compra de 2025 nunca aparece (dispensada: $dispensada)', () {
        expect(
          _classificar(
            ata: ataPncpSalva(
              PncpAta.fromApi(ataPncpJson(anoCompra: 2025)),
              dispensada: dispensada,
            ),
          ),
          isEmpty,
        );
      });
    }

    test('usa a publicação da compra conhecida', () {
      expect(
        PncpAtasPendencias.classificar(
          atasPncp: [ataPncpFixture()],
          processos: [_processo()],
          atas: const [],
          compras: [
            PncpCompra(
              id: 1,
              cnpj: '49576416000141',
              ano: 2026,
              sequencial: 1,
              numeroControle: '4957641600014110000012026',
              dataPublicacao: DateTime(2026, 1, 20),
              dadosJson: '{}',
            ),
          ],
        ),
        isEmpty,
      );
    });
  });
}
