/// Regras condicionais do Edital conforme o Modelo da Fase IV 2026 v04.
abstract final class EditalRules {
  // O endpoint enviar-edital limita o PDF a 30 MB.
  static const limitePdfBytes = 30 * 1024 * 1024;

  static const _modalidadesPorInstrumento = <int, Set<int>>{
    1: {1, 2, 3, 4, 5, 6, 7, 13, 14, 16, 17, 18, 19, 997, 998, 999},
    2: {8, 14},
    3: {8, 9, 14},
  };

  static String? validarPdfObrigatorio({
    required int? modalidadeId,
    required bool temPdf,
  }) {
    if (!temPdf && modalidadeId != 9) {
      return 'Selecione o PDF do edital. O envio sem PDF só é permitido para inexigibilidade (modalidade 9).';
    }
    return null;
  }

  static bool exigeConfirmacaoSemPdf({
    required int? modalidadeId,
    required bool temPdf,
  }) => !temPdf && modalidadeId == 9;

  static String? validarArquivoPdf({
    required bool existe,
    required int tamanhoBytes,
  }) {
    if (!existe) {
      return 'O PDF selecionado não existe mais no disco. Selecione o arquivo novamente.';
    }
    if (tamanhoBytes > limitePdfBytes) {
      return 'O PDF ultrapassa o limite de 30 MB permitido pelo AUDESP.';
    }
    return null;
  }

  static String? validarInstrumentoModalidade({
    required int? tipoInstrumentoId,
    required int? modalidadeId,
  }) {
    if (tipoInstrumentoId == null || modalidadeId == null) return null;
    // Credenciamento e chamada pública não têm combinação utilizável na
    // tabela: o instrumento 4 foi removido do app e não deve ser reativado.
    if (modalidadeId == 12 || modalidadeId == 15) return null;
    if (!(_modalidadesPorInstrumento[tipoInstrumentoId]?.contains(
          modalidadeId,
        ) ??
        false)) {
      return 'A modalidade $modalidadeId não é permitida para o instrumento convocatório $tipoInstrumentoId.';
    }
    return null;
  }

  static String? validarDataAbertura({
    required int? tipoInstrumentoId,
    required DateTime? dataAbertura,
  }) {
    if ((tipoInstrumentoId == 1 || tipoInstrumentoId == 2) &&
        dataAbertura == null) {
      return 'Informe a abertura das propostas para instrumento tipo 1 ou 2.';
    }
    return null;
  }

  static String? validarDataEncerramento({
    required int? tipoInstrumentoId,
    required DateTime? dataAbertura,
    required DateTime? dataEncerramento,
  }) {
    if ((tipoInstrumentoId == 1 || tipoInstrumentoId == 2) &&
        dataEncerramento == null) {
      return 'Informe o encerramento das propostas para instrumento tipo 1 ou 2.';
    }
    if (dataAbertura != null &&
        dataEncerramento != null &&
        dataEncerramento.isBefore(dataAbertura)) {
      return 'O encerramento das propostas não pode ser anterior à abertura.';
    }
    return null;
  }

  static bool isLeilao(int? modalidadeId) =>
      modalidadeId == 1 || modalidadeId == 13;

  static String? validarItem({
    required int? modalidadeId,
    required Map<String, dynamic> item,
  }) {
    if (modalidadeId == null) return null;
    final numero = item['numeroItem'];
    final categoria = item['itemCategoriaId'];
    if (isLeilao(modalidadeId)) {
      if (item['materialOuServico'] != 'M') {
        return 'Item $numero: em leilão, o item deve ser material (M).';
      }
      if (categoria != 1 && categoria != 2) {
        return 'Item $numero: em leilão, a categoria deve ser Bens Imóveis (1) ou Bens Móveis (2).';
      }
    } else if (categoria != 3) {
      return 'Item $numero: para esta modalidade, a categoria deve ser Não se aplica (3).';
    }
    return null;
  }

  static String? validarEnvio(Map<String, dynamic> documento) {
    final instrumento = documento['tipoInstrumentoConvocatorioId'] as int?;
    final modalidade = documento['modalidadeId'] as int?;
    final abertura = DateTime.tryParse(
      documento['dataAberturaProposta'] as String? ?? '',
    );
    final encerramento = DateTime.tryParse(
      documento['dataEncerramentoProposta'] as String? ?? '',
    );
    final erro =
        validarInstrumentoModalidade(
          tipoInstrumentoId: instrumento,
          modalidadeId: modalidade,
        ) ??
        validarDataAbertura(
          tipoInstrumentoId: instrumento,
          dataAbertura: abertura,
        ) ??
        validarDataEncerramento(
          tipoInstrumentoId: instrumento,
          dataAbertura: abertura,
          dataEncerramento: encerramento,
        );
    if (erro != null) return erro;
    for (final item in documento['itensCompra'] as List<dynamic>? ?? []) {
      final erroItem = validarItem(modalidadeId: modalidade, item: item);
      if (erroItem != null) return erroItem;
    }
    return null;
  }
}
