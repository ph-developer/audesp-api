import '../../../features/xsd_licitacao/models/xsd_licitacao_models.dart';
import '../database_service.dart';

class XsdComissaoDao {
  final DatabaseService db;

  XsdComissaoDao(this.db);

  Future<List<XsdComissaoMembro>> findAll() async {
    final result = await db.pool.execute(
      'SELECT * FROM xsd_comissao ORDER BY nome ASC',
    );
    return result.rows.map((row) {
      final map = row.typedAssoc();
      return XsdComissaoMembro(
        id: map['id'] as int?,
        cpf: map['cpf'] as String,
        nome: map['nome'] as String,
        cargo: map['cargo'] as String,
        // A atribuição pertence à licitação, não ao cadastro global.
        atribuicao: 2,
        naturezaCargo: map['natureza_cargo'] as int,
      );
    }).toList();
  }

  Future<void> insert(XsdComissaoMembro membro) async {
    final stmt = await db.pool.prepare(
      'INSERT INTO xsd_comissao (cpf, nome, cargo, natureza_cargo) VALUES (?, ?, ?, ?)',
    );
    await stmt.execute([
      membro.cpf,
      membro.nome,
      membro.cargo,
      membro.naturezaCargo,
    ]);
  }

  Future<void> delete(int id) async {
    final stmt = await db.pool.prepare('DELETE FROM xsd_comissao WHERE id = ?');
    await stmt.execute([id]);
  }
}
