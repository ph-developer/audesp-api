import 'package:audesp_api/core/database/models/pncp_contrato.dart';
import 'package:audesp_api/features/pncp/domain/pncp_varredura.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pncp_fixtures.dart';

void main() {
  test(
    'contratos toleram buracos, avançam sobre 410 e param após três 404',
    () async {
      final chamadas = <int>[];
      final salvos = <PncpContrato>[];
      final cursores = <int, int>{};
      final resultado = await PncpVarredura.executarContratos(
        cnpj: '46395000000139',
        anoAtual: 2026,
        ultimaSequencia: {2026: 2},
        consultar: (cnpj, ano, seq) async {
          chamadas.add(seq);
          if (seq == 3 || seq == 7) return const ContratoExcluido();
          if (seq == 5) {
            return ContratoEncontrado(contratoPncpJson(sequencial: seq));
          }
          return const SequenciaInexistente();
        },
        salvar: (contrato) async {
          salvos.add(contrato);
          return true;
        },
        registrarSequencia: (ano, seq) async => cursores[ano] = seq,
      );
      expect(chamadas, [3, 4, 5, 6, 7, 8, 9, 10]);
      expect(salvos.single.sequencial, 5);
      expect(cursores, {2026: 7});
      expect(resultado, (novas: 1, consultas: 8));
    },
  );

  test('limite próprio de 50 e ano anterior somente com cursor', () async {
    for (final ultima in [
      <int, int>{},
      {2025: 10},
    ]) {
      final chamadas = <(int, int)>[];
      final r = await PncpVarredura.executarContratos(
        cnpj: '46395000000139',
        anoAtual: 2026,
        ultimaSequencia: ultima,
        consultar: (cnpj, ano, seq) async {
          chamadas.add((ano, seq));
          return ContratoEncontrado(
            contratoPncpJson(ano: ano, sequencial: seq),
          );
        },
        salvar: (contrato) async => contrato.sequencial != 2,
        registrarSequencia: (ano, seq) async {},
      );
      expect(r.consultas, 50);
      expect(chamadas.first, ultima.isEmpty ? (2026, 1) : (2025, 11));
      expect(r.novas, ultima.isEmpty ? 49 : 50);
    }
  });

  test(
    'ano anterior termina antes de iniciar o atual e erro mantém cursor',
    () async {
      final cursores = <int, int>{};
      final chamadas = <(int, int)>[];
      await expectLater(
        PncpVarredura.executarContratos(
          cnpj: '46395000000139',
          anoAtual: 2026,
          ultimaSequencia: {2025: 10},
          consultar: (cnpj, ano, seq) async {
            chamadas.add((ano, seq));
            if (ano == 2025) return const SequenciaInexistente();
            if (seq == 3) throw Exception('indisponível');
            return ContratoEncontrado(contratoPncpJson(sequencial: seq));
          },
          salvar: (_) async => true,
          registrarSequencia: (ano, seq) async => cursores[ano] = seq,
        ),
        throwsException,
      );
      expect(chamadas.take(4), [(2025, 11), (2025, 12), (2025, 13), (2026, 1)]);
      expect(cursores, {2026: 2});
    },
  );
}
