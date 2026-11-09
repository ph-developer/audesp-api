import 'package:flutter/material.dart';

import '../../../core/utils/search_matcher.dart';
import '../../../shared/widgets/audesp_dropdown.dart';
import '../domain/edital_domain.dart';

/// Filtro das listagens pela modalidade da licitação do edital; `null` é
/// "Todas".
class FiltroModalidadeDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const FiltroModalidadeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static final _modalidades = kModalidadesDropdown.entries.toList()
    ..sort(
      (a, b) =>
          normalizeSearchText(a.value).compareTo(normalizeSearchText(b.value)),
    );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AudespDropdown<int?>(
        label: 'Modalidade',
        value: value,
        items: {null: 'Todas', for (final m in _modalidades) m.key: m.value},
        onChanged: onChanged,
      ),
    );
  }
}
