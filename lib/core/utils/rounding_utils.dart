import 'dart:math' as math;

double arredondarParaCima(double valor, int casasDecimais) {
  final fator = math.pow(10, casasDecimais);
  final scaled = valor * fator;

  // Se o valor escalado estiver dentro de epsilon de um inteiro,
  // ancora nele antes de aplicar o ceil — isso absorve resíduos de
  // ponto flutuante (ex: 2865.6000000000001 * 100 = 286560.0000000001)
  // sem afetar valores genuinamente acima do inteiro.
  const epsilon = 1e-9;
  final nearest = scaled.roundToDouble();
  if ((scaled - nearest).abs() < epsilon) return nearest / fator;

  return scaled.ceilToDouble() / fator;
}
