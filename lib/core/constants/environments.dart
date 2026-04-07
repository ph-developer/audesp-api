import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ambientes disponíveis para comunicação com a API AUDESP.
enum Environment { piloto, oficial }

extension EnvironmentExtension on Environment {
  String get label => switch (this) {
        Environment.piloto => 'Piloto',
        Environment.oficial => 'Oficial',
      };

  String get baseUrl => switch (this) {
        Environment.piloto => 'https://audesp-piloto.tce.sp.gov.br',
        Environment.oficial => 'https://audesp.tce.sp.gov.br',
      };
}

/// Provider global do ambiente ativo. Pode ser alterado em runtime via
/// [EnvironmentNotifier].
final environmentProvider =
    StateNotifierProvider<EnvironmentNotifier, Environment>(
  (ref) => EnvironmentNotifier(),
);

class EnvironmentNotifier extends StateNotifier<Environment> {
  EnvironmentNotifier() : super(Environment.piloto);

  void setEnvironment(Environment env) => state = env;
}
