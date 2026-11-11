import 'package:audesp_api/shared/widgets/indicador_icone.dart';
import 'package:flutter_test/flutter_test.dart';

/// [IndicadorIcone] cujo título (primeira linha da tooltip) é [titulo].
Finder findIndicador(String titulo) =>
    find.byWidgetPredicate((w) => w is IndicadorIcone && w.titulo == titulo);
