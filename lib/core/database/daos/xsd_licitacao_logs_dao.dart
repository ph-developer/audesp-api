import '../database_service.dart';

class XsdLicitacaoLogEntry {
  final int licitacaoId;
  final String variant;
  final String revision;
  final String baseName;
  final String xmlSha256;
  final String markdownSha256;
  final String editalSourceSha256;
  final String licitacaoSourceSha256;
  final String profileSnapshot;

  const XsdLicitacaoLogEntry({
    required this.licitacaoId,
    required this.variant,
    required this.revision,
    required this.baseName,
    required this.xmlSha256,
    required this.markdownSha256,
    required this.editalSourceSha256,
    required this.licitacaoSourceSha256,
    required this.profileSnapshot,
  });
}

class XsdLicitacaoLogsDao {
  final DatabaseService db;

  XsdLicitacaoLogsDao(this.db);

  Future<void> insertLog(XsdLicitacaoLogEntry entry) async {
    final stmt = await db.pool.prepare('''
      INSERT INTO xsd_licitacao_logs
        (licitacao_id, variant, revision, base_name, xml_sha256,
         markdown_sha256, edital_source_sha256, licitacao_source_sha256,
         profile_snapshot, validation_success)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
    ''');
    await stmt.execute([
      entry.licitacaoId,
      entry.variant,
      entry.revision,
      entry.baseName,
      entry.xmlSha256,
      entry.markdownSha256,
      entry.editalSourceSha256,
      entry.licitacaoSourceSha256,
      entry.profileSnapshot,
    ]);
  }

  Future<DateTime?> getLastGenerationDate(int licitacaoId) async {
    final stmt = await db.pool.prepare(
      'SELECT created_at FROM xsd_licitacao_logs WHERE licitacao_id = ? ORDER BY created_at DESC LIMIT 1',
    );
    final result = await stmt.execute([licitacaoId]);
    if (result.rows.isNotEmpty) {
      final ts = result.rows.first.typedAssoc()['created_at'] as int;
      return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    }
    return null;
  }
}
