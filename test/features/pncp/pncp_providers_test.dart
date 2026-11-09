import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/database/daos/pncp_compras_dao.dart';
import 'package:audesp_api/core/database/daos/pncp_contratos_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/features/pncp/domain/pncp_varredura.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/pncp/services/pncp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pncp_fixtures.dart';

const _cnpj = '46395000000139';

class _Settings implements AppSettingsDao {
  final valores = <String, String>{
    SettingsKeys.pncpCnpj: _cnpj,
    SettingsKeys.pncpConsultaAutomatica: '1',
  };

  @override
  Future<String?> get(String key) async => valores[key];
  @override
  Future<void> set(String key, String value) async => valores[key] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Compras implements PncpComprasDao {
  final compras = <PncpCompra>[];
  @override
  Future<List<PncpCompra>> listAll() async => compras;
  @override
  Future<bool> upsert(PncpCompra compra) async {
    compras.add(compra);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Contratos implements PncpContratosDao {
  final contratos = <PncpContrato>[];
  @override
  Future<List<PncpContrato>> listAll() async => contratos;
  @override
  Future<bool> upsert(PncpContrato contrato) async {
    contratos.add(contrato);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servico extends PncpService {
  final chamadas = <String>[];
  bool falharContrato = false;
  bool semFim = false;

  @override
  Future<SequenciaPncp> consultarCompra(
    String cnpj,
    int ano,
    int sequencial, {
    bool novaTentativa = true,
  }) async {
    chamadas.add('compra $ano/$sequencial');
    return sequencial == 1 || semFim
        ? CompraEncontrada(
            compraPncpJson(cnpj: cnpj, ano: ano, sequencial: sequencial),
          )
        : const SequenciaInexistente();
  }

  @override
  Future<SequenciaPncp> consultarContrato(
    String cnpj,
    int ano,
    int sequencial, {
    bool novaTentativa = true,
  }) async {
    chamadas.add('contrato $ano/$sequencial');
    if (falharContrato && sequencial == 2) {
      throw const PncpException('Falha nos contratos');
    }
    return sequencial <= 2 || semFim
        ? ContratoEncontrado(
            contratoPncpJson(cnpj: cnpj, ano: ano, sequencial: sequencial),
          )
        : const SequenciaInexistente();
  }
}

void main() {
  late _Settings settings;
  late _Compras compras;
  late _Contratos contratos;
  late _Servico servico;
  late ProviderContainer container;
  final ano = DateTime.now().year;

  setUp(() {
    settings = _Settings();
    compras = _Compras();
    contratos = _Contratos();
    servico = _Servico();
    container = ProviderContainer(
      overrides: [
        appSettingsDaoProvider.overrideWithValue(settings),
        pncpComprasDaoProvider.overrideWithValue(compras),
        pncpContratosDaoProvider.overrideWithValue(contratos),
        pncpServiceProvider.overrideWithValue(servico),
      ],
    );
  });
  tearDown(() => container.dispose());

  test(
    'mesma rodada consulta compras antes de contratos, com cursores distintos',
    () async {
      final resultado = await container
          .read(pncpConsultaProvider.notifier)
          .consultar();
      expect(resultado, (compras: 1, contratos: 2));
      expect(servico.chamadas.take(4), [
        for (var i = 1; i <= 4; i++) 'compra $ano/$i',
      ]);
      expect(servico.chamadas.skip(4).first, 'contrato $ano/1');
      expect(settings.valores[SettingsKeys.pncpSequencia(_cnpj, ano)], '1');
      expect(
        settings.valores[SettingsKeys.pncpContratoSequencia(_cnpj, ano)],
        '2',
      );
      expect(await container.read(pncpComprasProvider.future), hasLength(1));
      expect(await container.read(pncpContratosProvider.future), hasLength(2));
      expect(container.read(pncpConsultaProvider).erro, isNull);
    },
  );

  test(
    'erro no contrato mantém compras e cursores e a próxima rodada continua',
    () async {
      final sub = container.listen(pncpContratosProvider, (_, _) {});
      addTearDown(sub.close);
      expect(await container.read(pncpContratosProvider.future), isEmpty);
      servico.falharContrato = true;
      await expectLater(
        container.read(pncpConsultaProvider.notifier).consultar(),
        throwsA(isA<PncpException>()),
      );
      expect(compras.compras, hasLength(1));
      expect(contratos.contratos, hasLength(1));
      expect(settings.valores[SettingsKeys.pncpSequencia(_cnpj, ano)], '1');
      expect(
        settings.valores[SettingsKeys.pncpContratoSequencia(_cnpj, ano)],
        '1',
      );
      expect(container.read(pncpConsultaProvider).erro, 'Falha nos contratos');
      expect(await container.read(pncpContratosProvider.future), hasLength(1));
      servico.falharContrato = false;
      servico.chamadas.clear();
      expect(await container.read(pncpConsultaProvider.notifier).consultar(), (
        compras: 0,
        contratos: 1,
      ));
      expect(servico.chamadas.first, 'compra $ano/2');
      expect(
        servico.chamadas.where((c) => c.startsWith('contrato')).first,
        'contrato $ano/2',
      );
    },
  );

  test(
    '50 requisições de compras não consomem o limite dos contratos',
    () async {
      servico.semFim = true;
      expect(await container.read(pncpConsultaProvider.notifier).consultar(), (
        compras: 50,
        contratos: 50,
      ));
      expect(
        servico.chamadas.where((c) => c.startsWith('compra')),
        hasLength(50),
      );
      expect(
        servico.chamadas.where((c) => c.startsWith('contrato')),
        hasLength(50),
      );
    },
  );

  test(
    'consulta automática usa a última rodada compartilhada e evita sobreposição local',
    () async {
      final notifier = container.read(pncpConsultaProvider.notifier);
      final primeira = notifier.consultar(automatica: true);
      final segunda = notifier.consultar(automatica: true);
      expect(await primeira, (compras: 1, contratos: 2));
      expect(await segunda, isNull);
      servico.chamadas.clear();
      expect(await notifier.consultar(automatica: true), isNull);
      expect(servico.chamadas, isEmpty);
      expect(settings.valores[SettingsKeys.pncpUltimaConsultaEm], isNotNull);
    },
  );
}
