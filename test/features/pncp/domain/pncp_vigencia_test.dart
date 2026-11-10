import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/features/pncp/domain/pncp_vigencia.dart';
import 'package:flutter_test/flutter_test.dart';

PncpCompra _compra(String numeroControle, DateTime? publicacao) => PncpCompra(
  id: 1,
  cnpj: '49576416000141',
  ano: 2026,
  sequencial: 1,
  numeroControle: numeroControle,
  dataPublicacao: publicacao,
  dadosJson: '{}',
);

const _compra2026 = '49576416000141-1-000010/2026';
const _compra2025 = '49576416000141-1-000352/2025';

void main() {
  group('compra', () {
    test('vale a partir de 02/02/2026', () {
      expect(
        PncpVigencia.compra(_compra('1', DateTime(2026, 2, 1, 23, 59))),
        isFalse,
      );
      expect(PncpVigencia.compra(_compra('1', DateTime(2026, 2, 2))), isTrue);
    });

    test('sem data de publicação continua valendo', () {
      expect(PncpVigencia.compra(_compra('1', null)), isTrue);
    });
  });

  group('derivado', () {
    test('usa a publicação da compra conhecida', () {
      final publicacoes = PncpVigencia.publicacoes([
        _compra('4957641600014110000102026', DateTime(2026, 1, 20)),
      ]);
      expect(
        PncpVigencia.derivado(
          numeroControleCompra: _compra2026,
          publicacoes: publicacoes,
          assinatura: DateTime(2026, 3, 1),
        ),
        isFalse,
      );
      expect(
        PncpVigencia.derivado(
          numeroControleCompra: _compra2026,
          publicacoes: {'4957641600014110000102026': DateTime(2026, 2, 19)},
        ),
        isTrue,
      );
    });

    test('compra de ano anterior a 2026 fica de fora', () {
      expect(
        PncpVigencia.derivado(
          numeroControleCompra: _compra2025,
          publicacoes: const {},
          assinatura: DateTime(2026, 5, 1),
        ),
        isFalse,
      );
    });

    test('sem a compra, assinatura anterior ao corte fica de fora', () {
      expect(
        PncpVigencia.derivado(
          numeroControleCompra: _compra2026,
          publicacoes: const {},
          assinatura: DateTime(2026, 1, 30),
        ),
        isFalse,
      );
      expect(
        PncpVigencia.derivado(
          numeroControleCompra: _compra2026,
          publicacoes: const {},
          assinatura: DateTime(2026, 2, 2),
        ),
        isTrue,
      );
    });

    test('sem informação suficiente continua valendo', () {
      expect(
        PncpVigencia.derivado(
          numeroControleCompra: null,
          publicacoes: const {},
        ),
        isTrue,
      );
    });
  });
}
