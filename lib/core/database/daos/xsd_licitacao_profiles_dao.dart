import '../../../features/xsd_licitacao/models/xsd_licitacao_models.dart';
import '../database_service.dart';

class XsdLicitacaoProfilesDao {
  final DatabaseService db;
  XsdLicitacaoProfilesDao(this.db);

  Future<XsdLicitacaoProfile?> findByLicitacaoId(int licitacaoId) async {
    final statement = await db.pool.prepare(
      'SELECT profile_json FROM xsd_licitacao_profiles WHERE licitacao_id = ?',
    );
    final result = await statement.execute([licitacaoId]);
    if (result.rows.isEmpty) return null;
    return XsdLicitacaoProfile.decode(
      result.rows.first.typedAssoc()['profile_json'] as String,
    );
  }

  Future<void> upsert(int licitacaoId, XsdLicitacaoProfile profile) async {
    final statement = await db.pool.prepare('''
      INSERT INTO xsd_licitacao_profiles
        (licitacao_id, revision, profile_json)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE
        revision = VALUES(revision), profile_json = VALUES(profile_json),
        updated_at = UNIX_TIMESTAMP()
    ''');
    await statement.execute([
      licitacaoId,
      XsdLicitacaoProfile.revision,
      profile.encode(),
    ]);
  }
}
