import 'dart:convert';

/// Ata do PNCP; sua sequência pertence à compra, não à numeração do órgão.
class PncpAta {
  final int id;
  final String cnpj;
  final int anoCompra;
  final int sequencialCompra;
  final int sequencialAta;
  final String numeroControle;
  final String numeroControleCompra;
  final String numeroAta;
  final int? anoAta;
  final bool cancelada;
  final DateTime? dataCancelamento;
  final DateTime? dataAssinatura;
  final DateTime? vigenciaInicio;
  final DateTime? vigenciaFim;
  final DateTime? dataPublicacao;
  final String objeto;
  final String dadosJson;
  final DateTime? dispensadaEm;
  final int? dispensadaPor;
  final String? motivoDispensa;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PncpAta({
    required this.id,
    required this.cnpj,
    required this.anoCompra,
    required this.sequencialCompra,
    required this.sequencialAta,
    required this.numeroControle,
    required this.numeroControleCompra,
    this.numeroAta = '',
    this.anoAta,
    this.cancelada = false,
    this.dataCancelamento,
    this.dataAssinatura,
    this.vigenciaInicio,
    this.vigenciaFim,
    this.dataPublicacao,
    this.objeto = '',
    required this.dadosJson,
    this.dispensadaEm,
    this.dispensadaPor,
    this.motivoDispensa,
    this.createdAt,
    this.updatedAt,
  });

  bool get dispensada => dispensadaEm != null;

  Map<String, dynamic> get dados {
    try {
      return jsonDecode(dadosJson) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// Aceita a lista/detalhe de uma compra e a consulta por atualização.
  /// A lista não traz a compra: os primeiros 25 dígitos a identificam.
  /// Quando informada, a URL também é conferida antes de persistir a ata.
  factory PncpAta.fromApi(
    Map<String, dynamic> json, {
    String? cnpj,
    int? anoCompra,
    int? sequencialCompra,
  }) {
    final controle = _digitos(
      json['numeroControlePNCPAta'] ?? json['numeroControlePNCP'],
    );
    if (controle.length != 31) {
      throw const FormatException('O PNCP retornou uma ata sem código válido.');
    }
    final compra = controle.substring(0, 25);
    final compraInformada = _digitos(
      json['numeroControlePNCPCompra'] ?? json['numeroControlePncpCompra'],
    );
    final cnpjCompra = compra.substring(0, 14);
    final ano = int.parse(compra.substring(21, 25));
    final sequencia = int.parse(compra.substring(15, 21));
    if ((compraInformada.isNotEmpty && compraInformada != compra) ||
        (cnpj != null && _digitos(cnpj) != cnpjCompra) ||
        (anoCompra != null && anoCompra != ano) ||
        (sequencialCompra != null && sequencialCompra != sequencia)) {
      throw const FormatException(
        'A ata do PNCP não corresponde à compra consultada.',
      );
    }
    return PncpAta(
      id: 0,
      cnpj: cnpjCompra,
      anoCompra: ano,
      sequencialCompra: sequencia,
      sequencialAta: int.parse(controle.substring(25)),
      numeroControle: controle,
      numeroControleCompra: compra,
      numeroAta: json['numeroAtaRegistroPreco']?.toString().trim() ?? '',
      anoAta: (json['anoAta'] as num?)?.toInt(),
      cancelada: json['cancelado'] == true,
      dataCancelamento: _dataApi(json['dataCancelamento']),
      dataAssinatura: _dataApi(json['dataAssinatura']),
      vigenciaInicio: _dataApi(
        json['dataVigenciaInicio'] ?? json['vigenciaInicio'],
      ),
      vigenciaFim: _dataApi(json['dataVigenciaFim'] ?? json['vigenciaFim']),
      dataPublicacao: _dataApi(json['dataPublicacaoPncp']),
      objeto:
          (json['objetoCompra'] ?? json['objetoContratacao'])
              ?.toString()
              .trim() ??
          '',
      dadosJson: jsonEncode(json),
    );
  }

  factory PncpAta.fromMap(Map<String, dynamic> row) => PncpAta(
    id: row['id'] as int,
    cnpj: row['cnpj'] as String,
    anoCompra: row['ano_compra'] as int,
    sequencialCompra: row['sequencial_compra'] as int,
    sequencialAta: row['sequencial_ata'] as int,
    numeroControle: row['numero_controle'] as String,
    numeroControleCompra: row['numero_controle_compra'] as String,
    numeroAta: row['numero_ata'] as String? ?? '',
    anoAta: row['ano_ata'] as int?,
    cancelada: row['cancelada'] == 1,
    dataCancelamento: _data(row['data_cancelamento']),
    dataAssinatura: _data(row['data_assinatura']),
    vigenciaInicio: _data(row['vigencia_inicio']),
    vigenciaFim: _data(row['vigencia_fim']),
    dataPublicacao: _data(row['data_publicacao']),
    objeto: row['objeto'] as String? ?? '',
    dadosJson: row['dados_json'] as String,
    dispensadaEm: _data(row['dispensada_em']),
    dispensadaPor: row['dispensada_por'] as int?,
    motivoDispensa: row['motivo_dispensa'] as String?,
    createdAt: _data(row['created_at']),
    updatedAt: _data(row['updated_at']),
  );

  static String _digitos(Object? valor) =>
      valor?.toString().replaceAll(RegExp(r'\D'), '') ?? '';

  static DateTime? _dataApi(Object? valor) =>
      DateTime.tryParse(valor?.toString() ?? '');

  static DateTime? _data(Object? epoch) =>
      epoch is int ? DateTime.fromMillisecondsSinceEpoch(epoch * 1000) : null;
}
