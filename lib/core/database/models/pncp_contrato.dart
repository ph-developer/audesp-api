import 'dart:convert';

/// Contrato publicado no PNCP pelo CNPJ configurado.
class PncpContrato {
  final int id;
  final String cnpj;
  final int ano;
  final int sequencial;
  final String numeroControle;
  final String? numeroControleCompra;
  final String? numeroControleAta;
  final bool frutoAdesao;
  final String numeroContrato;
  final int? tipoContratoId;
  final String niFornecedor;
  final String nomeFornecedor;
  final String objeto;
  final double? valorGlobal;
  final DateTime? dataAssinatura;
  final DateTime? vigenciaInicio;
  final DateTime? vigenciaFim;
  final DateTime? dataPublicacao;
  final String dadosJson;
  final DateTime? dispensadaEm;
  final int? dispensadaPor;
  final String? motivoDispensa;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PncpContrato({
    required this.id,
    required this.cnpj,
    required this.ano,
    required this.sequencial,
    required this.numeroControle,
    this.numeroControleCompra,
    this.numeroControleAta,
    this.frutoAdesao = false,
    this.numeroContrato = '',
    this.tipoContratoId,
    this.niFornecedor = '',
    this.nomeFornecedor = '',
    this.objeto = '',
    this.valorGlobal,
    this.dataAssinatura,
    this.vigenciaInicio,
    this.vigenciaFim,
    this.dataPublicacao,
    required this.dadosJson,
    this.dispensadaEm,
    this.dispensadaPor,
    this.motivoDispensa,
    this.createdAt,
    this.updatedAt,
  });

  bool get dispensado => dispensadaEm != null;

  Map<String, dynamic> get dados {
    try {
      return jsonDecode(dadosJson) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  factory PncpContrato.fromApi(Map<String, dynamic> json) {
    final controle = _digitos(json['numeroControlePNCP']) ?? '';
    return PncpContrato(
      id: 0,
      cnpj: controle.length >= 14 ? controle.substring(0, 14) : '',
      ano: (json['anoContrato'] as num?)?.toInt() ?? 0,
      sequencial: (json['sequencialContrato'] as num?)?.toInt() ?? 0,
      numeroControle: controle,
      numeroControleCompra: _digitos(json['numeroControlePncpCompra']),
      numeroControleAta: _digitos(json['numeroControlePncpAta']),
      frutoAdesao: json['frutoAdesao'] == true,
      numeroContrato: json['numeroContratoEmpenho']?.toString().trim() ?? '',
      tipoContratoId: (json['tipoContrato']?['id'] as num?)?.toInt(),
      niFornecedor: json['niFornecedor']?.toString().trim() ?? '',
      nomeFornecedor:
          json['nomeRazaoSocialFornecedor']?.toString().trim() ?? '',
      objeto: json['objetoContrato']?.toString().trim() ?? '',
      valorGlobal: (json['valorGlobal'] as num?)?.toDouble(),
      dataAssinatura: _dataApi(json['dataAssinatura']),
      vigenciaInicio: _dataApi(json['dataVigenciaInicio']),
      vigenciaFim: _dataApi(json['dataVigenciaFim']),
      dataPublicacao: _dataApi(json['dataPublicacaoPncp']),
      dadosJson: jsonEncode(json),
    );
  }

  factory PncpContrato.fromMap(Map<String, dynamic> row) => PncpContrato(
    id: row['id'] as int,
    cnpj: row['cnpj'] as String,
    ano: row['ano'] as int,
    sequencial: row['sequencial'] as int,
    numeroControle: row['numero_controle'] as String,
    numeroControleCompra: _digitos(row['numero_controle_compra']),
    numeroControleAta: _digitos(row['numero_controle_ata']),
    frutoAdesao: row['fruto_adesao'] == 1,
    numeroContrato: row['numero_contrato'] as String? ?? '',
    tipoContratoId: row['tipo_contrato_id'] as int?,
    niFornecedor: row['ni_fornecedor'] as String? ?? '',
    nomeFornecedor: row['nome_fornecedor'] as String? ?? '',
    objeto: row['objeto'] as String? ?? '',
    valorGlobal: double.tryParse(row['valor_global']?.toString() ?? ''),
    dataAssinatura: _data(row['data_assinatura']),
    vigenciaInicio: _data(row['vigencia_inicio']),
    vigenciaFim: _data(row['vigencia_fim']),
    dataPublicacao: _data(row['data_publicacao']),
    dadosJson: row['dados_json'] as String,
    dispensadaEm: _data(row['dispensada_em']),
    dispensadaPor: row['dispensada_por'] as int?,
    motivoDispensa: row['motivo_dispensa'] as String?,
    createdAt: _data(row['created_at']),
    updatedAt: _data(row['updated_at']),
  );

  static String? _digitos(Object? valor) {
    final digitos = valor?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
    return digitos.isEmpty ? null : digitos;
  }

  static DateTime? _dataApi(Object? valor) =>
      DateTime.tryParse(valor?.toString() ?? '');

  static DateTime? _data(Object? epoch) =>
      epoch is int ? DateTime.fromMillisecondsSinceEpoch(epoch * 1000) : null;
}
