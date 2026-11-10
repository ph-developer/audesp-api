import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/features/pncp/domain/pncp_cursores.dart';
import 'package:flutter_test/flutter_test.dart';

const _cnpj = '49576416000141';
final _hoje = DateTime(2026, 11, 9);

void main() {
  group('validar', () {
    test('ata em branco é sempre válida', () {
      expect(PncpCursores.validar(compra: null, ata: null), isNull);
    });

    test('ata até o cursor das compras é válida', () {
      expect(PncpCursores.validar(compra: 334, ata: 334), isNull);
      expect(PncpCursores.validar(compra: 334, ata: 300), isNull);
    });

    test('ata além das compras, ou sem compras, é rejeitada', () {
      expect(PncpCursores.validar(compra: 334, ata: 335), isNotNull);
      expect(PncpCursores.validar(compra: null, ata: 1), isNotNull);
    });
  });

  group('alteracoes', () {
    test('nada alterado não grava nada', () {
      expect(
        PncpCursores.alteracoes(
          cnpj: _cnpj,
          ano: 2026,
          hoje: _hoje,
          compra: 334,
          contrato: 200,
          ata: 300,
        ),
        isEmpty,
      );
    });

    test('compra e contrato gravam só o próprio cursor', () {
      expect(
        PncpCursores.alteracoes(
          cnpj: _cnpj,
          ano: 2026,
          hoje: _hoje,
          compra: 334,
          compraAlterada: true,
          contratoAlterado: true,
        ),
        {
          SettingsKeys.pncpSequencia(_cnpj, 2026): '334',
          SettingsKeys.pncpContratoSequencia(_cnpj, 2026): null,
        },
      );
    });

    test('ata alterada move a consulta por data para hoje', () {
      expect(
        PncpCursores.alteracoes(
          cnpj: _cnpj,
          ano: 2026,
          hoje: _hoje,
          ata: 300,
          ataAlterada: true,
        ),
        {
          SettingsKeys.pncpAtaCompraSequencia(_cnpj, 2026): '300',
          SettingsKeys.pncpAtaCompraPagina(_cnpj, 2026): null,
          SettingsKeys.pncpAtasAtualizadasAte: '2026-11-09',
          SettingsKeys.pncpAtasAtualizadasCnpj: _cnpj,
        },
      );
    });

    test('ata em branco recomeça a varredura e a consulta por data', () {
      expect(
        PncpCursores.alteracoes(
          cnpj: _cnpj,
          ano: 2026,
          hoje: _hoje,
          ataAlterada: true,
        ),
        {
          SettingsKeys.pncpAtaCompraSequencia(_cnpj, 2026): null,
          SettingsKeys.pncpAtaCompraPagina(_cnpj, 2026): null,
          SettingsKeys.pncpAtasAtualizadasAte: null,
          SettingsKeys.pncpAtasAtualizadasCnpj: null,
        },
      );
    });
  });
}
