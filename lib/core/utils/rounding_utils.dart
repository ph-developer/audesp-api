import 'dart:math' as math;

double arredondarParaCima(double valor, int casasDecimais) {
  final fator = math.pow(10, casasDecimais);
  return (valor * fator).ceilToDouble() / fator;
}
