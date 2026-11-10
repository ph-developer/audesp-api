import 'package:audesp_api/core/constants/environments.dart';
import 'package:audesp_api/core/database/models/user.dart';
import 'package:audesp_api/core/database/models/ajuste.dart';
import 'package:audesp_api/core/database/models/ata.dart';
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
import '../pncp/pncp_fixtures.dart';
import '../pncp/pncp_ata_fixtures.dart';
import 'pendencias_fixtures.dart';

class _AmbienteTeste extends EnvironmentNotifier {
  @override
  Environment build() => Environment.piloto;

  @override
  Future<void> setEnvironment(Environment env) async => state = env;
}

void main() {
  test(
    'ata liberada reage ao ambiente, à dispensa, ao cancelamento e ao rascunho salvo',
    () async {
      final processo = processoFixture(
        codigo: '49576416000141-1-000001/2026',
        semPncp: false,
        srp: true,
        licitacoes: [licitacaoFixture(1, status: 'sent')],
      );
      final atas = <Ata>[];
      var ata = ataPncpFixture();
      final container = ProviderContainer(
        overrides: [
          environmentProvider.overrideWith(_AmbienteTeste.new),
          documentosProcessoProvider.overrideWith(
            (ref) async => DocumentosProcesso(
              editais: [processo.edital],
              licitacoes: processo.licitacoes,
              atas: atas,
            ),
          ),
          enviosProvider.overrideWith(
            (ref, endpoint) async => EnviosIndex([
              if (endpoint == EnviosEndpoint.edital)
                envioFixture(processo.edital, situacao: 'Armazenado'),
              if (endpoint == EnviosEndpoint.licitacao)
                envioFixture(
                  processo.licitacoes.single,
                  situacao: 'Armazenado',
                ),
            ]),
          ),
          pncpAtasProvider.overrideWith((ref) async => [ata]),
          pncpComprasProvider.overrideWith((ref) async => const []),
          pncpContratosProvider.overrideWith(
            (ref) => throw StateError('Sem permissão de Ajuste'),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(localSessionProvider.notifier)
          .login(usuarioFixture(permissions: AppPermissions.ata));
      final sub = container.listen(pendenciasContagemProvider, (_, _) {});
      addTearDown(sub.close);
      Future<int> contagem() async =>
          (await container.read(pendenciasContagemProvider.future))['/ata']!;
      expect(await contagem(), 1);
      await container
          .read(environmentProvider.notifier)
          .setEnvironment(Environment.oficial);
      expect(await contagem(), 0);
      expect(
        (await container.read(pendenciasModulosProvider.future)).atasBloqueadas,
        hasLength(1),
      );
      await container
          .read(environmentProvider.notifier)
          .setEnvironment(Environment.piloto);
      expect(await contagem(), 1);
      ata = ataPncpFixture(dispensada: true);
      container.invalidate(pncpAtasProvider);
      expect(await contagem(), 0);
      expect(
        (await container.read(
          pendenciasModulosProvider.future,
        )).atasDispensadas,
        hasLength(1),
      );
      ata = ataPncpFixture(alteracoes: {'cancelado': true});
      container.invalidate(pncpAtasProvider);
      expect(await contagem(), 0);
      expect(
        (await container.read(pendenciasModulosProvider.future)).atasBloqueadas,
        isEmpty,
      );
      ata = ataPncpFixture();
      container.invalidate(pncpAtasProvider);
      expect(await contagem(), 1);
      atas.add(ataFixture(4, codigo: ata.numeroControle));
      container.invalidate(documentosProcessoProvider);
      expect(await contagem(), 0);
      expect(
        (await container.read(pendenciasModulosProvider.future)).atasPncp,
        isEmpty,
      );
    },
  );

  test(
    'contrato liberado reage ao ambiente, à dispensa e ao ajuste salvo',
    () async {
      final processo = processoFixture(
        codigo: '46395000000139-1-000352/2026',
        semPncp: false,
        licitacoes: [licitacaoFixture(1, status: 'sent')],
      );
      final ajustes = <Ajuste>[];
      var contrato = contratoPncpFixture();
      final container = ProviderContainer(
        overrides: [
          environmentProvider.overrideWith(_AmbienteTeste.new),
          documentosProcessoProvider.overrideWith(
            (ref) async => DocumentosProcesso(
              editais: [processo.edital],
              licitacoes: processo.licitacoes,
              ajustes: ajustes,
            ),
          ),
          enviosProvider.overrideWith(
            (ref, endpoint) async => EnviosIndex([
              if (endpoint == EnviosEndpoint.edital)
                envioFixture(processo.edital, situacao: 'Armazenado'),
              if (endpoint == EnviosEndpoint.licitacao)
                envioFixture(
                  processo.licitacoes.single,
                  situacao: 'Armazenado',
                ),
            ]),
          ),
          pncpConfigProvider.overrideWith(
            (ref) async => const PncpConfig(cnpj: '46395000000139'),
          ),
          pncpContratosProvider.overrideWith((ref) async => [contrato]),
          pncpComprasProvider.overrideWith((ref) async => const []),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(localSessionProvider.notifier)
          .login(usuarioFixture(permissions: AppPermissions.ajuste));
      final sub = container.listen(pendenciasContagemProvider, (_, _) {});
      addTearDown(sub.close);
      Future<int> contagem() async =>
          (await container.read(pendenciasContagemProvider.future))['/ajuste']!;
      expect(await contagem(), 1);
      await container
          .read(environmentProvider.notifier)
          .setEnvironment(Environment.oficial);
      expect(await contagem(), 0);
      expect(
        (await container.read(
          pendenciasModulosProvider.future,
        )).contratosBloqueados,
        hasLength(1),
      );
      await container
          .read(environmentProvider.notifier)
          .setEnvironment(Environment.piloto);
      expect(await contagem(), 1);
      contrato = contratoPncpFixture(dispensado: true);
      container.invalidate(pncpContratosProvider);
      expect(await contagem(), 0);
      expect(
        (await container.read(
          pendenciasModulosProvider.future,
        )).contratosDispensados,
        hasLength(1),
      );
      contrato = contratoPncpFixture();
      container.invalidate(pncpContratosProvider);
      expect(await contagem(), 1);
      ajustes.add(ajusteFixture(4, codigo: contrato.numeroControle));
      container.invalidate(documentosProcessoProvider);
      expect(await contagem(), 0);
    },
  );

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
          // Compras dão a data de publicação de atas e contratos.
          pncpComprasProvider.overrideWith((ref) async => const []),
          pncpContratosProvider.overrideWith((ref) async => []),
          pncpConfigProvider.overrideWith((ref) async => const PncpConfig()),
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
