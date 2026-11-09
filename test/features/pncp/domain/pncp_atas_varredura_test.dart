import 'package:audesp_api/core/database/models/pncp_ata.dart';
import 'package:audesp_api/features/pncp/domain/pncp_atas_varredura.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pncp_ata_fixtures.dart';

void main() {
  const cnpj = '49576416000141';

  test(
    'anda por todas as compras vazias até o cursor das compras, sem usar SRP',
    () async {
      final chamadas = <(int, int, int)>[];
      final salvas = <PncpAta>[];
      final cursores = <int, int>{};
      final resultado = await PncpAtasVarredura.executar(
        cnpj: cnpj,
        anoAtual: 2026,
        ultimaSequenciaCompra: {2026: 6},
        ultimaCompraConsultada: {},
        consultar: (_, ano, seq, pagina) async {
          chamadas.add((ano, seq, pagina));
          return seq == 5
              ? PaginaAtasPncp(dados: [ataPncpJson(sequencialCompra: seq)])
              : const PaginaAtasPncp();
        },
        salvar: (ata) async {
          salvas.add(ata);
          return true;
        },
        registrarSequencia: (ano, seq) async => cursores[ano] = seq,
        registrarPagina: (_, _) async {},
      );
      expect(chamadas, [for (var i = 1; i <= 6; i++) (2026, i, 1)]);
      expect(salvas.single.sequencialCompra, 5);
      expect(cursores, {2026: 6});
      expect(resultado, (consultas: 6, novas: 1));
    },
  );

  test(
    'sem cursor de compras não consulta; ignora anos que não foram consultados',
    () async {
      final chamadas = <int>[];
      await PncpAtasVarredura.executar(
        cnpj: cnpj,
        anoAtual: 2026,
        ultimaSequenciaCompra: {2024: 10},
        ultimaCompraConsultada: {2025: 8},
        consultar: (_, ano, _, _) async {
          chamadas.add(ano);
          return const PaginaAtasPncp();
        },
        salvar: (_) async => true,
        registrarSequencia: (_, _) async {},
        registrarPagina: (_, _) async {},
      );
      expect(chamadas, isEmpty);
    },
  );

  test(
    'limite de 50 próprio, ano anterior conhecido antes do atual e continuação',
    () async {
      final cursor = <int, int>{2025: 4};
      final chamadas = <(int, int)>[];
      Future<({int consultas, int novas})> executar() =>
          PncpAtasVarredura.executar(
            cnpj: cnpj,
            anoAtual: 2026,
            ultimaSequenciaCompra: {2025: 8, 2026: 60},
            ultimaCompraConsultada: cursor,
            consultar: (_, ano, seq, _) async {
              chamadas.add((ano, seq));
              return const PaginaAtasPncp();
            },
            salvar: (_) async => true,
            registrarSequencia: (ano, seq) async => cursor[ano] = seq,
            registrarPagina: (_, _) async {},
          );
      expect((await executar()).consultas, 50);
      expect(chamadas.first, (2025, 5));
      expect(cursor, {2025: 8, 2026: 46});
      chamadas.clear();
      expect((await executar()).consultas, 14);
      expect(chamadas.first, (2026, 47));
      expect(cursor[2026], 60);
    },
  );

  test(
    'paginação consome orçamento e retoma sem pular compra incompleta',
    () async {
      final cursor = <int, int>{};
      final paginas = <int, ProgressoPaginaAta>{};
      final chamadas = <(int, int)>[];
      final usadas = <String>{};
      Future<({int consultas, int novas})> executar() =>
          PncpAtasVarredura.executar(
            cnpj: cnpj,
            anoAtual: 2026,
            ultimaSequenciaCompra: {2026: 2},
            ultimaCompraConsultada: cursor,
            paginas: paginas,
            maxConsultas: 2,
            consultar: (_, ano, seq, pagina) async {
              chamadas.add((seq, pagina));
              return PaginaAtasPncp(
                totalPaginas: seq == 1 ? 3 : 1,
                dados: [
                  ataPncpJson(sequencialCompra: seq, sequencialAta: pagina),
                ],
              );
            },
            salvar: (ata) async => usadas.add(ata.numeroControle),
            registrarSequencia: (ano, seq) async => cursor[ano] = seq,
            registrarPagina: (ano, progresso) async => paginas[ano] = progresso,
          );
      expect(await executar(), (consultas: 2, novas: 2));
      expect(cursor, isEmpty);
      expect(paginas[2026], (sequencialCompra: 1, pagina: 3));
      expect(await executar(), (consultas: 2, novas: 2));
      expect(chamadas, [(1, 1), (1, 2), (1, 3), (2, 1)]);
      expect(cursor[2026], 2);
    },
  );

  test(
    'falha ao consultar ou salvar conserva a última compra completa',
    () async {
      for (final falhaAoSalvar in [false, true]) {
        final cursor = <int, int>{};
        await expectLater(
          PncpAtasVarredura.executar(
            cnpj: cnpj,
            anoAtual: 2026,
            ultimaSequenciaCompra: {2026: 3},
            ultimaCompraConsultada: {},
            consultar: (_, ano, seq, _) async {
              if (seq == 2 && !falhaAoSalvar) throw Exception('Sem conexão');
              return PaginaAtasPncp(
                dados: [ataPncpJson(sequencialCompra: seq)],
              );
            },
            salvar: (ata) async {
              if (ata.sequencialCompra == 2) throw Exception('Falha no banco');
              return true;
            },
            registrarSequencia: (ano, seq) async => cursor[ano] = seq,
            registrarPagina: (_, _) async {},
          ),
          throwsException,
        );
        expect(cursor, {2026: 1});
      }
    },
  );

  test(
    'janelas: janeiro inicial, sobreposição, virada do ano e limite inclusivo de 365 dias',
    () {
      expect(PncpAtasVarredura.janela(hoje: DateTime(2026, 11, 9, 18)), (
        inicio: DateTime(2026),
        fim: DateTime(2026, 11, 9),
      ));
      expect(
        PncpAtasVarredura.janela(
          hoje: DateTime(2026, 11, 9),
          atualizadasAte: DateTime(2026, 11, 8),
        ),
        (inicio: DateTime(2026, 11, 7), fim: DateTime(2026, 11, 9)),
      );
      expect(
        PncpAtasVarredura.janela(
          hoje: DateTime(2027, 1, 2),
          atualizadasAte: DateTime(2026, 12, 31),
        ),
        (inicio: DateTime(2026, 12, 30), fim: DateTime(2027, 1, 2)),
      );
      expect(
        PncpAtasVarredura.janela(
          hoje: DateTime(2026, 11, 9),
          atualizadasAte: DateTime(2020),
        ),
        (inicio: DateTime(2025, 11, 10), fim: DateTime(2026, 11, 9)),
      );
    },
  );

  test(
    'consulta por data percorre todas as páginas, deduplica e só depois avança marcador',
    () async {
      final paginas = <int>[];
      final salvas = <String>{};
      DateTime? marcador;
      final novas = await PncpAtasVarredura.atualizar(
        cnpj: cnpj,
        hoje: DateTime(2026, 11, 9),
        consultar: (_, inicio, fim, pagina) async {
          expect(marcador, isNull);
          expect(inicio, DateTime(2026));
          paginas.add(pagina);
          return PaginaAtasPncp(
            totalPaginas: 3,
            dados: [
              ataPncpJson(
                atualizacao: true,
                sequencialAta: pagina == 3 ? 1 : pagina,
              ),
            ],
          );
        },
        salvar: (ata) async => salvas.add(ata.numeroControle),
        registrarData: (data) async => marcador = data,
      );
      expect(paginas, [1, 2, 3]);
      expect(novas, 2);
      expect(marcador, DateTime(2026, 11, 9));
    },
  );

  test(
    'falha em página ou persistência não avança data; dados anteriores ficam salvos',
    () async {
      for (final falhaAoSalvar in [false, true]) {
        DateTime? marcador;
        final salvas = <PncpAta>[];
        await expectLater(
          PncpAtasVarredura.atualizar(
            cnpj: cnpj,
            hoje: DateTime(2026, 11, 9),
            consultar: (_, _, _, pagina) async {
              if (pagina == 2 && !falhaAoSalvar) throw Exception('Sem conexão');
              return PaginaAtasPncp(
                totalPaginas: 2,
                dados: [ataPncpJson(atualizacao: true, sequencialAta: pagina)],
              );
            },
            salvar: (ata) async {
              if (ata.sequencialAta == 2) throw Exception('Falha no banco');
              salvas.add(ata);
              return true;
            },
            registrarData: (data) async => marcador = data,
          ),
          throwsException,
        );
        expect(marcador, isNull);
        expect(salvas, hasLength(1));
      }
    },
  );

  test('janela vazia também avança data', () async {
    DateTime? marcador;
    expect(
      await PncpAtasVarredura.atualizar(
        cnpj: cnpj,
        hoje: DateTime(2026, 11, 9),
        consultar: (_, _, _, _) async => const PaginaAtasPncp(),
        salvar: (_) async => true,
        registrarData: (data) async => marcador = data,
      ),
      0,
    );
    expect(marcador, DateTime(2026, 11, 9));
  });
}
