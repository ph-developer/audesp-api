/// Valor mínimo, em UFESP, a partir do qual o envio ao AUDESP é obrigatório.
class UfespConfig {
  static const valorPadrao = 38.42;
  static const quantidadePadrao = 2500;

  final double valorUfesp;
  final int quantidadeMinima;

  const UfespConfig({
    this.valorUfesp = valorPadrao,
    this.quantidadeMinima = quantidadePadrao,
  });

  factory UfespConfig.fromSettings({String? valor, String? quantidade}) =>
      UfespConfig(
        valorUfesp:
            double.tryParse(valor?.replaceAll(',', '.') ?? '') ?? valorPadrao,
        quantidadeMinima: int.tryParse(quantidade ?? '') ?? quantidadePadrao,
      );

  double get limite => valorUfesp * quantidadeMinima;

  /// false só quando há valor estimado e ele fica abaixo do limite; sem
  /// valor (edital ainda sem itens) não se sabe, então não indica nada.
  bool envioObrigatorio(double? valorEstimado) =>
      valorEstimado == null || valorEstimado <= 0 || valorEstimado >= limite;
}
