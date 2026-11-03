class Condutor {
  final int id;
  final String nome;

  /// Somente dígitos (11).
  final String cpf;

  const Condutor({required this.id, required this.nome, required this.cpf});

  factory Condutor.fromMap(Map<String, dynamic> map) {
    return Condutor(
      id: map['id'] as int,
      nome: map['nome'] as String,
      cpf: map['cpf'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': nome, 'cpf': cpf};
  }
}
