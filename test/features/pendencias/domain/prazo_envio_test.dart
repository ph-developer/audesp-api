import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/pendencias/domain/prazo_envio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pncp/pncp_ata_fixtures.dart';
import '../../pncp/pncp_fixtures.dart';
import '../../processo/processo_fixtures.dart';

PncpCompra _compra(DateTime? publicacao, {bool dispensada = false}) =>
    PncpCompra(
      id: 1,
      cnpj: '49576416000141',
      ano: 2026,
      sequencial: 1,
      numeroControle: '4957641600014110000012026',
      dataPublicacao: publicacao,
      dadosJson: '{}',
      dispensadaEm: dispensada ? DateTime(2026, 11, 10) : null,
    );

void main() {
  group('DiasUteis', () {
    final calendario = DiasUteis();

    test('Páscoa e Sexta-feira Santa', () {
      expect(DiasUteis.pascoa(2026), DateTime(2026, 4, 5));
      expect(DiasUteis.pascoa(2027), DateTime(2027, 3, 28));
      expect(calendario.util(DateTime(2026, 4, 3)), isFalse);
    });

    test('fins de semana e feriados nacionais e de SP', () {
      expect(calendario.util(DateTime(2026, 11, 14)), isFalse); // sábado
      expect(calendario.util(DateTime(2026, 11, 20)), isFalse);
      expect(calendario.util(DateTime(2026, 7, 9)), isFalse);
      expect(calendario.util(DateTime(2026, 11, 19)), isTrue);
    });

    test('Carnaval e Corpus Christi só quando configurados', () {
      expect(calendario.util(DateTime(2026, 2, 16)), isTrue);
      expect(calendario.util(DateTime(2026, 6, 4)), isTrue);
      final completo = DiasUteis(carnaval: true, corpusChristi: true);
      expect(completo.util(DateTime(2026, 2, 16)), isFalse);
      expect(completo.util(DateTime(2026, 2, 17)), isFalse);
      expect(completo.util(DateTime(2026, 6, 4)), isFalse);
    });

    test('feriados extras anuais e de uma data', () {
      final extras = DiasUteis(feriadosExtras: ['25/01', '23/11/2026']);
      expect(extras.util(DateTime(2027, 1, 25)), isFalse);
      expect(extras.util(DateTime(2026, 11, 23)), isFalse);
      expect(extras.util(DateTime(2027, 11, 23)), isTrue);
    });

    test('lerFeriado valida a data', () {
      expect(DiasUteis.lerFeriado('9/7'), (9, 7, null));
      expect(DiasUteis.lerFeriado('29/02'), (29, 2, null));
      expect(DiasUteis.lerFeriado('31/02'), isNull);
      expect(DiasUteis.lerFeriado('01/13/2026'), isNull);
      expect(DiasUteis.lerFeriado('2026-11-23'), isNull);
    });

    test('somar não conta o dia da base e pula feriados', () {
      // Terça 10/11: 11, 12, 13, 16, 17.
      expect(
        calendario.somar(DateTime(2026, 11, 10), 5),
        DateTime(2026, 11, 17),
      );
      // Base no sábado começa a contar na segunda.
      expect(
        calendario.somar(DateTime(2026, 11, 14), 1),
        DateTime(2026, 11, 16),
      );
      // 20/11 (sexta) é feriado.
      expect(
        calendario.somar(DateTime(2026, 11, 19), 1),
        DateTime(2026, 11, 23),
      );
    });
  });

  group('PrazoEnvioConfig.calcular', () {
    final config = PrazoEnvioConfig();

    test('edital publicado antes do corte usa o prazo da transição', () {
      final prazo = config.calcular(
        TipoPrazo.edital,
        publicacaoEdital: DateTime(2026, 10, 31, 15),
      )!;
      expect(prazo.limite, DateTime(2027, 2, 1));
      expect(prazo.transicao, isTrue);
      // Também para ata e ajuste da mesma compra.
      expect(
        config
            .calcular(
              TipoPrazo.ajuste,
              publicacaoEdital: DateTime(2026, 10, 1),
              assinatura: DateTime(2026, 12, 1),
            )!
            .limite,
        DateTime(2027, 2, 1),
      );
    });

    test('edital a partir do corte: dias úteis da publicação', () {
      final prazo = config.calcular(
        TipoPrazo.edital,
        publicacaoEdital: DateTime(2026, 11, 10, 9),
      )!;
      expect(prazo.limite, DateTime(2026, 11, 17));
      expect(prazo.transicao, isFalse);
      expect(prazo.explicacao, contains('5 dias úteis da publicação'));
    });

    test('ata conta da assinatura e, sem ela, da publicação', () {
      final publicacaoEdital = DateTime(2026, 11, 3);
      expect(
        config
            .calcular(
              TipoPrazo.ata,
              publicacaoEdital: publicacaoEdital,
              assinatura: DateTime(2026, 11, 10),
              publicacao: DateTime(2026, 11, 12),
            )!
            .limite,
        DateTime(2026, 12, 2),
      );
      final semAssinatura = config.calcular(
        TipoPrazo.ata,
        publicacaoEdital: publicacaoEdital,
        publicacao: DateTime(2026, 11, 10),
      )!;
      expect(semAssinatura.limite, DateTime(2026, 12, 2));
      expect(semAssinatura.explicacao, contains('publicação'));
    });

    test('ajuste: 22 dias úteis, atravessando Natal e Ano Novo', () {
      expect(
        config
            .calcular(
              TipoPrazo.ajuste,
              publicacaoEdital: DateTime(2026, 11, 3),
              assinatura: DateTime(2026, 12, 1),
            )!
            .limite,
        DateTime(2027, 1, 4),
      );
    });

    test('sem compra conhecida, o regime vem do próprio documento', () {
      expect(
        config
            .calcular(TipoPrazo.ata, assinatura: DateTime(2026, 10, 15))!
            .limite,
        DateTime(2027, 2, 1),
      );
      expect(
        config
            .calcular(TipoPrazo.ajuste, assinatura: DateTime(2026, 12, 1))!
            .limite,
        DateTime(2027, 1, 4),
      );
    });

    test('sem data, ou licitação, fica sem prazo', () {
      expect(config.calcular(TipoPrazo.edital), isNull);
      expect(config.calcular(TipoPrazo.ata), isNull);
      expect(
        config.calcular(TipoPrazo.ata, publicacaoEdital: DateTime(2026, 11, 3)),
        isNull,
      );
      expect(
        config.calcular(
          TipoPrazo.licitacao,
          publicacaoEdital: DateTime(2026, 11, 3),
        ),
        isNull,
      );
      // Antes do corte a licitação também tem o prazo da transição.
      expect(
        config
            .calcular(
              TipoPrazo.licitacao,
              publicacaoEdital: DateTime(2026, 10, 3),
            )!
            .limite,
        DateTime(2027, 2, 1),
      );
    });
  });

  group('PrazoEnvio.situacao', () {
    final prazo = PrazoEnvioConfig().calcular(
      TipoPrazo.edital,
      publicacaoEdital: DateTime(2026, 11, 10),
    )!;

    test('em dia, próximo, vence hoje e vencido', () {
      expect(prazo.diasRestantes(DateTime(2026, 11, 11)), 4);
      expect(prazo.situacao(DateTime(2026, 11, 11, 18)), SituacaoPrazo.emDia);
      expect(prazo.situacao(DateTime(2026, 11, 13)), SituacaoPrazo.proximo);
      expect(
        prazo.situacao(DateTime(2026, 11, 17, 23)),
        SituacaoPrazo.venceHoje,
      );
      expect(prazo.situacao(DateTime(2026, 11, 18)), SituacaoPrazo.vencido);
      expect(prazo.diasRestantes(DateTime(2026, 11, 18)), 0);
    });
  });

  group('configuração', () {
    test('valores padrão e leitura das settings', () {
      final padrao = PrazoEnvioConfig.fromSettings(const {});
      expect(padrao.corte, DateTime(2026, 11, 1));
      expect(padrao.prazoTransicao, DateTime(2027, 2, 1));
      expect(padrao.dias, PrazoEnvioConfig.diasPadrao);
      expect(padrao.diasAlerta, 2);

      final config = PrazoEnvioConfig.fromSettings({
        'prazo_corte': '2026-12-01',
        'prazo_dias_edital': '7',
        'prazo_dias_ata': '0',
        'prazo_dias_alerta': '3',
        'prazo_feriados': '25/01;inválido;23/11/2026',
        'prazo_carnaval': '1',
      });
      expect(config.corte, DateTime(2026, 12, 1));
      expect(config.dias[TipoPrazo.edital], 7);
      expect(config.dias[TipoPrazo.ata], 15);
      expect(config.diasAlerta, 3);
      expect(config.calendario.feriadosExtras, ['25/01', '23/11/2026']);
      expect(config.calendario.carnaval, isTrue);
      expect(config.calendario.corpusChristi, isFalse);

      final relido = PrazoEnvioConfig.fromSettings(config.toSettings());
      expect(relido.toSettings(), config.toSettings());
    });
  });

  group('PrazosEnvio', () {
    final compra = _compra(DateTime(2026, 11, 10));
    final prazos = PrazosEnvio(
      config: PrazoEnvioConfig(),
      compras: [compra],
      atas: [
        ataPncpFixture(alteracoes: {'dataAssinatura': '2026-11-10'}),
      ],
      contratos: [
        contratoPncpFixture(
          alteracoes: {
            'numeroControlePncpCompra': '49576416000141-1-000001/2026',
            'dataAssinatura': '2026-12-01',
          },
        ),
      ],
    );

    test('compra, ata e contrato do PNCP', () {
      expect(prazos.compra(compra)!.limite, DateTime(2026, 11, 17));
      expect(
        prazos.compra(_compra(DateTime(2026, 11, 10), dispensada: true)),
        isNull,
      );
      expect(prazos.compra(_compra(null)), isNull);
      final ata = ataPncpFixture(alteracoes: {'dataAssinatura': '2026-11-10'});
      expect(prazos.ataPncp(ata)!.limite, DateTime(2026, 12, 2));
      expect(
        prazos.ataPncp(
          ataPncpFixture(
            alteracoes: {'dataAssinatura': '2026-11-10', 'cancelado': true},
          ),
        ),
        isNull,
      );
    });

    test('documentos locais casam pelo código PNCP', () {
      final edital = editalFixture(
        codigoEdital: '49576416000141-1-000001/2026',
      );
      expect(prazos.edital(edital)!.limite, DateTime(2026, 11, 17));
      expect(prazos.edital(editalFixture(codigoEdital: 'LOCAL')), isNull);

      final ata = ataFixture(1, codigo: '49576416000141-1-000001/2026-000001');
      expect(prazos.ata(ata)!.limite, DateTime(2026, 12, 2));
      expect(prazos.ata(ataFixture(2)), isNull);

      final ajuste = ajusteFixture(1, codigo: '46395000000139-2-000002/2026');
      expect(prazos.ajuste(ajuste)!.limite, DateTime(2027, 1, 4));
    });

    test('ordenar é estável e deixa os sem prazo no fim', () {
      final limites = <String, DateTime?>{
        'a': null,
        'b': DateTime(2026, 12, 1),
        'c': DateTime(2026, 11, 20),
        'd': null,
        'e': DateTime(2026, 12, 1),
      };
      final config = PrazoEnvioConfig();
      final ordenados = PrazosEnvio.ordenar(
        limites.keys,
        (k) => limites[k] == null
            ? null
            : PrazoEnvio(
                limite: limites[k]!,
                explicacao: '',
                calendario: config.calendario,
                diasAlerta: 2,
              ),
      );
      expect(ordenados, ['c', 'b', 'e', 'a', 'd']);
    });
  });
}
