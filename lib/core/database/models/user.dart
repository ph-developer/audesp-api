class User {
  final int id;
  final String nome;
  final String email;
  final String? passwordHash;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.nome,
    required this.email,
    this.passwordHash,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> row) => User(
        id: row['id'] as int,
        nome: row['nome'] as String,
        email: row['email'] as String,
        passwordHash: row['password_hash'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (row['created_at'] as int) * 1000,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'password_hash': passwordHash,
        'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      };
}
