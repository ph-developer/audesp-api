import 'package:flutter_test/flutter_test.dart';
import 'package:audesp_api/shared/formatters/pcnp_input_formatter.dart';

void main() {
  group('PcnpInputFormatter', () {
    test('applyMask aplica máscara para 25 dígitos numéricos', () {
      const raw = '1234567800019510000012026';
      final masked = PcnpInputFormatter.applyMask(raw);
      expect(masked, '12345678000195-1-000001/2026');
    });

    test('applyMask preserva código alfanumérico sem PNCP intacto', () {
      const code = 'PE-0001/2026';
      final formatted = PcnpInputFormatter.applyMask(code);
      expect(formatted, 'PE-0001/2026');
    });

    test('applyMask preserva string vazia ou incompleta não PNCP', () {
      expect(PcnpInputFormatter.applyMask(''), '');
      expect(PcnpInputFormatter.applyMask('DISP-012/2026'), 'DISP-012/2026');
    });

    test('stripMask remove máscara quando possui 25 dígitos', () {
      const masked = '12345678000195-1-000001/2026';
      final stripped = PcnpInputFormatter.stripMask(masked);
      expect(stripped, '1234567800019510000012026');
    });

    test('stripMask preserva código alfanumérico sem PNCP intacto', () {
      const code = 'DISP-0012/2026';
      final stripped = PcnpInputFormatter.stripMask(code);
      expect(stripped, 'DISP-0012/2026');
    });
  });
}
