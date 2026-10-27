/// Normaliza CPF/CNPJ e preserva a identificação de pessoa estrangeira.
String normalizarNiPessoa(String tipoPessoaId, String ni) {
  if (tipoPessoaId == 'PJ' || tipoPessoaId == 'PF') {
    return ni.replaceAll(RegExp(r'\D'), '');
  }
  return ni.trim();
}
