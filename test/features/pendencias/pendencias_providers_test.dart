import 'package:audesp_api/core/constants/environments.dart';
import 'package:audesp_api/core/database/models/user.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/logs/domain/ultimo_envio.dart';
import 'package:audesp_api/features/logs/envios_providers.dart';
import 'package:audesp_api/features/pendencias/pendencias_providers.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../processo/processo_fixtures.dart';
import 'pendencias_fixtures.dart';

class _AmbienteTeste extends EnvironmentNotifier {
  @override
  Environment build() => Environment.piloto;

  @override
  Future<void> setEnvironment(Environment env) async => state = env;
}

void main() {
  test(
    'contagens incluem adesão sem processo e reagem a envios e ambiente',
    () async {
      final ajuste = ajusteFixture(9, editalId: null);
      final docs = DocumentosProcesso(ajustes: [ajuste]);
      var situacao = 'Recebido';
      final container = ProviderContainer(
        overrides: [
          environmentProvider.overrideWith(_AmbienteTeste.new),
          documentosProcessoProvider.overrideWith((ref) async => docs),
          enviosProvider.overrideWith(
            (ref, endpoint) async => EnviosIndex([
              if (endpoint == EnviosEndpoint.ajuste)
                envioFixture(ajuste, situacao: situacao),
            ]),
          ),
          // Sem permissão para Edital, o PNCP nem é consultado.
          pncpComprasProvider.overrideWith(
            (ref) => throw StateError('PNCP indevido'),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(localSessionProvider.notifier)
          .login(usuarioFixture(permissions: AppPermissions.ajuste));
      final subscription = container.listen(
        pendenciasContagemProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(
        (await container.read(pendenciasContagemProvider.future))['/ajuste'],
        1,
      );

      await container
          .read(environmentProvider.notifier)
          .setEnvironment(Environment.oficial);
      expect(
        (await container.read(pendenciasContagemProvider.future))['/ajuste'],
        0,
      );
      await container
          .read(environmentProvider.notifier)
          .setEnvironment(Environment.piloto);
      expect(
        (await container.read(pendenciasContagemProvider.future))['/ajuste'],
        1,
      );

      situacao = 'Armazenado';
      container.invalidate(enviosProvider);
      expect(
        (await container.read(pendenciasContagemProvider.future))['/ajuste'],
        0,
      );

      situacao = 'Rejeitado';
      container.invalidate(enviosProvider);
      expect(
        (await container.read(pendenciasContagemProvider.future))['/ajuste'],
        1,
      );
      container.read(localSessionProvider.notifier).logout();
      expect(
        (await container.read(pendenciasContagemProvider.future)).values,
        everyElement(0),
      );
    },
  );
}
