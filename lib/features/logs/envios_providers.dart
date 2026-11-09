import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import 'domain/ultimo_envio.dart';

/// Envios registrados para um endpoint ([EnviosEndpoint]). AutoDispose para
/// recarregar ao voltar do formulário, onde o documento pode ter sido enviado
/// ou ter o status do protocolo atualizado.
final enviosProvider = FutureProvider.autoDispose.family<EnviosIndex, String>(
  (ref, endpoint) => ref.watch(apiLogsDaoProvider).listEnvios(endpoint),
);
