class AppPermissions {
  static const int none = 0;
  static const int edital = 1;
  static const int licitacao = 2;
  static const int ata = 4;
  static const int ajuste = 8;
  static const int estimativa = 16;
}

class User {
  final int id;
  final String nome;
  final String email;
  final String? passwordHash;
  final bool isAdmin;
  final int permissions;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.nome,
    required this.email,
    this.passwordHash,
    this.isAdmin = false,
    this.permissions = 0,
    required this.createdAt,
  });

  bool hasPermission(int permission) {
    if (isAdmin) return true;
    return (permissions & permission) == permission;
  }

  factory User.fromMap(Map<String, dynamic> row) => User(
        id: row['id'] as int,
        nome: row['nome'] as String,
        email: row['email'] as String,
        passwordHash: row['password_hash'] as String?,
        isAdmin: (row['is_admin'] as int?) == 1,
        permissions: row['permissions'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (row['created_at'] as int) * 1000,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'password_hash': passwordHash,
        'is_admin': isAdmin ? 1 : 0,
        'permissions': permissions,
        'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      };
}
