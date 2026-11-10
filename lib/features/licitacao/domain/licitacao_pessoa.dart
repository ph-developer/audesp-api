/// Normaliza CPF/CNPJ e preserva a identificação de pessoa estrangeira.
String normalizarNiPessoa(String tipoPessoaId, String ni) {
  return switch (tipoPessoaId) {
    'PJ' => ni.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase(),
    'PF' => ni.replaceAll(RegExp(r'\D'), ''),
    _ => ni.trim(),
  };
}
