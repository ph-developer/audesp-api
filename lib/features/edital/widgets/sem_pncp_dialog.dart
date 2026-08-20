import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/audesp_dropdown.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../domain/edital_domain.dart';

const kModalidadesSiglas = <int, String>{
  1: 'LE', // Leilão Eletrônico
  2: 'DC', // Diálogo Competitivo
  3: 'CC', // Concurso
  4: 'CE', // Concorrência Eletrônica
  5: 'CP', // Concorrência Presencial
  6: 'PE', // Pregão Eletrônico
  7: 'PP', // Pregão Presencial
  8: 'DISP', // Dispensa de Licitação
  9: 'INEX', // Inexigibilidade
  12: 'CRED', // Credenciamento
  13: 'LP', // Leilão Presencial
  14: 'INAP', // Inaplicabilidade
  15: 'CHAP', // Chamada Pública
  16: 'CEI', // Concorrência Eletrônica Internacional
  17: 'CPI', // Concorrência Presencial Internacional
  18: 'PEI', // Pregão Eletrônico Internacional
  19: 'PPI', // Pregão Presencial Internacional
  997: 'RDC',
  998: 'CV', // Convite
  999: 'TP', // Tomada de Preços
};

class SemPncpDialogResult {
  final String codigoEdital;
  final int? modalidadeId;
  final String numero;
  final String ano;

  const SemPncpDialogResult({
    required this.codigoEdital,
    this.modalidadeId,
    required this.numero,
    required this.ano,
  });
}

Future<SemPncpDialogResult?> showSemPncpDialog(
  BuildContext context, {
  int? initialModalidadeId,
  String? initialNumero,
  String? initialAno,
  String? currentCodigo,
}) {
  return showDialog<SemPncpDialogResult>(
    context: context,
    builder: (ctx) => _SemPncpDialog(
      initialModalidadeId: initialModalidadeId,
      initialNumero: initialNumero,
      initialAno: initialAno,
      currentCodigo: currentCodigo,
    ),
  );
}

class _SemPncpDialog extends StatefulWidget {
  final int? initialModalidadeId;
  final String? initialNumero;
  final String? initialAno;
  final String? currentCodigo;

  const _SemPncpDialog({
    this.initialModalidadeId,
    this.initialNumero,
    this.initialAno,
    this.currentCodigo,
  });

  @override
  State<_SemPncpDialog> createState() => _SemPncpDialogState();
}

class _SemPncpDialogState extends State<_SemPncpDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _modalidadeId;
  late final TextEditingController _siglaCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _anoCtrl;

  @override
  void initState() {
    super.initState();
    _modalidadeId = widget.initialModalidadeId ?? 6;

    String initialNumero = widget.initialNumero ?? '';
    String initialAno = widget.initialAno?.isNotEmpty == true
        ? widget.initialAno!
        : DateTime.now().year.toString();

    // Se já havia um código pré-existente sem PNCP, tenta extrair modalidade, número e ano
    if (widget.currentCodigo != null && widget.currentCodigo!.contains('-')) {
      final parts = widget.currentCodigo!.split('-');
      if (parts.length == 2) {
        final sigla = parts[0].trim().toUpperCase();
        for (final entry in kModalidadesSiglas.entries) {
          if (entry.value.toUpperCase() == sigla) {
            _modalidadeId = entry.key;
            break;
          }
        }
        final numAno = parts[1].split('/');
        if (numAno.length == 2) {
          final cleanNum = numAno[0].replaceFirst(RegExp(r'^0+'), '');
          initialNumero =
              cleanNum.isEmpty && numAno[0].isNotEmpty ? '0' : cleanNum;
          if (numAno[1].trim().isNotEmpty) {
            initialAno = numAno[1].trim();
          }
        }
      }
    }

    final sigla = (_modalidadeId != null &&
            kModalidadesSiglas.containsKey(_modalidadeId))
        ? kModalidadesSiglas[_modalidadeId]!
        : 'PE';

    _siglaCtrl = TextEditingController(text: sigla);
    _numeroCtrl = TextEditingController(text: initialNumero);
    _anoCtrl = TextEditingController(text: initialAno);
  }

  @override
  void dispose() {
    _siglaCtrl.dispose();
    _numeroCtrl.dispose();
    _anoCtrl.dispose();
    super.dispose();
  }

  String get _codigoGerado {
    final sigla = _siglaCtrl.text.trim().toUpperCase();
    final numRaw = _numeroCtrl.text.trim();
    final ano = _anoCtrl.text.trim();

    if (sigla.isEmpty && numRaw.isEmpty && ano.isEmpty) {
      return '';
    }

    final numPadded = numRaw.isEmpty
        ? '000001'
        : (int.tryParse(numRaw)?.toString().padLeft(6, '0') ?? numRaw);

    final anoFinal = ano.isEmpty ? DateTime.now().year.toString() : ano;

    return '$sigla-$numPadded/$anoFinal';
  }

  void _onModalidadeChanged(int? modId) {
    setState(() {
      _modalidadeId = modId;
      if (modId != null && kModalidadesSiglas.containsKey(modId)) {
        _siglaCtrl.text = kModalidadesSiglas[modId]!;
      } else {
        _siglaCtrl.text = 'OUT';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final codigo = _codigoGerado;
    final length = codigo.length;
    final isOverLimit = length > 25;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.link_off, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Gerador de Código (Sem PNCP)'),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Para contratações não publicadas no PNCP, o AUDESP exige um código '
                'único identificador da compra de até 25 caracteres.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AudespDropdown<int>.items(
                label: 'Modalidade da Licitação / Compra',
                value: _modalidadeId,
                items: kModalidadesDropdown.entries
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _onModalidadeChanged,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: AudespTextField(
                      label: 'Sigla / Prefixo',
                      controller: _siglaCtrl,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: AudespTextField(
                      label: 'Número *',
                      controller: _numeroCtrl,
                      hintText: 'Ex: 1, 12',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: AudespTextField(
                      label: 'Ano *',
                      controller: _anoCtrl,
                      hintText: '2026',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverLimit
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverLimit
                        ? colorScheme.error
                        : colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Código Gerado para o AUDESP:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOverLimit
                                ? colorScheme.onErrorContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$length / 25 caracteres',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOverLimit
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      codigo.isEmpty ? '—' : codigo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOverLimit
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (isOverLimit) return;
            Navigator.of(context).pop(
              SemPncpDialogResult(
                codigoEdital: codigo,
                modalidadeId: _modalidadeId,
                numero: _numeroCtrl.text.trim(),
                ano: _anoCtrl.text.trim(),
              ),
            );
          },
          icon: const Icon(Icons.check),
          label: const Text('Aplicar Código'),
        ),
      ],
    );
  }
}
