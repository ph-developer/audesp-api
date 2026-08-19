import 'package:audesp_api/core/theme/app_theme.dart';
import 'package:audesp_api/shared/widgets/audesp_date_picker_field.dart';
import 'package:audesp_api/shared/widgets/audesp_date_time_picker_field.dart';
import 'package:audesp_api/shared/widgets/audesp_dropdown.dart';
import 'package:audesp_api/shared/widgets/audesp_input_metrics.dart';
import 'package:audesp_api/shared/widgets/audesp_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('initialValue inicializa o controller interno sem conflito', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AudespTextField(
            label: 'E-mail',
            initialValue: 'usuario@exemplo.com',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('usuario@exemplo.com'), findsOneWidget);
  });

  testWidgets('input labels remain floating when empty and unfocused', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SizedBox(
            width: 300,
            child: AudespTextField(label: 'Campo vazio'),
          ),
        ),
      ),
    );

    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(
      decorator.decoration.floatingLabelBehavior,
      FloatingLabelBehavior.always,
    );
  });

  testWidgets('single-line inputs use the standard height', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const textKey = Key('text');
    const dropdownKey = Key('dropdown');
    const dateKey = Key('date');
    const dateTimeKey = Key('date-time');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  key: textKey,
                  width: 250,
                  child: AudespTextField(label: 'Texto'),
                ),
                SizedBox(
                  key: dropdownKey,
                  width: 250,
                  child: AudespDropdown<int>(
                    label: 'Seleção',
                    value: 1,
                    items: const {1: 'Um'},
                    onChanged: (_) {},
                  ),
                ),
                SizedBox(
                  key: dateKey,
                  width: 250,
                  child: AudespDatePickerField(
                    label: 'Data',
                    value: null,
                    onChanged: (_) {},
                  ),
                ),
                SizedBox(
                  key: dateTimeKey,
                  width: 250,
                  child: AudespDateTimePickerField(
                    label: 'Data e hora',
                    value: null,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final heights = <double>[
      tester.getSize(find.byKey(textKey)).height,
      tester.getSize(find.byKey(dropdownKey)).height,
      tester.getSize(find.byKey(dateKey)).height,
      tester.getSize(find.byKey(dateTimeKey)).height,
    ];

    expect(
      heights,
      everyElement(AudespInputMetrics.fieldHeight),
      reason: 'Alturas encontradas: $heights',
    );
  });

  testWidgets('multiline input remains taller than the standard height', (
    tester,
  ) async {
    const fieldKey = Key('multiline');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SizedBox(
            key: fieldKey,
            width: 300,
            child: AudespTextField(label: 'Descrição', maxLines: 3),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(fieldKey)).height,
      greaterThan(AudespInputMetrics.fieldHeight),
    );
  });
}
