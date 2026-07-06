class FornecedorPredefinido {
  final String razaoSocial;
  final String cnpj;
  final bool bancoDePrecos;

  const FornecedorPredefinido({
    required this.razaoSocial,
    required this.cnpj,
    this.bancoDePrecos = false,
  });
}

const fornecedoresPredefinidos = [
  FornecedorPredefinido(
    razaoSocial: 'NP Tecnologia e Gestão de Dados Ltda',
    cnpj: '07.797.967/0001-95',
    bancoDePrecos: true,
  ),
];
