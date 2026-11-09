import 'package:go_router/go_router.dart';

import '../database/models/user.dart';
import 'app_modules.dart';

const homePendenciasTimeout = Duration(seconds: 2);

/// Refina o destino inicial sem atrasar o login nem interromper uma navegação
/// feita pelo usuário enquanto as pendências carregavam.
Future<void> navegarParaPendencias({
  required GoRouter router,
  required User user,
  required Future<Map<String, int>> contagens,
  required bool Function() sessaoAtual,
  Duration timeout = homePendenciasTimeout,
}) async {
  final fallback = homeLocationFor(user);
  var saiuDoInicio = false;
  void observarRota() {
    final path = router.routeInformationProvider.value.uri.path;
    if (path != fallback && path != '/login') saiuDoInicio = true;
  }

  observarRota();
  router.routeInformationProvider.addListener(observarRota);
  try {
    final resultado = await contagens.timeout(timeout);
    if (!sessaoAtual() || saiuDoInicio) return;
    final destino = homeLocationComPendencias(user, resultado);
    if (destino != fallback) router.go(destino);
  } catch (_) {
    // Erro ou demora na consulta mantém o módulo inicial síncrono.
  } finally {
    router.routeInformationProvider.removeListener(observarRota);
  }
}
