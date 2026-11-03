import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/features/documentacao/documentacao_providers.dart';
import 'package:audesp_api/features/documentacao/domain/documentacao_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, String> settings;
  late int leituras;

  const original = DocumentacaoSnapshot(
    textoPagina: 't1',
    anexos: {'edital.zip': 'h1'},
    especificacaoApi: 'y1',
  );
  const alterada = DocumentacaoSnapshot(
    textoPagina: 't1',
    anexos: {'edital.zip': 'h2'},
    especificacaoApi: 'y1',
  );

  setUp(() {
    settings = {};
    leituras = 0;
  });

  Future<VerificacaoDocumentacao> verificar(
    DateTime agora,
    Future<DocumentacaoSnapshot> Function() lerDocumentacao,
  ) {
    return verificarDocumentacao(
      agora: agora,
      ler: (k) async => settings[k],
      gravar: (k, v) async => settings[k] = v,
      apagar: (k) async => settings.remove(k),
      lerDocumentacao: () {
        leituras++;
        return lerDocumentacao();
      },
    );
  }

  final manha = DateTime(2026, 11, 3, 8);
  final tarde = DateTime(2026, 11, 3, 14);

  test('a primeira leitura vira referência, sem alerta', () async {
    expect(
      await verificar(manha, () async => original),
      VerificacaoDocumentacao.referenciaCriada,
    );
    expect(settings[SettingsKeys.documentacaoReferencia], original.toJson());
    expect(settings.containsKey(SettingsKeys.documentacaoAlteradaEm), isFalse);
  });

  test('consulta uma vez por período, mesmo vindo de outra máquina', () async {
    await verificar(manha, () async => original);
    expect(
      await verificar(
        manha.add(const Duration(hours: 3)),
        () async => original,
      ),
      VerificacaoDocumentacao.jaVerificada,
    );
    expect(leituras, 1);
    expect(
      await verificar(tarde, () async => original),
      VerificacaoDocumentacao.semAlteracao,
    );
    expect(leituras, 2);
  });

  test('alteração mantém a referência e registra quando apareceu', () async {
    await verificar(manha, () async => original);
    expect(
      await verificar(tarde, () async => alterada),
      VerificacaoDocumentacao.alterada,
    );
    expect(settings[SettingsKeys.documentacaoReferencia], original.toJson());
    expect(settings[SettingsKeys.documentacaoAtual], alterada.toJson());
    final detectada = settings[SettingsKeys.documentacaoAlteradaEm];
    expect(detectada, '${tarde.millisecondsSinceEpoch ~/ 1000}');

    // A data da primeira detecção não muda nos períodos seguintes.
    await verificar(DateTime(2026, 11, 4, 8), () async => alterada);
    expect(settings[SettingsKeys.documentacaoAlteradaEm], detectada);
  });

  test('falha devolve o período para nova tentativa', () async {
    await verificar(manha, () async => original);
    await expectLater(
      verificar(tarde, () async => throw Exception('sem rede')),
      throwsException,
    );
    expect(
      settings[SettingsKeys.documentacaoPeriodo],
      periodoVerificacao(manha),
    );
    expect(
      await verificar(tarde, () async => original),
      VerificacaoDocumentacao.semAlteracao,
    );
  });

  test('falha na primeira consulta não deixa período marcado', () async {
    await expectLater(
      verificar(manha, () async => throw Exception('sem rede')),
      throwsException,
    );
    expect(settings.containsKey(SettingsKeys.documentacaoPeriodo), isFalse);
  });
}
