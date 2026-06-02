class Ata {
  final int id;
  final int editalId;
  final String municipio;
  final String entidade;
  final String codigoEdital;
  final String codigoAta;
  final bool retificacao;
  final String status;
  final String documentoJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ata({
    required this.id,
    required this.editalId,
    required this.municipio,
    required this.entidade,
    required this.codigoEdital,
    required this.codigoAta,
    required this.retificacao,
    required this.status,
    required this.documentoJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ata.fromMap(Map<String, dynamic> row) => Ata(
        id: row['id'] as int,
        editalId: row['edital_id'] as int,
        municipio: row['municipio'] as String,
        entidade: row['entidade'] as String,
        codigoEdital: row['codigo_edital'] as String,
        codigoAta: row['codigo_ata'] as String,
        retificacao: (row['retificacao'] as int) == 1,
        status: row['status'] as String,
        documentoJson: row['documento_json'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (row['created_at'] as int) * 1000,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int) * 1000,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'edital_id': editalId,
        'municipio': municipio,
        'entidade': entidade,
        'codigo_edital': codigoEdital,
        'codigo_ata': codigoAta,
        'retificacao': retificacao ? 1 : 0,
        'status': status,
        'documento_json': documentoJson,
        'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
        'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
      };
}
