import '../../../core/database/app_database.dart';

/// Documentos vinculados a um edital.
class Processo {
  final Edital edital;
  final List<Licitacao> licitacoes;
  final List<Ata> atas;
  final List<Ajuste> ajustes;

  Processo({
    required this.edital,
    required List<Licitacao> licitacoes,
    required List<Ata> atas,
    required List<Ajuste> ajustes,
  }) : licitacoes = List.unmodifiable(licitacoes),
       atas = List.unmodifiable(atas),
       ajustes = List.unmodifiable(ajustes);

  /// Preserva a ordem dos editais e dos documentos em cada vínculo.
  static List<Processo> agrupar({
    required Iterable<Edital> editais,
    required Iterable<Licitacao> licitacoes,
    required Iterable<Ata> atas,
    required Iterable<Ajuste> ajustes,
  }) {
    final licitacoesPorEdital = <int, List<Licitacao>>{};
    final atasPorEdital = <int, List<Ata>>{};
    final ajustesPorEdital = <int, List<Ajuste>>{};

    for (final licitacao in licitacoes) {
      (licitacoesPorEdital[licitacao.editalId] ??= []).add(licitacao);
    }
    for (final ata in atas) {
      (atasPorEdital[ata.editalId] ??= []).add(ata);
    }
    for (final ajuste in ajustes) {
      final editalId = ajuste.editalId;
      if (editalId != null) {
        (ajustesPorEdital[editalId] ??= []).add(ajuste);
      }
    }

    return [
      for (final edital in editais)
        Processo(
          edital: edital,
          licitacoes: licitacoesPorEdital[edital.id] ?? [],
          atas: atasPorEdital[edital.id] ?? [],
          ajustes: ajustesPorEdital[edital.id] ?? [],
        ),
    ];
  }
}
