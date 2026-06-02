class Edital {
  final int id;
  final String municipio;
  final String entidade;
  final String codigoEdital;
  final bool retificacao;
  final String status;
  final String? pdfPath;
  final String documentoJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Edital({
    required this.id,
    required this.municipio,
    required this.entidade,
    required this.codigoEdital,
    required this.retificacao,
    required this.status,
    this.pdfPath,
    required this.documentoJson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Edital.fromMap(Map<String, dynamic> row) => Edital(
        id: row['id'] as int,
        municipio: row['municipio'] as String,
        entidade: row['entidade'] as String,
        codigoEdital: row['codigo_edital'] as String,
        retificacao: (row['retificacao'] as int) == 1,
        status: row['status'] as String,
        pdfPath: row['pdf_path'] as String?,
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
        'municipio': municipio,
        'entidade': entidade,
        'codigo_edital': codigoEdital,
        'retificacao': retificacao ? 1 : 0,
        'status': status,
        'pdf_path': pdfPath,
        'documento_json': documentoJson,
        'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
        'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
      };
}
