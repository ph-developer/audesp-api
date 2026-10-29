import 'package:audesp_api/features/edital/domain/edital_domain.dart';
import 'package:audesp_api/features/edital/domain/edital_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PDF do edital', () {
    test('somente inexigibilidade permite ausência com confirmação', () {
      for (final modalidade in kModalidades.keys) {
        expect(
          EditalRules.validarPdfObrigatorio(
            modalidadeId: modalidade,
            temPdf: false,
          ),
          modalidade == 9 ? isNull : isNotNull,
          reason: 'Modalidade $modalidade',
        );
        expect(
          EditalRules.exigeConfirmacaoSemPdf(
            modalidadeId: modalidade,
            temPdf: false,
          ),
          modalidade == 9,
        );
        expect(
          EditalRules.validarPdfObrigatorio(
            modalidadeId: modalidade,
            temPdf: true,
          ),
          isNull,
        );
        expect(
          EditalRules.exigeConfirmacaoSemPdf(
            modalidadeId: modalidade,
            temPdf: true,
          ),
          isFalse,
        );
      }
    });

    test('rejeita arquivo inexistente e tamanho acima de 30 MB', () {
      expect(
        EditalRules.validarArquivoPdf(existe: false, tamanhoBytes: 0),
        contains('não existe'),
      );
      expect(EditalRules.limitePdfBytes, 30 * 1024 * 1024);
      expect(
        EditalRules.validarArquivoPdf(
          existe: true,
          tamanhoBytes: 30 * 1024 * 1024,
        ),
        isNull,
      );
      expect(
        EditalRules.validarArquivoPdf(
          existe: true,
          tamanhoBytes: 30 * 1024 * 1024 + 1,
        ),
        contains('30 MB'),
      );
    });
  });

  group('instrumento e modalidade', () {
    test('confere a tabela e as novas modalidades internacionais', () {
      const permitidas = {
        1: {1, 2, 3, 4, 5, 6, 7, 13, 14, 16, 17, 18, 19, 997, 998, 999},
        2: {8, 14},
        3: {8, 9, 14},
      };
      for (final instrumento in permitidas.keys) {
        for (final modalidade in kModalidades.keys.where(
          (m) => m != 12 && m != 15,
        )) {
          expect(
            EditalRules.validarInstrumentoModalidade(
              tipoInstrumentoId: instrumento,
              modalidadeId: modalidade,
            ),
            permitidas[instrumento]!.contains(modalidade) ? isNull : isNotNull,
            reason: 'Instrumento $instrumento, modalidade $modalidade',
          );
        }
      }
    });

    test(
      'excepciona credenciamento e chamada pública sem reativar instrumento 4',
      () {
        expect(kTipoInstrumento.containsKey(4), isFalse);
        for (final modalidade in [12, 15]) {
          for (final instrumento in [1, 2, 3]) {
            expect(
              EditalRules.validarInstrumentoModalidade(
                tipoInstrumentoId: instrumento,
                modalidadeId: modalidade,
              ),
              isNull,
            );
          }
        }
      },
    );
  });

  group('datas de propostas', () {
    final abertura = DateTime(2026, 10, 27, 10);

    test('exige as duas datas nos instrumentos 1 e 2', () {
      for (final instrumento in [1, 2]) {
        expect(
          EditalRules.validarDataAbertura(
            tipoInstrumentoId: instrumento,
            dataAbertura: null,
          ),
          isNotNull,
        );
        expect(
          EditalRules.validarDataEncerramento(
            tipoInstrumentoId: instrumento,
            dataAbertura: abertura,
            dataEncerramento: null,
          ),
          isNotNull,
        );
      }
    });

    test(
      'instrumento 3 permite datas ausentes, mas respeita a ordem se informadas',
      () {
        expect(
          EditalRules.validarDataAbertura(
            tipoInstrumentoId: 3,
            dataAbertura: null,
          ),
          isNull,
        );
        expect(
          EditalRules.validarDataEncerramento(
            tipoInstrumentoId: 3,
            dataAbertura: null,
            dataEncerramento: null,
          ),
          isNull,
        );
        for (final instrumento in [1, 2, 3]) {
          for (final minutos in [-1, 0, 1]) {
            expect(
              EditalRules.validarDataEncerramento(
                tipoInstrumentoId: instrumento,
                dataAbertura: abertura,
                dataEncerramento: abertura.add(Duration(minutes: minutos)),
              ),
              minutos < 0 ? isNotNull : isNull,
            );
          }
        }
      },
    );
  });

  group('categoria dos itens', () {
    test('leilão exige material e categoria de bens móveis ou imóveis', () {
      for (final modalidade in [1, 13]) {
        for (final material in ['M', 'S']) {
          for (final categoria in [1, 2, 3, null]) {
            final erro = EditalRules.validarItem(
              modalidadeId: modalidade,
              item: {
                'numeroItem': 42,
                'materialOuServico': material,
                'itemCategoriaId': categoria,
              },
            );
            expect(
              erro,
              material == 'M' && (categoria == 1 || categoria == 2)
                  ? isNull
                  : contains('Item 42'),
            );
          }
        }
      }
    });

    test('demais modalidades exigem categoria 3 para material ou serviço', () {
      for (final modalidade in kModalidades.keys.where(
        (m) => m != 1 && m != 13,
      )) {
        for (final material in ['M', 'S']) {
          for (final categoria in [1, 2, 3]) {
            expect(
              EditalRules.validarItem(
                modalidadeId: modalidade,
                item: {
                  'numeroItem': 5,
                  'materialOuServico': material,
                  'itemCategoriaId': categoria,
                },
              ),
              categoria == 3 ? isNull : contains('Item 5'),
            );
          }
        }
      }
      expect(EditalRules.validarItem(modalidadeId: null, item: {}), isNull);
    });

    test('categoria é 3 fora de leilão e só 1 ou 2 em leilão', () {
      for (final atual in [1, 2, 3, null]) {
        expect(EditalRules.categoriaItem(modalidadeId: 6, atual: atual), 3);
        expect(EditalRules.categoriaItem(modalidadeId: null, atual: atual), 3);
        expect(
          EditalRules.categoriaItem(modalidadeId: 1, atual: atual),
          atual == 3 ? isNull : atual,
        );
      }
    });

    test('normalização ajusta todos os itens sem alterar a lista original', () {
      final itens = [
        {'numeroItem': 1, 'itemCategoriaId': 2},
        {'numeroItem': 2, 'itemCategoriaId': 3},
        {'numeroItem': 3},
      ];
      expect(
        EditalRules.normalizarCategorias(
          modalidadeId: 6,
          itens: itens,
        ).map((i) => i['itemCategoriaId']),
        [3, 3, 3],
      );
      final leilao = EditalRules.normalizarCategorias(
        modalidadeId: 13,
        itens: itens,
      );
      expect(leilao[0]['itemCategoriaId'], 2);
      expect(leilao[1].containsKey('itemCategoriaId'), isFalse);
      expect(leilao[2].containsKey('itemCategoriaId'), isFalse);
      expect(itens[1]['itemCategoriaId'], 3);
    });

    test('envio confere todos os itens importados e as datas', () {
      final documento = <String, dynamic>{
        'modalidadeId': 6,
        'tipoInstrumentoConvocatorioId': 1,
        'dataAberturaProposta': '2026-10-27T10:00:00',
        'dataEncerramentoProposta': '2026-10-27T11:00:00',
        'itensCompra': [
          {'numeroItem': 1, 'materialOuServico': 'S', 'itemCategoriaId': 3},
          {'numeroItem': 72, 'materialOuServico': 'M', 'itemCategoriaId': 2},
        ],
      };
      expect(EditalRules.validarEnvio(documento), contains('Item 72'));
      documento['itensCompra'] = [];
      expect(EditalRules.validarEnvio(documento), isNull);
      documento['dataEncerramentoProposta'] = '2026-10-27T09:59:00';
      expect(EditalRules.validarEnvio(documento), contains('anterior'));
      documento.remove('dataAberturaProposta');
      expect(EditalRules.validarEnvio(documento), contains('abertura'));
    });
  });
}
