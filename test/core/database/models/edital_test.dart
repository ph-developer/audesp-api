import 'package:flutter_test/flutter_test.dart';
import 'package:audesp_api/core/database/models/edital.dart';

void main() {
  group('Edital Model', () {
    test('fromMap e toMap preservam semPncp', () {
      final map = {
        'id': 1,
        'municipio': '1234',
        'entidade': '5678',
        'codigo_edital': 'PE-0001/2026',
        'sem_pncp': 1,
        'retificacao': 0,
        'status': 'draft',
        'pdf_path': null,
        'documento_json': '{}',
        'created_at': 1700000000,
        'updated_at': 1700000000,
      };

      final edital = Edital.fromMap(map);
      expect(edital.semPncp, isTrue);
      expect(edital.codigoEdital, 'PE-0001/2026');

      final serialized = edital.toMap();
      expect(serialized['sem_pncp'], 1);
      expect(serialized['codigo_edital'], 'PE-0001/2026');
    });

    test('semPncp default é false quando ausente no mapa', () {
      final map = {
        'id': 2,
        'municipio': '1234',
        'entidade': '5678',
        'codigo_edital': '1234567800019510000012026',
        'retificacao': 0,
        'status': 'draft',
        'pdf_path': null,
        'documento_json': '{}',
        'created_at': 1700000000,
        'updated_at': 1700000000,
      };

      final edital = Edital.fromMap(map);
      expect(edital.semPncp, isFalse);
      expect(edital.toMap()['sem_pncp'], 0);
    });
  });
}
