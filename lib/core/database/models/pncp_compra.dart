import 'dart:convert';

/// Compra (contratação) publicada no PNCP pelo CNPJ configurado.
class PncpCompra {
  final int id;
  final String cnpj;
  final int ano;
  final int sequencial;

  /// `numeroControlePNCP` só com dígitos (25), igual ao código do edital.
  final String numeroControle;
  final int? modalidadeId;
  final String numeroCompra;
  final String objeto;
  final double? valorTotalEstimado;
  final DateTime? dataPublicacao;

  /// Resposta bruta da API de consulta do PNCP.
  final String dadosJson;
  final DateTime? dispensadaEm;
  final int? dispensadaPor;
  final String? motivoDispensa;

  const PncpCompra({
    required this.id,
    required this.cnpj,
    required this.ano,
    required this.sequencial,
    required this.numeroControle,
    this.modalidadeId,
    this.numeroCompra = '',
    this.objeto = '',
    this.valorTotalEstimado,
    this.dataPublicacao,
    required this.dadosJson,
    this.dispensadaEm,
    this.dispensadaPor,
    this.motivoDispensa,
  });

  bool get dispensada => dispensadaEm != null;

  Map<String, dynamic> get dados {
    try {
      return jsonDecode(dadosJson) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// Monta a compra a partir da resposta de
  /// `/v1/orgaos/{cnpj}/compras/{ano}/{sequencial}`, ainda sem id local.
  factory PncpCompra.fromApi(Map<String, dynamic> json) {
    // O número de controle começa pelo CNPJ: 46395000000139-1-000001/2026.
    final controle = (json['numeroControlePNCP']?.toString() ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    return PncpCompra(
      id: 0,
      cnpj: controle.length >= 14 ? controle.substring(0, 14) : '',
      ano: (json['anoCompra'] as num?)?.toInt() ?? 0,
      sequencial: (json['sequencialCompra'] as num?)?.toInt() ?? 0,
      numeroControle: controle,
      modalidadeId: (json['modalidadeId'] as num?)?.toInt(),
      numeroCompra: json['numeroCompra']?.toString().trim() ?? '',
      objeto: json['objetoCompra']?.toString().trim() ?? '',
      valorTotalEstimado: (json['valorTotalEstimado'] as num?)?.toDouble(),
      dataPublicacao: DateTime.tryParse(
        json['dataPublicacaoPncp']?.toString() ?? '',
      ),
      dadosJson: jsonEncode(json),
    );
  }

  factory PncpCompra.fromMap(Map<String, dynamic> row) => PncpCompra(
    id: row['id'] as int,
    cnpj: row['cnpj'] as String,
    ano: row['ano'] as int,
    sequencial: row['sequencial'] as int,
    numeroControle: row['numero_controle'] as String,
    modalidadeId: row['modalidade_id'] as int?,
    numeroCompra: row['numero_compra'] as String? ?? '',
    objeto: row['objeto'] as String? ?? '',
    valorTotalEstimado: double.tryParse(
      row['valor_total_estimado']?.toString() ?? '',
    ),
    dataPublicacao: _data(row['data_publicacao']),
    dadosJson: row['dados_json'] as String,
    dispensadaEm: _data(row['dispensada_em']),
    dispensadaPor: row['dispensada_por'] as int?,
    motivoDispensa: row['motivo_dispensa'] as String?,
  );

  static DateTime? _data(Object? epoch) =>
      epoch is int ? DateTime.fromMillisecondsSinceEpoch(epoch * 1000) : null;
}
