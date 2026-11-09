import '../../../core/database/models/pncp_ata.dart';

/// Uma página dos dois endpoints de listagem de atas.
class PaginaAtasPncp {
  final List<Map<String, dynamic>> dados;
  final int totalPaginas;

  const PaginaAtasPncp({this.dados = const [], this.totalPaginas = 1});
}

typedef ConsultarAtasCompraPncp =
    Future<PaginaAtasPncp> Function(
      String cnpj,
      int ano,
      int sequencial,
      int pagina,
    );
typedef ConsultarAtasAtualizadasPncp =
    Future<PaginaAtasPncp> Function(
      String cnpj,
      DateTime inicio,
      DateTime fim,
      int pagina,
    );
typedef ProgressoPaginaAta = ({int sequencialCompra, int pagina});

/// As atas não têm sequência independente: a varredura acompanha as compras
/// já descobertas. A consulta por data revisita compras antigas e cancelamentos.
abstract final class PncpAtasVarredura {
  static const maxConsultasPorExecucao = 50;

  static Future<({int consultas, int novas})> executar({
    required String cnpj,
    required int anoAtual,
    required Map<int, int> ultimaSequenciaCompra,
    required Map<int, int> ultimaCompraConsultada,
    required ConsultarAtasCompraPncp consultar,
    required Future<bool> Function(PncpAta ata) salvar,
    required Future<void> Function(int ano, int sequencial) registrarSequencia,
    required Future<void> Function(int ano, ProgressoPaginaAta progresso)
    registrarPagina,
    Map<int, ProgressoPaginaAta> paginas = const {},
    int maxConsultas = maxConsultasPorExecucao,
  }) async {
    var consultas = 0;
    var novas = 0;
    for (final ano in [
      if (ultimaSequenciaCompra.containsKey(anoAtual - 1)) anoAtual - 1,
      anoAtual,
    ]) {
      final limite = ultimaSequenciaCompra[ano] ?? 0;
      var sequencia = (ultimaCompraConsultada[ano] ?? 0) + 1;
      while (sequencia <= limite && consultas < maxConsultas) {
        final progresso = paginas[ano];
        var pagina = progresso?.sequencialCompra == sequencia
            ? progresso!.pagina
            : 1;
        while (consultas < maxConsultas) {
          consultas++;
          final resposta = await consultar(cnpj, ano, sequencia, pagina);
          for (final dados in resposta.dados) {
            if (await salvar(
              PncpAta.fromApi(
                dados,
                cnpj: cnpj,
                anoCompra: ano,
                sequencialCompra: sequencia,
              ),
            )) {
              novas++;
            }
          }
          if (pagina >= resposta.totalPaginas) {
            // 204/404/410 também concluem esta compra, sem parar a varredura.
            await registrarSequencia(ano, sequencia);
            sequencia++;
            break;
          }
          pagina++;
          // Permite continuar mesmo uma compra com mais de 50 páginas.
          // O número da compra evita aplicar a página à compra seguinte se
          // houver interrupção entre a gravação do cursor e a próxima leitura.
          await registrarPagina(ano, (
            sequencialCompra: sequencia,
            pagina: pagina,
          ));
        }
      }
    }
    return (consultas: consultas, novas: novas);
  }

  /// Janela inclusiva de até 365 dias, com um dia de sobreposição.
  static ({DateTime inicio, DateTime fim}) janela({
    required DateTime hoje,
    DateTime? atualizadasAte,
  }) {
    final dia = DateTime(hoje.year, hoje.month, hoje.day);
    var inicio = atualizadasAte == null
        ? DateTime(dia.year)
        : DateTime(
            atualizadasAte.year,
            atualizadasAte.month,
            atualizadasAte.day - 1,
          );
    if (inicio.isAfter(dia)) inicio = dia;
    final limite = DateTime(dia.year, dia.month, dia.day - 364);
    if (inicio.isBefore(limite)) inicio = limite;
    return (inicio: inicio, fim: dia);
  }

  static Future<int> atualizar({
    required String cnpj,
    required DateTime hoje,
    DateTime? atualizadasAte,
    required ConsultarAtasAtualizadasPncp consultar,
    required Future<bool> Function(PncpAta ata) salvar,
    required Future<void> Function(DateTime data) registrarData,
  }) async {
    final periodo = janela(hoje: hoje, atualizadasAte: atualizadasAte);
    var novas = 0;
    var pagina = 1;
    while (true) {
      final resposta = await consultar(
        cnpj,
        periodo.inicio,
        periodo.fim,
        pagina,
      );
      for (final dados in resposta.dados) {
        if (await salvar(PncpAta.fromApi(dados, cnpj: cnpj))) novas++;
      }
      if (pagina >= resposta.totalPaginas) break;
      pagina++;
    }
    // Só depois de ler e persistir todas as páginas, inclusive uma janela vazia.
    await registrarData(periodo.fim);
    return novas;
  }
}
