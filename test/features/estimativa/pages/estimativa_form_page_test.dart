import 'package:audesp_api/core/database/daos/editais_dao.dart';
import 'package:audesp_api/core/database/daos/estimativas_dao.dart';
import 'package:audesp_api/core/database/database_providers.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_item_model.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:audesp_api/features/estimativa/pages/estimativa_form_page.dart';
import 'package:audesp_api/shared/widgets/audesp_dropdown.dart';
import 'package:audesp_api/shared/widgets/audesp_text_field.dart';
import 'package:audesp_api/shared/widgets/hover_cell_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EstimativasMemoria implements EstimativasDao {
  EstimativaModel estimativa;
  final eventos = <String>[];

  _EstimativasMemoria({
    String status = EstimativaStatus.rascunho,
    String objeto = 'Material',
  }) : estimativa = EstimativaModel(
         id: 7,
         numero: 3,
         ano: 2026,
         objeto: objeto,
         status: status,
         formaPagamento: '30 dias',
         itens: [
           EstimativaItem(
             numero: 1,
             descricao: 'Papel',
             unidade: 'UN',
             quantidade: 2,
           ),
         ],
       );

  @override
  Future<EstimativaModel?> findById(int id) async => estimativa;

  @override
  Future<int> getNextNumero(int ano) async => 4;

  @override
  Future<bool> checkNumeroExists(int numero, int ano, {int? excludeId}) async =>
      false;

  @override
  Future<bool> updateEstimativa(EstimativaModel estimativa) async {
    eventos.add('salvar');
    this.estimativa = estimativa.copyWith(status: this.estimativa.status);
    return true;
  }

  @override
  Future<void> setStatus(int id, String status) async {
    eventos.add('status:$status');
    estimativa = estimativa.copyWith(status: status);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EditaisMemoria implements EditaisDao {
  final int quantidade;
  int? estimativaConsultada;
  _EditaisMemoria(this.quantidade);

  @override
  Future<int> countByEstimativa(int estimativaId) async {
    estimativaConsultada = estimativaId;
    return quantidade;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpPage(
  WidgetTester tester,
  _EstimativasMemoria dao, {
  _EditaisMemoria? editais,
  bool nova = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        estimativasDaoProvider.overrideWithValue(dao),
        editaisDaoProvider.overrideWithValue(editais ?? _EditaisMemoria(0)),
      ],
      child: MaterialApp(
        home: EstimativaFormPage(estimativaId: nova ? null : 7),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('finalizada abre somente leitura e mantém exportações', (
    tester,
  ) async {
    final dao = _EstimativasMemoria(status: EstimativaStatus.finalizada);
    await _pumpPage(tester, dao);
    expect(
      find.text('Estimativa finalizada. Reabra para editar.'),
      findsOneWidget,
    );
    expect(find.text('Salvar Estimativa'), findsNothing);
    expect(find.text('Finalizar'), findsNothing);
    expect(find.text('Reabrir'), findsOneWidget);
    expect(find.text('Gerar PDF'), findsOneWidget);
    expect(find.text('Exportação SEI'), findsOneWidget);
    expect(
      tester
          .widgetList<AudespTextField>(find.byType(AudespTextField))
          .every((field) => field.readOnly),
      isTrue,
    );
    expect(
      tester
          .widgetList<AudespDropdown<String>>(
            find.byType(AudespDropdown<String>),
          )
          .every((field) => field.readOnly),
      isTrue,
    );
    expect(
      tester
          .widgetList<HoverCellText>(find.byType(HoverCellText))
          .every((cell) => cell.onTap == null),
      isTrue,
    );
    expect(
      tester
          .widgetList<ReorderableDragStartListener>(
            find.byType(ReorderableDragStartListener),
          )
          .every((handle) => !handle.enabled),
      isTrue,
    );
    expect(dao.eventos, isEmpty);
  });

  testWidgets('Finalizar salva alterações antes de mudar status', (
    tester,
  ) async {
    final dao = _EstimativasMemoria();
    await _pumpPage(tester, dao);
    final objeto = find.byWidgetPredicate(
      (w) => w is AudespTextField && w.label == 'Objeto da Licitação *',
    );
    await tester.enterText(
      find.descendant(of: objeto, matching: find.byType(TextField)),
      'Objeto revisado',
    );
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    expect(dao.eventos, isEmpty);
    await tester.tap(find.text('Finalizar').last);
    await tester.pumpAndSettle();
    expect(dao.eventos, ['salvar', 'status:finalizada']);
    expect(dao.estimativa.objeto, 'Objeto revisado');
    expect(dao.estimativa.finalizada, isTrue);
    expect(
      find.text('Estimativa finalizada. Reabra para editar.'),
      findsOneWidget,
    );
  });

  testWidgets('Finalizar respeita validação do formulário', (tester) async {
    final dao = _EstimativasMemoria(objeto: '');
    await _pumpPage(tester, dao);
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar').last);
    await tester.pumpAndSettle();
    expect(find.text('Obrigatório'), findsOneWidget);
    expect(dao.eventos, isEmpty);
    expect(dao.estimativa.finalizada, isFalse);
  });

  testWidgets('Reabrir avisa sobre editais e só altera o estado da estimativa', (
    tester,
  ) async {
    final dao = _EstimativasMemoria(status: EstimativaStatus.finalizada);
    final editais = _EditaisMemoria(2);
    await _pumpPage(tester, dao, editais: editais);
    await tester.tap(find.text('Reabrir'));
    await tester.pumpAndSettle();
    expect(editais.estimativaConsultada, 7);
    expect(
      find.textContaining(
        '2 edital(is) importaram itens desta estimativa; eles não serão alterados.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Reabrir').last);
    await tester.pumpAndSettle();
    expect(dao.eventos, ['status:rascunho']);
    expect(dao.estimativa.finalizada, isFalse);
    expect(find.text('Salvar Estimativa'), findsOneWidget);
    expect(
      tester
          .widgetList<AudespTextField>(find.byType(AudespTextField))
          .every((field) => !field.readOnly),
      isTrue,
    );
  });

  testWidgets('cancelar Reabrir preserva a estimativa finalizada', (
    tester,
  ) async {
    final dao = _EstimativasMemoria(status: EstimativaStatus.finalizada);
    await _pumpPage(tester, dao);
    await tester.tap(find.text('Reabrir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('edital(is) importaram'), findsNothing);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(dao.eventos, isEmpty);
    expect(dao.estimativa.finalizada, isTrue);
  });

  testWidgets('nova estimativa precisa ser salva para oferecer Finalizar', (
    tester,
  ) async {
    await _pumpPage(tester, _EstimativasMemoria(), nova: true);
    expect(find.text('Salvar Estimativa'), findsOneWidget);
    expect(find.text('Finalizar'), findsNothing);
    expect(find.text('Reabrir'), findsNothing);
  });
}
