import 'package:flutter_test/flutter_test.dart';
import 'package:audesp_api/core/database/models/ajuste.dart';

void main() {
  group('Ajuste Model', () {
    test('fromMap e toMap preservam adesão sem edital local', () {
      final map = {
        'id': 1,
        'edital_id': null,
        'ata_id': null,
        'municipio': '1234',
        'entidade': '5678',
        'codigo_edital': '1234567800019510000012026',
        'codigo_ata': '1234567800019510000012026000001',
        'codigo_contrato': '8765432100019520000012026',
        'retificacao': 0,
        'status': 'draft',
        'documento_json':
            '{"descritor":{"adesaoParticipacao":true,"codigoEdital":"1234567800019510000012026","codigoAta":"1234567800019510000012026000001"}}',
        'created_at': 1700000000,
        'updated_at': 1700000001,
      };

      final ajuste = Ajuste.fromMap(map);
      expect(ajuste.editalId, isNull);
      expect(ajuste.ataId, isNull);
      expect(ajuste.codigoEdital, map['codigo_edital']);
      expect(ajuste.codigoAta, map['codigo_ata']);
      expect(ajuste.toMap(), map);
      expect(Ajuste.fromMap(ajuste.toMap()).editalId, isNull);
    });

    test('fromMap e toMap preservam vínculo com edital e ata locais', () {
      final map = {
        'id': 2,
        'edital_id': 7,
        'ata_id': 8,
        'municipio': '1234',
        'entidade': '5678',
        'codigo_edital': '1234567800019510000012026',
        'codigo_ata': '1234567800019510000012026000001',
        'codigo_contrato': '1234567800019520000012026',
        'retificacao': 1,
        'status': 'sent',
        'documento_json': '{}',
        'created_at': 1700000000,
        'updated_at': 1700000001,
      };

      final ajuste = Ajuste.fromMap(map);
      expect(ajuste.editalId, 7);
      expect(ajuste.ataId, 8);
      expect(ajuste.retificacao, isTrue);
      expect(ajuste.toMap(), map);
      expect(Ajuste.fromMap(ajuste.toMap()).editalId, 7);
    });
  });
}
