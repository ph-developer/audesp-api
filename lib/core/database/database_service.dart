import 'dart:convert';
import 'package:mysql_client/mysql_client.dart';

class DatabaseService {
  final MySQLConnectionPool pool;

  DatabaseService(this.pool);

  Future<void> initialize() async {
    await _createSchemaTable();
    await _createTables();
    await _ensureUniqueIndexes();
  }

  Future<int> get schemaVersion async {
    final result = await pool.execute('SELECT version FROM __schema');
    return result.rows.first.typedAssoc()['version'] as int;
  }

  Future<void> setSchemaVersion(int version) async {
    final stmt = await pool.prepare('UPDATE __schema SET version = (?)');
    await stmt.execute([version]);
  }

  Future<void> _createSchemaTable() async {
    await pool.execute(
      'CREATE TABLE IF NOT EXISTS __schema ('
      'version INTEGER NOT NULL DEFAULT 0'
      ')',
    );
    final count = await pool.execute('SELECT COUNT(*) FROM __schema');
    if (count.rows.first.typedAssoc()['COUNT(*)'] as int == 0) {
      await pool.execute('INSERT INTO __schema (version) VALUES (0)');
    }
  }

  Future<void> _createTables() async {
    final version = await schemaVersion;

    if (version < 1) {
      await pool.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          nome TEXT NOT NULL,
          email TEXT NOT NULL,
          password_hash TEXT NULL,
          is_admin TINYINT NOT NULL DEFAULT 0,
          permissions INT NOT NULL DEFAULT 0,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP())
        )
      ''');

      await pool.execute('''
        CREATE TABLE IF NOT EXISTS editais (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          municipio TEXT NOT NULL,
          entidade TEXT NOT NULL,
          codigo_edital TEXT NOT NULL,
          sem_pncp TINYINT NOT NULL DEFAULT 0,
          retificacao TINYINT NOT NULL DEFAULT 0,
          status TEXT NOT NULL,
          pdf_path TEXT NULL,
          documento_json LONGTEXT NOT NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          updated_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP())
        )
      ''');

      await pool.execute('''
        CREATE TABLE IF NOT EXISTS licitacoes (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          edital_id BIGINT NOT NULL,
          municipio TEXT NOT NULL,
          entidade TEXT NOT NULL,
          codigo_edital TEXT NOT NULL,
          retificacao TINYINT NOT NULL DEFAULT 0,
          status TEXT NOT NULL,
          documento_json LONGTEXT NOT NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          updated_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          FOREIGN KEY (edital_id) REFERENCES editais(id)
        )
      ''');

      await pool.execute('''
        CREATE TABLE IF NOT EXISTS atas (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          edital_id BIGINT NOT NULL,
          municipio TEXT NOT NULL,
          entidade TEXT NOT NULL,
          codigo_edital TEXT NOT NULL,
          codigo_ata TEXT NOT NULL,
          retificacao TINYINT NOT NULL DEFAULT 0,
          status TEXT NOT NULL,
          documento_json LONGTEXT NOT NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          updated_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          FOREIGN KEY (edital_id) REFERENCES editais(id)
        )
      ''');

      await pool.execute('''
        CREATE TABLE IF NOT EXISTS ajustes (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          edital_id BIGINT NULL,
          ata_id BIGINT NULL,
          municipio TEXT NOT NULL,
          entidade TEXT NOT NULL,
          codigo_edital TEXT NOT NULL,
          codigo_ata TEXT NULL,
          codigo_contrato TEXT NOT NULL,
          retificacao TINYINT NOT NULL DEFAULT 0,
          status TEXT NOT NULL,
          documento_json LONGTEXT NOT NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          updated_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          FOREIGN KEY (edital_id) REFERENCES editais(id),
          FOREIGN KEY (ata_id) REFERENCES atas(id)
        )
      ''');

      await pool.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          `key` VARCHAR(255) NOT NULL PRIMARY KEY,
          `value` TEXT NOT NULL
        )
      ''');

      await pool.execute('''
        CREATE TABLE IF NOT EXISTS api_logs (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          endpoint TEXT NOT NULL,
          request LONGTEXT NOT NULL,
          response LONGTEXT NULL,
          status_code INT NULL,
          user_id BIGINT NULL,
          timestamp BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP())
        )
      ''');

      await setSchemaVersion(1);
    }

    if (version < 2) {
      await _ensureUniqueIndexes();
      await setSchemaVersion(2);
    }

    if (version < 3) {
      try {
        await pool.execute(
          'ALTER TABLE api_logs ADD COLUMN protocolo VARCHAR(255) NULL',
        );
        await pool.execute(
          'ALTER TABLE api_logs ADD COLUMN status_protocolo VARCHAR(255) NULL',
        );
        await pool.execute(
          'ALTER TABLE api_logs ADD COLUMN retorno_status LONGTEXT NULL',
        );
      } catch (_) {}
      await setSchemaVersion(3);
    }

    if (version < 4) {
      final result = await pool.execute(
        'SELECT id, response FROM api_logs WHERE response IS NOT NULL AND status_code >= 200 AND status_code < 300 AND protocolo IS NULL',
      );
      for (final row in result.rows) {
        final map = row.typedAssoc();
        final id = map['id'] as int;
        final responseText = map['response'] as String;
        try {
          final json = jsonDecode(responseText);
          if (json is Map<String, dynamic> && json.containsKey('protocolo')) {
            final protocolo = json['protocolo']?.toString();
            if (protocolo != null && protocolo.isNotEmpty) {
              final stmt = await pool.prepare(
                'UPDATE api_logs SET protocolo = ?, status_protocolo = ? WHERE id = ?',
              );
              await stmt.execute([protocolo, 'Pendente', id]);
            }
          }
        } catch (_) {}
      }
      await setSchemaVersion(4);
    }

    if (version < 5) {
      try {
        await pool.execute(
          'ALTER TABLE users ADD COLUMN is_admin TINYINT NOT NULL DEFAULT 0',
        );
        await pool.execute(
          'ALTER TABLE users ADD COLUMN permissions INT NOT NULL DEFAULT 0',
        );

        final countResult = await pool.execute('SELECT COUNT(*) FROM users');
        if ((countResult.rows.first.typedAssoc()['COUNT(*)'] as int) == 0) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await pool.execute(
            'INSERT INTO users (nome, email, password_hash, is_admin, permissions, created_at) '
            'VALUES (:nome, :email, NULL, 1, 0, :created_at)',
            {
              'nome': 'Administrador',
              'email': 'ti@penapolis.sp.gov.br',
              'created_at': now,
            },
          );
        }
      } catch (_) {}
      await setSchemaVersion(5);
    }

    if (version < 6) {
      await pool.execute('''
        CREATE TABLE IF NOT EXISTS estimativas (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          numero INT NOT NULL,
          ano INT NOT NULL,
          objeto TEXT NOT NULL,
          documento_json LONGTEXT NOT NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          updated_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP())
        )
      ''');
      await setSchemaVersion(6);
    }

    if (version < 7) {
      await pool.execute('''
        CREATE TABLE IF NOT EXISTS assinaturas_predefinidas (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          nome TEXT NOT NULL,
          cargo TEXT NOT NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP())
        )
      ''');
      await setSchemaVersion(7);
    }

    if (version < 8) {
      await pool.execute('''
        CREATE TABLE IF NOT EXISTS xsd_comissao (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          cpf TEXT NOT NULL,
          nome TEXT NOT NULL,
          cargo TEXT NOT NULL,
          atribuicao INT NOT NULL DEFAULT 1,
          natureza_cargo INT NOT NULL DEFAULT 1,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP())
        )
      ''');
      await pool.execute('''
        CREATE TABLE IF NOT EXISTS xsd_licitacao_logs (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          licitacao_id BIGINT NOT NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          FOREIGN KEY (licitacao_id) REFERENCES licitacoes(id)
        )
      ''');
      await setSchemaVersion(8);
    }

    if (version < 9) {
      await pool.execute('''
        CREATE TABLE IF NOT EXISTS xsd_licitacao_profiles (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          licitacao_id BIGINT NOT NULL,
          revision VARCHAR(20) NOT NULL DEFAULT '2026_A',
          profile_json LONGTEXT NOT NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          updated_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          UNIQUE KEY uq_xsd_profile_licitacao (licitacao_id),
          FOREIGN KEY (licitacao_id) REFERENCES licitacoes(id)
        )
      ''');
      final columns = <String, String>{
        'variant': 'VARCHAR(10) NULL',
        'revision': "VARCHAR(20) NOT NULL DEFAULT '2026_A'",
        'base_name': 'VARCHAR(255) NULL',
        'xml_sha256': 'CHAR(64) NULL',
        'edital_source_sha256': 'CHAR(64) NULL',
        'licitacao_source_sha256': 'CHAR(64) NULL',
        'profile_snapshot': 'LONGTEXT NULL',
        'validation_success': 'TINYINT NOT NULL DEFAULT 0',
      };
      for (final entry in columns.entries) {
        final found = await pool.execute(
          "SELECT COUNT(*) AS c FROM information_schema.columns "
          "WHERE table_schema = (SELECT DATABASE()) "
          "AND table_name = 'xsd_licitacao_logs' AND column_name = :column",
          {'column': entry.key},
        );
        if (found.rows.first.typedAssoc()['c'] == 0) {
          await pool.execute(
            'ALTER TABLE xsd_licitacao_logs ADD COLUMN `${entry.key}` ${entry.value}',
          );
        }
      }
      await setSchemaVersion(9);
    }

    if (version < 10) {
      await pool.execute('DROP TABLE IF EXISTS xsd_licitacao_profiles');
      await pool.execute('DROP TABLE IF EXISTS xsd_licitacao_logs');
      await pool.execute('DROP TABLE IF EXISTS xsd_comissao');
      await setSchemaVersion(10);
    }

    if (version < 11) {
      final found = await pool.execute(
        "SELECT COUNT(*) AS c FROM information_schema.columns "
        "WHERE table_schema = (SELECT DATABASE()) "
        "AND table_name = 'editais' AND column_name = 'sem_pncp'",
      );
      if (found.rows.first.typedAssoc()['c'] == 0) {
        await pool.execute(
          'ALTER TABLE editais ADD COLUMN sem_pncp TINYINT NOT NULL DEFAULT 0',
        );
      }
      await setSchemaVersion(11);
    }

    if (version < 12) {
      final found = await pool.execute(
        "SELECT IS_NULLABLE FROM information_schema.columns "
        "WHERE table_schema = (SELECT DATABASE()) "
        "AND table_name = 'ajustes' AND column_name = 'edital_id'",
      );
      if (found.rows.first.typedAssoc()['IS_NULLABLE'] == 'NO') {
        await pool.execute('ALTER TABLE ajustes MODIFY edital_id BIGINT NULL');
      }
      await setSchemaVersion(12);
    }

    if (version < 13) {
      final statusFound = await pool.execute(
        "SELECT COUNT(*) AS c FROM information_schema.columns "
        "WHERE table_schema = (SELECT DATABASE()) "
        "AND table_name = 'estimativas' AND column_name = 'status'",
      );
      if (statusFound.rows.first.typedAssoc()['c'] == 0) {
        await pool.execute(
          "ALTER TABLE estimativas ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'rascunho'",
        );
        // Preserva a importação das estimativas anteriores à introdução do estado.
        await pool.execute("UPDATE estimativas SET status = 'finalizada'");
      }

      final estimativaFound = await pool.execute(
        "SELECT COUNT(*) AS c FROM information_schema.columns "
        "WHERE table_schema = (SELECT DATABASE()) "
        "AND table_name = 'editais' AND column_name = 'estimativa_id'",
      );
      if (estimativaFound.rows.first.typedAssoc()['c'] == 0) {
        // Sem FK: a origem pode ser excluída sem alterar os itens importados.
        await pool.execute(
          'ALTER TABLE editais ADD COLUMN estimativa_id BIGINT NULL',
        );
      }
      await setSchemaVersion(13);
    }

    if (version < 14) {
      // Compras publicadas no PNCP pelo CNPJ configurado, para cobrar as
      // que ainda não têm edital no sistema.
      await pool.execute('''
        CREATE TABLE IF NOT EXISTS pncp_compras (
          id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
          cnpj VARCHAR(14) NOT NULL,
          ano INT NOT NULL,
          sequencial INT NOT NULL,
          numero_controle VARCHAR(25) NOT NULL,
          modalidade_id INT NULL,
          numero_compra VARCHAR(50) NULL,
          objeto TEXT NULL,
          valor_total_estimado DECIMAL(18,4) NULL,
          data_publicacao BIGINT NULL,
          dados_json LONGTEXT NOT NULL,
          dispensada_em BIGINT NULL,
          dispensada_por BIGINT NULL,
          motivo_dispensa VARCHAR(500) NULL,
          created_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          updated_at BIGINT NOT NULL DEFAULT (UNIX_TIMESTAMP()),
          UNIQUE KEY uk_pncp_compras_sequencia (cnpj, ano, sequencial),
          UNIQUE KEY uk_pncp_compras_controle (numero_controle)
        )
      ''');
      await setSchemaVersion(14);
    }
  }

  Future<void> _ensureUniqueIndexes() async {
    final result = await pool.execute(
      "SELECT COUNT(*) AS c FROM information_schema.statistics "
      "WHERE table_schema = (SELECT DATABASE()) "
      "AND table_name = 'users' AND index_name = 'idx_users_email'",
    );
    if (result.rows.first.typedAssoc()['c'] == 0) {
      await pool.execute(
        'CREATE UNIQUE INDEX idx_users_email ON users(email(255))',
      );
    }
  }

  Future<void> close() async {
    await pool.close();
  }
}
