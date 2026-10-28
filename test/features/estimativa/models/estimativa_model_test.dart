import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final estimativa = EstimativaModel(
    id: 1,
    numero: 2,
    ano: 2026,
    objeto: 'Material',
  );

  test('novas estimativas são rascunhos', () {
    expect(estimativa.status, EstimativaStatus.rascunho);
    expect(estimativa.finalizada, isFalse);
  });

  test('copyWith altera e preserva status sem modificar a origem', () {
    final finalizada = estimativa.copyWith(status: EstimativaStatus.finalizada);
    expect(finalizada.finalizada, isTrue);
    expect(finalizada.copyWith(numero: 3).status, EstimativaStatus.finalizada);
    expect(
      finalizada.copyWith(status: EstimativaStatus.rascunho).finalizada,
      isFalse,
    );
    expect(estimativa.finalizada, isFalse);
    expect(finalizada.id, estimativa.id);
    expect(finalizada.objeto, estimativa.objeto);
  });

  test('status pertence à coluna e não ao documento JSON', () {
    final finalizada = estimativa.copyWith(status: EstimativaStatus.finalizada);
    expect(finalizada.toMap(), isNot(contains('status')));
    final fromJson = EstimativaModel.fromMap({
      ...finalizada.toMap(),
      'status': EstimativaStatus.finalizada,
    });
    expect(fromJson.status, EstimativaStatus.rascunho);
    expect(
      fromJson.copyWith(status: EstimativaStatus.finalizada).finalizada,
      isTrue,
    );
  });
}
