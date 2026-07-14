class AssinaturaModel {
  final int id;
  final String nome;
  final String cargo;

  const AssinaturaModel({
    required this.id,
    required this.nome,
    required this.cargo,
  });

  factory AssinaturaModel.fromMap(Map<String, dynamic> map) {
    return AssinaturaModel(
      id: map['id'] as int,
      nome: map['nome'] as String,
      cargo: map['cargo'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': nome, 'cargo': cargo};
  }

  AssinaturaModel copyWith({int? id, String? nome, String? cargo}) {
    return AssinaturaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cargo: cargo ?? this.cargo,
    );
  }
}
