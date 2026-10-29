import '../../../core/database/models/pncp_compra.dart';

/// Resposta do PNCP para uma sequência.
sealed class SequenciaPncp {
  const SequenciaPncp();
}

class CompraEncontrada extends SequenciaPncp {
  final Map<String, dynamic> dados;
  const CompraEncontrada(this.dados);
}

/// 404: a numeração ainda não chegou nesta sequência (ou é um buraco).
class SequenciaInexistente extends SequenciaPncp {
  const SequenciaInexistente();
}

/// 410: a compra existiu e foi excluída do PNCP.
class CompraExcluida extends SequenciaPncp {
  const CompraExcluida();
}

typedef ConsultarCompraPncp =
    Future<SequenciaPncp> Function(String cnpj, int ano, int sequencial);

/// Persiste a compra encontrada. Retorna true quando ela ainda não estava
/// registrada.
typedef SalvarCompraPncp = Future<bool> Function(PncpCompra compra);

/// Guarda a última sequência já ocupada (encontrada ou excluída) do ano.
typedef RegistrarSequenciaPncp = Future<void> Function(int ano, int sequencial);

/// Consulta o PNCP sequência a sequência a partir da última encontrada.
abstract final class PncpVarredura {
  /// A numeração pode ter buracos, então só para depois de algumas
  /// sequências seguidas sem compra.
  static const faltasParaParar = 3;

  /// Limita cada execução; a próxima continua de onde esta parou.
  static const maxConsultasPorExecucao = 50;

  /// [ultimaSequencia] traz a última sequência ocupada por ano. O ano
  /// anterior só é conferido se já tiver sido consultado, para terminar a
  /// numeração dele na virada do ano sem varrer anos que nunca foram usados.
  ///
  /// Compras excluídas (410) são puladas sem contar como falta, porque
  /// provam que a numeração continua. Qualquer outro erro do PNCP lança
  /// exceção e interrompe a varredura; o que já foi registrado fica salvo.
  static Future<({int consultas, int novas})> executar({
    required String cnpj,
    required int anoAtual,
    required Map<int, int> ultimaSequencia,
    required ConsultarCompraPncp consultar,
    required SalvarCompraPncp salvar,
    required RegistrarSequenciaPncp registrarSequencia,
    int maxConsultas = maxConsultasPorExecucao,
  }) async {
    var consultas = 0;
    var novas = 0;
    final anos = [
      if (ultimaSequencia.containsKey(anoAtual - 1)) anoAtual - 1,
      anoAtual,
    ];
    for (final ano in anos) {
      var sequencial = ultimaSequencia[ano] ?? 0;
      var faltas = 0;
      while (faltas < faltasParaParar && consultas < maxConsultas) {
        sequencial++;
        consultas++;
        switch (await consultar(cnpj, ano, sequencial)) {
          case SequenciaInexistente():
            faltas++;
            continue;
          case CompraExcluida():
            break;
          case CompraEncontrada(:final dados):
            if (await salvar(PncpCompra.fromApi(dados))) novas++;
        }
        faltas = 0;
        await registrarSequencia(ano, sequencial);
      }
    }
    return (consultas: consultas, novas: novas);
  }
}
