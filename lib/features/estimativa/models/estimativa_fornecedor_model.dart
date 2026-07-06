import 'package:uuid/uuid.dart';

class EstimativaFornecedor {
  final String id;
  final String razaoSocial;
  final String cnpj;
  final String data;
  final bool desclassificado;
  final bool bancoDePrecos;

  EstimativaFornecedor({
    String? id,
    required this.razaoSocial,
    required this.cnpj,
    required this.data,
    this.desclassificado = false,
    this.bancoDePrecos = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'razaoSocial': razaoSocial,
      'cnpj': cnpj,
      'data': data,
      'desclassificado': desclassificado,
      'bancoDePrecos': bancoDePrecos,
    };
  }

  factory EstimativaFornecedor.fromMap(Map<String, dynamic> map) {
    return EstimativaFornecedor(
      id: map['id'] ?? const Uuid().v4(),
      razaoSocial: map['razaoSocial'] ?? '',
      cnpj: map['cnpj'] ?? '',
      data: map['data'] ?? '',
      desclassificado: map['desclassificado'] ?? false,
      bancoDePrecos: map['bancoDePrecos'] ?? false,
    );
  }

  EstimativaFornecedor copyWith({
    String? id,
    String? razaoSocial,
    String? cnpj,
    String? data,
    bool? desclassificado,
    bool? bancoDePrecos,
  }) {
    return EstimativaFornecedor(
      id: id ?? this.id,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      cnpj: cnpj ?? this.cnpj,
      data: data ?? this.data,
      desclassificado: desclassificado ?? this.desclassificado,
      bancoDePrecos: bancoDePrecos ?? this.bancoDePrecos,
    );
  }
}
