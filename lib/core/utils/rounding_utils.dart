import 'dart:math' as math;

double arredondarParaCima(double valor, int casasDecimais) {
  final fator = math.pow(10, casasDecimais);
  final scaled = valor * fator;

  // O erro de representação cresce com a magnitude do valor escalado.
  // Dois epsilons de double cobrem as multiplicações do total e do fator
  // decimal; a tolerância absoluta preserva o tratamento de valores menores.
  const epsilonAbsoluto = 1e-9;
  const epsilonDouble = 2.220446049250313e-16;
  final tolerancia = math.max(
    epsilonAbsoluto,
    scaled.abs() * epsilonDouble * 2,
  );
  final nearest = scaled.roundToDouble();
  if ((scaled - nearest).abs() <= tolerancia) return nearest / fator;

  return scaled.ceilToDouble() / fator;
}
