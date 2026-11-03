import 'package:audesp_api/features/licitacao/domain/licitacao_condutor.dart';
import 'package:audesp_api/features/licitacao/models/condutor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ana = Condutor(id: 1, nome: 'Ana', cpf: '52998224725');
  const bruno = Condutor(id: 2, nome: 'Bruno', cpf: '11144477735');

  group('CondutorRules.cpfValido', () {
    test(
      'aceita CPF com dígitos verificadores corretos, com ou sem máscara',
      () {
        expect(CondutorRules.cpfValido('52998224725'), isTrue);
        expect(CondutorRules.cpfValido('111.444.777-35'), isTrue);
      },
    );

    test('rejeita dígito verificador errado, tamanho errado e repetição', () {
      expect(CondutorRules.cpfValido('52998224724'), isFalse);
      expect(CondutorRules.cpfValido('5299822472'), isFalse);
      expect(CondutorRules.cpfValido('11111111111'), isFalse);
    });
  });

  group('CondutorRules.validarCpf', () {
    test('exige CPF válido e ainda não cadastrado', () {
      expect(CondutorRules.validarCpf('', const []), 'Obrigatório');
      expect(CondutorRules.validarCpf('123', const []), 'CPF inválido');
      expect(
        CondutorRules.validarCpf('529.982.247-25', const [ana]),
        'CPF já cadastrado',
      );
      expect(CondutorRules.validarCpf('529.982.247-25', const [bruno]), isNull);
    });
  });

  test('formatarCpf aplica a máscara apenas a 11 dígitos', () {
    expect(CondutorRules.formatarCpf('52998224725'), '529.982.247-25');
    expect(CondutorRules.formatarCpf('123'), '123');
  });

  group('CondutorRules.aplicarSelecao', () {
    test('mantém CPFs fora do cadastro e adiciona os novos ao final', () {
      final cpfs = CondutorRules.aplicarSelecao(
        atuais: ['99999999999', ana.cpf],
        cadastrados: const [ana, bruno],
        selecionados: {ana.cpf, bruno.cpf},
      );
      expect(cpfs, ['99999999999', ana.cpf, bruno.cpf]);
    });

    test('remove os CPFs do cadastro desmarcados', () {
      final cpfs = CondutorRules.aplicarSelecao(
        atuais: [ana.cpf, '99999999999'],
        cadastrados: const [ana, bruno],
        selecionados: {'99999999999'},
      );
      expect(cpfs, ['99999999999']);
    });
  });
}
