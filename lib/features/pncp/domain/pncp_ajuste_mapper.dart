import 'package:intl/intl.dart';

import '../../ajuste/domain/ajuste_documento.dart';

import '../../ajuste/domain/ajuste_domain.dart';
import '../../licitacao/domain/licitacao_pessoa.dart';

/// Cabeçalho do Ajuste a partir do contrato do PNCP, sem inventar itens.
abstract final class PncpAjusteMapper {
  static Map<String, dynamic> documento(
    Map<String, dynamic> contrato, {
    required bool adesaoParticipacao,
    String? codigoEdital,
  }) {
    final compra = _digitos(contrato['numeroControlePncpCompra']);
    final tipoPessoa = _texto(contrato['tipoPessoa']);
    final tipoContrato = _inteiro(contrato['tipoContrato']?['id']);
    final categoria = _inteiro(contrato['categoriaProcesso']?['id']);
    final ano = _inteiro(contrato['anoContrato']);
    final parcelas = _inteiro(contrato['numeroParcelas']);

    final documento = <String, dynamic>{
      'descritor': {
        'codigoContrato': _digitos(contrato['numeroControlePNCP']),
        'codigoEdital': adesaoParticipacao
            ? compra
            : codigoEdital?.trim() ?? compra,
        'adesaoParticipacao': adesaoParticipacao,
        'retificacao': false,
      },
      'itens': <int>[],
      if (ano != null && ano >= 1970 && ano <= 2099) 'anoContrato': ano,
      if (kTipoPessoaFornecedor.containsKey(tipoPessoa))
        'tipoPessoaFornecedor': tipoPessoa,
      if (_texto(contrato['niFornecedor']).isNotEmpty)
        'niFornecedor': normalizarNiPessoa(
          tipoPessoa,
          _texto(contrato['niFornecedor']),
        ),
      if (contrato['receita'] is bool) 'receita': contrato['receita'],
      if (parcelas != null && parcelas >= 1) 'numeroParcelas': parcelas,
      // Tipo e categoria são domínios PNCP no AUDESP (ajuste_domain.dart).
      // Manual PNCP, seções 5.9/5.11: só traz os códigos aceitos pelo schema
      // ajuste-20261015; códigos exclusivos do PNCP ficam para revisão manual.
      // https://www.gov.br/pncp/pt-br/central-de-conteudo/manuais/versoes-anteriores/manualdeintegrao-pncpverso2-3-0.pdf
      if (kTipoContrato.containsKey(tipoContrato))
        'tipoContratoId': tipoContrato,
      if (kCategoriaProcesso.containsKey(categoria))
        'categoriaProcessoId': categoria,
    };
    for (final campo in [
      'numeroContratoEmpenho',
      'processo',
      'nomeRazaoSocialFornecedor',
      'objetoContrato',
    ]) {
      final valor = _texto(contrato[campo]);
      if (valor.isNotEmpty) documento[campo] = valor;
    }
    for (final campo in [
      'valorInicial',
      'valorParcela',
      'valorGlobal',
      'valorAcumulado',
    ]) {
      final valor = contrato[campo];
      if (valor is num && valor.isFinite) documento[campo] = valor;
    }
    for (final (campo, destino) in [
      ('dataAssinatura', 'dataAssinatura'),
      ('dataVigenciaInicio', AjusteDocumento.campoVigenciaInicio),
      ('dataVigenciaFim', 'dataVigenciaFim'),
    ]) {
      final data = DateTime.tryParse(_texto(contrato[campo]));
      if (data != null) {
        documento[destino] = DateFormat('yyyy-MM-dd').format(data);
      }
    }
    // Não deduz tipoObjetoContrato, fontes, despesas, unidade, vigência em
    // meses, dados da gerenciadora ou itens a partir do texto ou de valores.
    return documento;
  }

  static int? _inteiro(Object? valor) =>
      valor is num && valor.isFinite && valor == valor.toInt()
      ? valor.toInt()
      : null;

  static String _texto(Object? valor) => valor?.toString().trim() ?? '';

  static String _digitos(Object? valor) =>
      _texto(valor).replaceAll(RegExp(r'\D'), '');
}
