import 'package:audesp_api/core/database/models/pncp_compra.dart';
import 'package:audesp_api/features/pncp/domain/pncp_varredura.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pncp_fixtures.dart';

const _cnpj = '46395000000139';

/// PNCP falso: sequências com compra e excluídas (410) por ano.
class _PncpFalso {
  final Map<int, Set<int>> existentes;
  final Map<int, Set<int>> excluidas;
  final consultadas = <(int, int)>[];
  final salvas = <PncpCompra>[];
  final cache = <int, int>{};

  _PncpFalso(this.existentes, {this.excluidas = const {}});

  Future<({int consultas, int novas})> executar(
    Map<int, int> ultima, {
    int maxConsultas = PncpVarredura.maxConsultasPorExecucao,
  }) => PncpVarredura.executar(
    cnpj: _cnpj,
    anoAtual: 2026,
    ultimaSequencia: ultima,
    maxConsultas: maxConsultas,
    consultar: (cnpj, ano, seq) async {
      consultadas.add((ano, seq));
      if (excluidas[ano]?.contains(seq) == true) return const CompraExcluida();
      return existentes[ano]?.contains(seq) == true
          ? CompraEncontrada(
              compraPncpJson(sequencial: seq, ano: ano, cnpj: cnpj),
            )
          : const SequenciaInexistente();
    },
    salvar: (compra) async {
      salvas.add(compra);
      return compra.sequencial != 2;
    },
    registrarSequencia: (ano, seq) async => cache[ano] = seq,
  );
}

void main() {
  test('tolera buracos e para após 3 sequências seguidas sem compra', () async {
    final pncp = _PncpFalso({
      2026: {1, 2, 4, 5},
    });
    final r = await pncp.executar({});
    expect(pncp.salvas.map((c) => c.sequencial), [1, 2, 4, 5]);
    expect(pncp.consultadas.map((c) => c.$2), [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(pncp.cache, {2026: 5});
    expect(r, (consultas: 8, novas: 3));
  });

  test('compra excluída (410) é pulada sem contar como falta', () async {
    final pncp = _PncpFalso(
      {
        2026: {26, 30},
      },
      excluidas: {
        2026: {27, 28, 29},
      },
    );
    await pncp.executar({2026: 25});
    expect(pncp.salvas.map((c) => c.sequencial), [26, 30]);
    expect(pncp.consultadas.map((c) => c.$2), [26, 27, 28, 29, 30, 31, 32, 33]);
    expect(pncp.cache, {2026: 30});
  });

  test('excluída no fim avança a sequência para não reconsultar', () async {
    final pncp = _PncpFalso(
      {
        2026: {26},
      },
      excluidas: {
        2026: {27},
      },
    );
    await pncp.executar({2026: 25});
    expect(pncp.cache, {2026: 27});
  });

  test('continua da última sequência registrada', () async {
    final pncp = _PncpFalso({
      2026: {11},
    });
    await pncp.executar({2026: 10});
    expect(pncp.consultadas.first, (2026, 11));
    expect(pncp.cache, {2026: 11});
  });

  test('respeita o limite de consultas por execução', () async {
    final pncp = _PncpFalso({
      2026: {for (var i = 1; i <= 100; i++) i},
    });
    final r = await pncp.executar({}, maxConsultas: 10);
    expect(r.consultas, 10);
    expect(pncp.cache, {2026: 10});
  });

  test('só confere o ano anterior quando ele já foi consultado', () async {
    final semAnterior = _PncpFalso({});
    await semAnterior.executar({});
    expect(semAnterior.consultadas.every((c) => c.$1 == 2026), isTrue);

    final comAnterior = _PncpFalso({
      2025: {41},
    });
    await comAnterior.executar({2025: 40});
    expect(comAnterior.consultadas.first, (2025, 41));
    expect(comAnterior.consultadas.last.$1, 2026);
    expect(comAnterior.cache, {2025: 41});
  });

  test('erro do PNCP interrompe a varredura e mantém o progresso', () async {
    final cache = <int, int>{};
    await expectLater(
      PncpVarredura.executar(
        cnpj: _cnpj,
        anoAtual: 2026,
        ultimaSequencia: const {},
        consultar: (cnpj, ano, seq) async => seq < 3
            ? CompraEncontrada(compraPncpJson(sequencial: seq))
            : throw Exception('fora do ar'),
        salvar: (_) async => true,
        registrarSequencia: (ano, seq) async => cache[ano] = seq,
      ),
      throwsException,
    );
    expect(cache, {2026: 2});
  });
}
