import 'package:audesp_api/features/ajuste/domain/ajuste_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _documento({
  bool adesao = false,
  bool jurisdicionada = false,
}) => {
  'descritor': {
    'adesaoParticipacao': adesao,
    'gerenciadoraJurisdicionada': jurisdicionada,
    'codigoEdital': '1234567800019010000012026',
  },
  'categoriaProcessoId': 2,
  'tipoObjetoContrato': 3,
  'itens': [4, 8],
};

void main() {
  group('objeto por categoria', () {
    const dominios = {
      1: [1, 2],
      2: [3, 4, 5, 6, 7, 8, 9, 10, 11],
      3: [12, 13, 14],
      4: [15],
      5: [16],
      6: [17],
      7: [18, 19],
      8: [20, 21, 22, 23, 24, 25, 26, 27],
      9: [18, 19],
      10: [28],
      11: [29],
    };

    test('aceita somente as combinações da tabela', () {
      for (final categoria in dominios.keys) {
        for (var objeto = 1; objeto <= 29; objeto++) {
          expect(
            AjusteRules.validarTipoObjetoContrato(
              categoriaProcessoId: categoria,
              tipoObjetoContrato: objeto,
            ),
            dominios[categoria]!.contains(objeto) ? isNull : isNotNull,
            reason: 'Categoria $categoria, objeto $objeto',
          );
        }
      }
    });

    test('rejeita campos ausentes e códigos desconhecidos', () {
      expect(
        AjusteRules.validarTipoObjetoContrato(
          categoriaProcessoId: null,
          tipoObjetoContrato: 3,
        ),
        isNotNull,
      );
      expect(
        AjusteRules.validarTipoObjetoContrato(
          categoriaProcessoId: 2,
          tipoObjetoContrato: null,
        ),
        isNotNull,
      );
      expect(
        AjusteRules.validarTipoObjetoContrato(
          categoriaProcessoId: 99,
          tipoObjetoContrato: 3,
        ),
        isNotNull,
      );
      expect(
        AjusteRules.validarTipoObjetoContrato(
          categoriaProcessoId: 2,
          tipoObjetoContrato: 99,
        ),
        isNotNull,
      );
    });

    test('envio rejeita objeto importado incompatível', () {
      final documento = _documento()..['tipoObjetoContrato'] = 12;
      expect(
        AjusteRules.validarEnvio(documento),
        contains('objeto do contrato 12'),
      );
      documento['categoriaProcessoId'] = 3;
      expect(AjusteRules.validarEnvio(documento), isNull);
    });
  });

  group('itens do ajuste', () {
    test('sem adesão confere existência e duplicidade', () {
      expect(
        AjusteRules.validarItens(
          [4, 8],
          adesaoParticipacao: false,
          numerosLicitacao: {1, 4, 8},
        ),
        isNull,
      );
      expect(
        AjusteRules.validarItens(
          [4, 9],
          adesaoParticipacao: false,
          numerosLicitacao: {4, 8},
        ),
        contains('Item 9 não consta'),
      );
      expect(
        AjusteRules.validarItens([4, 4], adesaoParticipacao: false),
        contains('Item 4 repetido'),
      );
    });

    test('sem referência local não bloqueia existência', () {
      expect(
        AjusteRules.validarItens([4, 9], adesaoParticipacao: false),
        isNull,
      );
      expect(AjusteRules.validarEnvio(_documento()), isNull);
    });

    test('adesão pula licitação local mas impede itens duplicados', () {
      expect(
        AjusteRules.validarItens(
          [4, 9],
          adesaoParticipacao: true,
          numerosLicitacao: {1},
        ),
        isNull,
      );
      expect(
        AjusteRules.validarItens(
          [4, 4],
          adesaoParticipacao: true,
          numerosLicitacao: {1},
        ),
        contains('Item 4 repetido'),
      );
    });

    test('confere lista importada no envio', () {
      expect(
        AjusteRules.validarEnvio(_documento(), numerosLicitacao: {4}),
        contains('Item 8 não consta'),
      );
      expect(
        AjusteRules.validarEnvio(_documento()..['itens'] = [8, 8]),
        contains('Item 8 repetido'),
      );
    });
  });

  group('códigos da adesão', () {
    test('exige edital PNCP completo e aceita código com máscara', () {
      for (final codigo in [null, '', '1' * 24, '1' * 26]) {
        expect(AjusteRules.validarCodigoEditalAdesao(codigo), isNotNull);
      }
      for (final codigo in [
        '1234567800019010000012026',
        '12345678000190-1-000001/2026',
      ]) {
        expect(AjusteRules.validarCodigoEditalAdesao(codigo), isNull);
      }
    });

    test('ata é opcional, mas deve estar completa quando informada', () {
      for (final codigo in [
        null,
        '',
        ' ',
        '1234567800019010000012026000001',
        '12345678000190-1-000001/2026-000001',
      ]) {
        expect(AjusteRules.validarCodigoAtaAdesao(codigo), isNull);
      }
      for (final codigo in ['1' * 30, '1' * 32, 'inválida']) {
        expect(AjusteRules.validarCodigoAtaAdesao(codigo), isNotNull);
      }
    });

    test(
      'ambas as gerenciadoras usam códigos próprios sem conferir itens locais',
      () {
        for (final jurisdicionada in [false, true]) {
          final documento = _documento(
            adesao: true,
            jurisdicionada: jurisdicionada,
          );
          expect(
            AjusteRules.validarEnvio(documento, numerosLicitacao: {1}),
            isNull,
          );
          final descritor = documento['descritor'] as Map<String, dynamic>;
          descritor['codigoAta'] = '123';
          expect(AjusteRules.validarEnvio(documento), contains('31 dígitos'));
          descritor.remove('codigoAta');
          descritor['codigoEdital'] = '';
          expect(AjusteRules.validarEnvio(documento), contains('25 dígitos'));
        }
      },
    );

    test('sem adesão preserva os códigos locais de edital Sem PNCP', () {
      final documento = _documento();
      final descritor = documento['descritor'] as Map<String, dynamic>;
      descritor['codigoEdital'] = 'EDITAL-LOCAL/2026';
      descritor['codigoAta'] = 'ATA-LOCAL/2026';
      expect(AjusteRules.validarEnvio(documento), isNull);
    });
  });
}
