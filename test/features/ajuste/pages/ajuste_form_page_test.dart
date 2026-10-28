import 'dart:convert';

import 'package:audesp_api/core/database/app_database.dart';
import 'package:audesp_api/core/database/daos/ajustes_dao.dart';
import 'package:audesp_api/core/database/daos/app_settings_dao.dart';
import 'package:audesp_api/core/database/daos/editais_dao.dart';
import 'package:audesp_api/core/database/daos/licitacoes_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/features/ajuste/pages/ajuste_form_page.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:audesp_api/shared/widgets/audesp_dropdown.dart';
import 'package:audesp_api/shared/widgets/audesp_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../processo/processo_fixtures.dart';

class _AjustesMemoria implements AjustesDao {
  final Ajuste? existente;
  final gravacoes = <({int? ataId, String? codigoAta, String documentoJson})>[];

  _AjustesMemoria([this.existente]);

  @override
  Future<Ajuste?> findById(int id) async => existente;

  @override
  Future<int> insertAjuste({
    required int? editalId,
    int? ataId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    String? codigoAta,
    required String codigoContrato,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    gravacoes.add((
      ataId: ataId,
      codigoAta: codigoAta,
      documentoJson: documentoJson,
    ));
    return 21;
  }

  @override
  Future<bool> updateAjuste({
    required int id,
    required int? editalId,
    int? ataId,
    required String municipio,
    required String entidade,
    required String codigoEdital,
    String? codigoAta,
    required String codigoContrato,
    required bool retificacao,
    required String status,
    required String documentoJson,
    DateTime? updatedAt,
  }) async {
    gravacoes.add((
      ataId: ataId,
      codigoAta: codigoAta,
      documentoJson: documentoJson,
    ));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EditaisMemoria implements EditaisDao {
  final List<Processo> processos;
  _EditaisMemoria(this.processos);

  @override
  Future<Edital?> findById(int id) async =>
      processos.where((p) => p.edital.id == id).firstOrNull?.edital;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LicitacoesMemoria implements LicitacoesDao {
  final List<Processo> processos;
  _LicitacoesMemoria(this.processos);

  @override
  Future<List<Licitacao>> watchByEdital(int editalId) async => processos
      .where((p) => p.edital.id == editalId)
      .expand((p) => p.licitacoes)
      .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SettingsMemoria implements AppSettingsDao {
  @override
  Future<String?> get(String key) async => switch (key) {
    SettingsKeys.codigoMunicipio => '1',
    SettingsKeys.codigoEntidade => '2',
    SettingsKeys.codigoTipoOrgao => '1',
    _ => null,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpPage(
  WidgetTester tester,
  _AjustesMemoria dao, {
  required List<Processo> processos,
  int? preselectedEditalId,
}) async {
  await tester.binding.setSurfaceSize(const Size(1800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ajustesDaoProvider.overrideWithValue(dao),
        editaisDaoProvider.overrideWithValue(_EditaisMemoria(processos)),
        licitacoesDaoProvider.overrideWithValue(_LicitacoesMemoria(processos)),
        appSettingsDaoProvider.overrideWithValue(_SettingsMemoria()),
        processosProvider.overrideWith((ref) async => processos),
      ],
      child: MaterialApp(
        home: AjusteFormPage(
          ajusteId: dao.existente?.id,
          preselectedEditalId: preselectedEditalId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _campo(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AudespTextField && w.label == label),
  matching: find.byType(TextField),
);

AudespDropdown<int?> _editalSelecionado(WidgetTester tester) => tester
    .widgetList<AudespDropdown<int?>>(find.byType(AudespDropdown<int?>))
    .singleWhere((w) => w.label == 'Edital *');

void main() {
  for (final srp in [true, false]) {
    for (final ataId in srp ? [null, 11] : [11]) {
      testWidgets(
        'ajuste antigo abre, preserva ata e bloqueia envio (SRP $srp, ata $ataId)',
        (tester) async {
          final dao = _AjustesMemoria(
            ajusteFixture(
              21,
              ataId: ataId,
              documentoJson: jsonEncode({
                'descritor': {
                  if (ataId != null) 'codigoAta': 'ATA-LEGADA/2026',
                },
              }),
            ),
          );
          await _pumpPage(
            tester,
            dao,
            processos: [
              processoFixture(
                srp: srp,
                licitacoes: [licitacaoFixture(1, status: 'sent')],
                ajustes: [dao.existente!],
                // A ata original pode ter sido excluída ou voltado a rascunho.
              ),
            ],
          );
          final motivo = srp
              ? 'Edital com registro de preços gera ata, não ajuste.'
              : 'Ajuste vinculado a ata não pode ser enviado.';

          expect(_editalSelecionado(tester).value, 1);
          expect(
            find.textContaining('$motivo O rascunho pode ser salvo'),
            findsOneWidget,
          );
          expect(find.text('Ata (somente para SRP)'), findsNothing);
          expect(find.textContaining('Código da Ata:'), findsNothing);
          expect(find.text('Preencher pela licitação'), findsNothing);
          expect(
            find.text('ID da Ata PNCP da Adesão (opcional)'),
            findsNothing,
          );

          await tester.tap(find.text('Enviar à AUDESP'));
          await tester.pumpAndSettle();
          expect(find.text(motivo), findsOneWidget);
          expect(dao.gravacoes, isEmpty);
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Salvar Rascunho'));
          await tester.pumpAndSettle();
          expect(dao.gravacoes.single.ataId, ataId);
          expect(
            dao.gravacoes.single.codigoAta,
            ataId == null ? null : 'ATA-LEGADA/2026',
          );
          expect(find.text('Rascunho salvo com sucesso.'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('novo ajuste lista só não SRP e grava ata_id nulo', (
    tester,
  ) async {
    final dao = _AjustesMemoria();
    await _pumpPage(
      tester,
      dao,
      preselectedEditalId: 2,
      processos: [
        processoFixture(
          srp: true,
          licitacoes: [licitacaoFixture(1, status: 'sent')],
        ),
        processoFixture(
          id: 2,
          licitacoes: [licitacaoFixture(2, editalId: 2, status: 'sent')],
        ),
      ],
    );
    expect(_editalSelecionado(tester).value, 2);
    final dropdown = tester.widget<DropdownButton<int?>>(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is AudespDropdown<int?> && w.label == 'Edital *',
        ),
        matching: find.byType(DropdownButton<int?>),
      ),
    );
    expect(dropdown.items!.map((item) => item.value), [2]);
    expect(find.text('Ata (somente para SRP)'), findsNothing);

    await tester.enterText(
      _campo('Código do Contrato (Sem PNCP) *'),
      'NOVO/2026',
    );
    await tester.tap(find.text('Salvar Rascunho'));
    await tester.pumpAndSettle();
    expect(dao.gravacoes.single.ataId, isNull);
    expect(dao.gravacoes.single.codigoAta, isNull);
    final doc =
        jsonDecode(dao.gravacoes.single.documentoJson) as Map<String, dynamic>;
    expect((doc['descritor'] as Map).containsKey('codigoAta'), isFalse);
    expect(find.text('Rascunho salvo com sucesso.'), findsOneWidget);
  });

  testWidgets('adesão mantém código de ata digitado e dispensa edital local', (
    tester,
  ) async {
    const codigoEdital = '1234567800019010000012026';
    const codigoAta = '1234567800019011234562026000001';
    const codigoContrato = '1234567800019020000012026';
    final dao = _AjustesMemoria();
    await _pumpPage(tester, dao, processos: []);
    await tester.tap(find.text('Adesão / Participação'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Código da Ata:'), findsOneWidget);
    await tester.enterText(
      _campo('ID de Contratação PNCP da Adesão *'),
      codigoEdital,
    );
    await tester.enterText(
      _campo('ID da Ata PNCP da Adesão (opcional)'),
      codigoAta,
    );
    await tester.enterText(_campo('ID do Contrato PNCP *'), codigoContrato);
    await tester.tap(find.text('Salvar Rascunho'));
    await tester.pumpAndSettle();
    expect(dao.gravacoes.single.ataId, isNull);
    expect(dao.gravacoes.single.codigoAta, codigoAta);
    final doc =
        jsonDecode(dao.gravacoes.single.documentoJson) as Map<String, dynamic>;
    expect(doc['descritor'], containsPair('adesaoParticipacao', true));
    expect(doc['descritor'], containsPair('codigoEdital', codigoEdital));
    expect(doc['descritor'], containsPair('codigoAta', codigoAta));
    expect(find.text('Rascunho salvo com sucesso.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
