import 'package:flutter_test/flutter_test.dart';
import 'package:audesp_api/core/database/models/edital.dart';

void main() {
  group('Edital Model', () {
    test('fromMap e toMap preservam semPncp', () {
      final map = {
        'id': 1,
        'estimativa_id': 42,
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
      expect(edital.estimativaId, 42);
      expect(edital.codigoEdital, 'PE-0001/2026');

      final serialized = edital.toMap();
      expect(serialized['sem_pncp'], 1);
      expect(serialized['estimativa_id'], 42);
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
      expect(edital.estimativaId, isNull);
      expect(edital.toMap()['estimativa_id'], isNull);
      expect(edital.toMap()['sem_pncp'], 0);
      expect(edital.oculto, isFalse);
    });

    test('fromMap e toMap preservam a ocultação', () {
      final edital = Edital.fromMap({
        'id': 3,
        'municipio': '1234',
        'entidade': '5678',
        'codigo_edital': '1234567800019510000012026',
        'retificacao': 0,
        'status': 'sent',
        'documento_json': '{}',
        'created_at': 1700000000,
        'updated_at': 1700000000,
        'oculto_em': 1800000000,
        'oculto_por': 1,
        'motivo_ocultacao': 'Lançado pelo sistema antigo',
      });
      expect(edital.oculto, isTrue);
      expect(edital.ocultoEm!.millisecondsSinceEpoch, 1800000000 * 1000);
      expect(edital.ocultoPor, 1);
      expect(edital.motivoOcultacao, 'Lançado pelo sistema antigo');
      expect(edital.toMap()['oculto_em'], 1800000000);
    });
  });
}
