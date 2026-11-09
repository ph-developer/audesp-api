import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/database/daos/pncp_compras_dao.dart';
import 'package:audesp_api/core/database/daos/pncp_contratos_dao.dart';
import 'package:audesp_api/core/database/daos/pncp_atas_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/features/pncp/domain/pncp_varredura.dart';
import 'package:audesp_api/features/pncp/domain/pncp_atas_varredura.dart';
import 'package:audesp_api/features/pncp/pncp_providers.dart';
import 'package:audesp_api/features/pncp/services/pncp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pncp_fixtures.dart';
import 'pncp_ata_fixtures.dart';

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

class _Atas implements PncpAtasDao {
  final atas = <String, PncpAta>{};
  @override
  Future<List<PncpAta>> listAll() async => atas.values.toList();
  @override
  Future<bool> upsert(PncpAta ata) async {
    final nova = !atas.containsKey(ata.numeroControle);
    atas[ata.numeroControle] = ata;
    return nova;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Servico extends PncpService {
  final chamadas = <String>[];
  bool falharContrato = false;
  bool semFim = false;
  bool falharAta = false;
  bool falharAtualizacao = false;
  DateTime? inicioAtualizacao;

  @override
  Future<PaginaAtasPncp> consultarAtasCompra(
    String cnpj,
    int ano,
    int seq,
    int pagina,
  ) async {
    chamadas.add('ata $ano/$seq página $pagina');
    if (falharAta && seq == 2) throw const PncpException('Falha nas atas');
    return seq == 1 || semFim
        ? PaginaAtasPncp(
            dados: [
              ataPncpJson(cnpj: cnpj, anoCompra: ano, sequencialCompra: seq),
            ],
          )
        : const PaginaAtasPncp();
  }

  @override
  Future<PaginaAtasPncp> consultarAtasAtualizadas(
    String cnpj,
    DateTime inicio,
    DateTime fim,
    int pagina,
  ) async {
    chamadas.add('atas atualizadas');
    inicioAtualizacao = inicio;
    if (falharAtualizacao) throw const PncpException('Falha nas atualizações');
    return PaginaAtasPncp(
      dados: [
        for (final seq in [1, 2])
          ataPncpJson(
            cnpj: cnpj,
            anoCompra: fim.year,
            atualizacao: true,
            sequencialAta: seq,
          ),
      ],
    );
  }

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
  late _Atas atas;
  late _Servico servico;
  late ProviderContainer container;
  final ano = DateTime.now().year;

  setUp(() {
    settings = _Settings();
    compras = _Compras();
    contratos = _Contratos();
    atas = _Atas();
    servico = _Servico();
    container = ProviderContainer(
      overrides: [
        appSettingsDaoProvider.overrideWithValue(settings),
        pncpComprasDaoProvider.overrideWithValue(compras),
        pncpContratosDaoProvider.overrideWithValue(contratos),
        pncpAtasDaoProvider.overrideWithValue(atas),
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
      expect(resultado, (compras: 1, contratos: 2, atas: 2));
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
      expect(await container.read(pncpAtasProvider.future), hasLength(2));
      expect(servico.chamadas.skip(9).first, 'ata $ano/1 página 1');
      expect(servico.chamadas.last, 'atas atualizadas');
      expect(
        settings.valores[SettingsKeys.pncpAtaCompraSequencia(_cnpj, ano)],
        '1',
      );
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
        atas: 2,
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
        atas: 51,
      ));
      expect(
        servico.chamadas.where((c) => c.startsWith('compra')),
        hasLength(50),
      );
      expect(
        servico.chamadas.where((c) => c.startsWith('contrato')),
        hasLength(50),
      );
      expect(
        servico.chamadas.where((c) => c.startsWith('ata ')),
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
      expect(await primeira, (compras: 1, contratos: 2, atas: 2));
      expect(await segunda, isNull);
      servico.chamadas.clear();
      expect(await notifier.consultar(automatica: true), isNull);
      expect(servico.chamadas, isEmpty);
      expect(settings.valores[SettingsKeys.pncpUltimaConsultaEm], isNotNull);
    },
  );

  test(
    'falha nas atas mantém compras, contratos e compras já lidas; retoma cursor',
    () async {
      settings.valores[SettingsKeys.pncpSequencia(_cnpj, ano)] = '2';
      servico.falharAta = true;
      await expectLater(
        container.read(pncpConsultaProvider.notifier).consultar(),
        throwsA(isA<PncpException>()),
      );
      expect(contratos.contratos, hasLength(2));
      expect(atas.atas, hasLength(1));
      expect(settings.valores[SettingsKeys.pncpSequencia(_cnpj, ano)], '2');
      expect(
        settings.valores[SettingsKeys.pncpContratoSequencia(_cnpj, ano)],
        '2',
      );
      expect(
        settings.valores[SettingsKeys.pncpAtaCompraSequencia(_cnpj, ano)],
        '1',
      );
      expect(settings.valores[SettingsKeys.pncpAtasAtualizadasAte], isNull);
      expect(container.read(pncpConsultaProvider).erro, 'Falha nas atas');
      expect(await container.read(pncpAtasProvider.future), hasLength(1));
      servico.falharAta = false;
      servico.chamadas.clear();
      expect(
        (await container.read(pncpConsultaProvider.notifier).consultar())!.atas,
        1,
      );
      expect(
        servico.chamadas.where((c) => c.startsWith('ata ')).single,
        'ata $ano/2 página 1',
      );
      expect(
        settings.valores[SettingsKeys.pncpAtaCompraSequencia(_cnpj, ano)],
        '2',
      );
    },
  );

  test(
    'falha nas atualizações preserva marcador anterior e dados da varredura',
    () async {
      settings.valores[SettingsKeys.pncpAtasAtualizadasAte] = '$ano-02-12';
      servico.falharAtualizacao = true;
      await expectLater(
        container.read(pncpConsultaProvider.notifier).consultar(),
        throwsA(isA<PncpException>()),
      );
      expect(compras.compras, hasLength(1));
      expect(contratos.contratos, hasLength(2));
      expect(atas.atas, hasLength(1));
      expect(
        settings.valores[SettingsKeys.pncpAtasAtualizadasAte],
        '$ano-02-12',
      );
      expect(
        container.read(pncpConsultaProvider).erro,
        'Falha nas atualizações',
      );
    },
  );

  test(
    'mudança de CNPJ reinicia janela por data e filtra atas da configuração anterior',
    () async {
      settings.valores[SettingsKeys.pncpAtasAtualizadasAte] = '$ano-11-09';
      settings.valores[SettingsKeys.pncpAtasAtualizadasCnpj] = '49576416000141';
      await atas.upsert(ataPncpFixture());
      await container.read(pncpConsultaProvider.notifier).consultar();
      expect(servico.inicioAtualizacao, DateTime(ano));
      expect(settings.valores[SettingsKeys.pncpAtasAtualizadasCnpj], _cnpj);
      expect(await container.read(pncpAtasProvider.future), hasLength(2));
    },
  );
}
