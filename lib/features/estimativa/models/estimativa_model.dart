import 'estimativa_item_model.dart';
import 'estimativa_lote_model.dart';
import 'estimativa_fornecedor_model.dart';

class EstimativaModel {
  final int id;
  final int numero;
  final int ano;
  final String objeto;

  // Configurações Globais
  final String tipoEstimativa; // 'item' ou 'lote'
  final String calculoGlobal; // 'min', 'avg', 'median'
  final int casasDecimais; // 2 ou 4 (sempre arredondar para cima)

  // Textos para o PDF (mantido para retrocompatibilidade do JSON)
  final Map<String, String> textosPdf;

  // Novas propriedades solicitadas
  final String prazoVigencia;
  final String formaPagamento;

  // Novas propriedades solicitadas
  final bool registroPrecos;
  final bool temGarantia;
  final List<String> fontesRecurso;
  final String exclusividadeMeEpp;

  // Conteúdo
  final List<EstimativaFornecedor> fornecedores;
  final List<EstimativaLote> lotes;
  final List<EstimativaItem> itens; // usado quando tipoEstimativa == 'item'

  final int createdAt;
  final int updatedAt;

  EstimativaModel({
    required this.id,
    required this.numero,
    required this.ano,
    required this.objeto,
    this.tipoEstimativa = 'item',
    this.calculoGlobal = 'min',
    this.casasDecimais = 2,
    this.textosPdf = const {},
    this.registroPrecos = false,
    this.temGarantia = false,
    this.prazoVigencia = '',
    this.formaPagamento = '',
    this.fontesRecurso = const [],
    this.exclusividadeMeEpp = 'nenhuma',
    this.fornecedores = const [],
    this.lotes = const [],
    this.itens = const [],
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'ano': ano,
      'objeto': objeto,
      'tipoEstimativa': tipoEstimativa,
      'calculoGlobal': calculoGlobal,
      'casasDecimais': casasDecimais,
      'textosPdf': textosPdf,
      'registroPrecos': registroPrecos,
      'temGarantia': temGarantia,
      'prazoVigencia': prazoVigencia,
      'formaPagamento': formaPagamento,
      'fontesRecurso': fontesRecurso,
      'exclusividadeMeEpp': exclusividadeMeEpp,
      'fornecedores': fornecedores.map((x) => x.toMap()).toList(),
      'lotes': lotes.map((x) => x.toMap()).toList(),
      'itens': itens.map((x) => x.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory EstimativaModel.fromMap(Map<String, dynamic> map) {
    return EstimativaModel(
      id: map['id']?.toInt() ?? 0,
      numero: map['numero']?.toInt() ?? 0,
      ano: map['ano']?.toInt() ?? 0,
      objeto: map['objeto'] ?? '',
      tipoEstimativa: map['tipoEstimativa'] ?? 'item',
      calculoGlobal: map['calculoGlobal'] ?? 'min',
      casasDecimais: map['casasDecimais'] ?? 2,
      textosPdf: Map<String, String>.from(map['textosPdf'] ?? {}),
      registroPrecos: map['registroPrecos'] ?? false,
      temGarantia: map['temGarantia'] ?? false,
      prazoVigencia: map['prazoVigencia'] ?? '',
      formaPagamento: map['formaPagamento'] ?? '',
      fontesRecurso: List<String>.from(map['fontesRecurso'] ?? []),
      exclusividadeMeEpp: map['exclusividadeMeEpp'] ?? 'nenhuma',
      fornecedores: List<EstimativaFornecedor>.from(
        (map['fornecedores'] as List<dynamic>? ?? []).map(
          (x) => EstimativaFornecedor.fromMap(x),
        ),
      ),
      lotes: List<EstimativaLote>.from(
        (map['lotes'] as List<dynamic>? ?? []).map(
          (x) => EstimativaLote.fromMap(x),
        ),
      ),
      itens: List<EstimativaItem>.from(
        (map['itens'] as List<dynamic>? ?? []).map(
          (x) => EstimativaItem.fromMap(x),
        ),
      ),
      createdAt: map['createdAt']?.toInt() ?? 0,
      updatedAt: map['updatedAt']?.toInt() ?? 0,
    );
  }

  EstimativaModel copyWith({
    int? id,
    int? numero,
    int? ano,
    String? objeto,
    String? tipoEstimativa,
    String? calculoGlobal,
    int? casasDecimais,
    Map<String, String>? textosPdf,
    bool? registroPrecos,
    bool? temGarantia,
    String? prazoVigencia,
    String? formaPagamento,
    List<String>? fontesRecurso,
    String? exclusividadeMeEpp,
    List<EstimativaFornecedor>? fornecedores,
    List<EstimativaLote>? lotes,
    List<EstimativaItem>? itens,
    int? createdAt,
    int? updatedAt,
  }) {
    return EstimativaModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      ano: ano ?? this.ano,
      objeto: objeto ?? this.objeto,
      tipoEstimativa: tipoEstimativa ?? this.tipoEstimativa,
      calculoGlobal: calculoGlobal ?? this.calculoGlobal,
      casasDecimais: casasDecimais ?? this.casasDecimais,
      textosPdf: textosPdf ?? this.textosPdf,
      registroPrecos: registroPrecos ?? this.registroPrecos,
      temGarantia: temGarantia ?? this.temGarantia,
      prazoVigencia: prazoVigencia ?? this.prazoVigencia,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      fontesRecurso: fontesRecurso ?? this.fontesRecurso,
      exclusividadeMeEpp: exclusividadeMeEpp ?? this.exclusividadeMeEpp,
      fornecedores: fornecedores ?? this.fornecedores,
      lotes: lotes ?? this.lotes,
      itens: itens ?? this.itens,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get valorTotalGlobal {
    if (tipoEstimativa == 'lote') {
      return lotes.fold(
        0.0,
        (sum, lote) => sum + lote.getValorTotal(calculoGlobal, casasDecimais: casasDecimais),
      );
    } else {
      return itens.fold(
        0.0,
        (sum, item) => sum + item.getValorTotal(calculoGlobal, casasDecimais: casasDecimais),
      );
    }
  }
}
