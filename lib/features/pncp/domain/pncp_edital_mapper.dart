import 'package:intl/intl.dart';

/// Converte uma compra do PNCP no cabeçalho de um edital AUDESP.
///
/// Os itens não são trazidos: continuam vindo da estimativa ou da planilha.
/// Os códigos de instrumento, modalidade, modo de disputa e amparo legal do
/// PNCP são os mesmos usados pelo AUDESP.
abstract final class PncpEditalMapper {
  static Map<String, dynamic> documento(Map<String, dynamic> compra) {
    final controle = (compra['numeroControlePNCP']?.toString() ?? '')
        .replaceAll(RegExp(r'\D'), '');
    final publicacao = DateTime.tryParse(
      compra['dataPublicacaoPncp']?.toString() ?? '',
    );
    final abertura = DateTime.tryParse(
      compra['dataAberturaProposta']?.toString() ?? '',
    );
    final encerramento = DateTime.tryParse(
      compra['dataEncerramentoProposta']?.toString() ?? '',
    );
    final dataHora = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    final amparo = compra['amparoLegal'] as Map<String, dynamic>?;

    return {
      'descritor': {'codigoEdital': controle, 'retificacao': false},
      'publicidade': {
        'houvePublicacao': publicacao != null,
        if (publicacao != null)
          'publicacoes': [
            {
              'dataPublicacao': DateFormat('yyyy-MM-dd').format(publicacao),
              'veiculoPublicacao': 5,
              'idContratacaoPNCP': controle,
            },
          ],
      },
      'tipoInstrumentoConvocatorioId': _int(
        compra['tipoInstrumentoConvocatorioCodigo'],
      ),
      'modalidadeId': _int(compra['modalidadeId']),
      'modoDisputaId': _int(compra['modoDisputaId']),
      'numeroCompra': _texto(compra['numeroCompra']),
      'anoCompra': _int(compra['anoCompra']),
      'numeroProcesso': _texto(compra['processo']),
      'objetoCompra': _texto(compra['objetoCompra']),
      if (_texto(compra['informacaoComplementar']).isNotEmpty)
        'informacaoComplementar': _texto(compra['informacaoComplementar']),
      'srp': compra['srp'] == true,
      'amparoLegalId': _int(amparo?['codigo']),
      if (abertura != null) 'dataAberturaProposta': dataHora.format(abertura),
      if (encerramento != null)
        'dataEncerramentoProposta': dataHora.format(encerramento),
      if (_texto(compra['linkSistemaOrigem']).isNotEmpty)
        'linkSistemaOrigem': _texto(compra['linkSistemaOrigem']),
      if (_texto(compra['justificativaPresencial']).isNotEmpty)
        'justificativaPresencial': _texto(compra['justificativaPresencial']),
      'itensCompra': <Map<String, dynamic>>[],
    };
  }

  static int? _int(Object? v) => (v as num?)?.toInt();

  static String _texto(Object? v) => v?.toString().trim() ?? '';
}
