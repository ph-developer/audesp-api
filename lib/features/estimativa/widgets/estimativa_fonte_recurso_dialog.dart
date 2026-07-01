import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/audesp_dialog.dart';
import '../../../shared/widgets/audesp_text_field.dart';

Future<Map<String, dynamic>?> showEstimativaFonteRecursoDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showAudespDialog<Map<String, dynamic>>(
    context: context,
    size: DialogSize.medium,
    builder: (_) => _EstimativaFonteRecursoDialog(initial: initial),
  );
}

class _EstimativaFonteRecursoDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _EstimativaFonteRecursoDialog({this.initial});

  @override
  State<_EstimativaFonteRecursoDialog> createState() =>
      _EstimativaFonteRecursoDialogState();
}

class _EstimativaFonteRecursoDialogState
    extends State<_EstimativaFonteRecursoDialog> {
  final _formKey = GlobalKey<FormState>();

  final _fonteCtrl = TextEditingController();
  final _aplicacaoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _reservaCtrl = TextEditingController();
  final _fichaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _fonteCtrl.text = ini['fonteRecurso'] as String? ?? '';
      _aplicacaoCtrl.text = ini['aplicacao'] as String? ?? '';
      _descricaoCtrl.text = ini['descricao'] as String? ?? '';
      _reservaCtrl.text = ini['reserva'] as String? ?? '';
      _fichaCtrl.text = ini['ficha'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _fonteCtrl.dispose();
    _aplicacaoCtrl.dispose();
    _descricaoCtrl.dispose();
    _reservaCtrl.dispose();
    _fichaCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    // Pad left 0 if 1 digit for Fonte de Recurso
    String fonte = _fonteCtrl.text.trim();
    if (fonte.length == 1) {
      fonte = fonte.padLeft(2, '0');
    }

    final result = <String, dynamic>{
      'fonteRecurso': fonte,
      'aplicacao': _aplicacaoCtrl.text.trim(),
      'descricao': _descricaoCtrl.text.trim(),
      'reserva': _reservaCtrl.text.trim(),
      'ficha': _fichaCtrl.text.trim(),
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null
            ? 'Adicionar Fonte de Recurso'
            : 'Editar Fonte de Recurso',
      ),
      content: SizedBox(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AudespTextField(
                      label: 'Fonte de Recurso *',
                      controller: _fonteCtrl,
                      maxLength: 2,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obrigatório';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AudespTextField(
                      label: 'Aplicação *',
                      controller: _aplicacaoCtrl,
                      maxLength: 8,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        final text = v?.trim() ?? '';
                        if (text.isEmpty) return 'Obrigatório';
                        if (text.length < 5) return 'Mínimo 5 dígitos';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AudespTextField(
                      label: 'Reserva',
                      controller: _reservaCtrl,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AudespTextField(
                      label: 'Ficha',
                      controller: _fichaCtrl,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AudespTextField(
                label: 'Descrição',
                controller: _descricaoCtrl,
                maxLength: 200,
                maxLines: 2,
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
        FilledButton(onPressed: _confirm, child: const Text('Confirmar')),
      ],
    );
  }
}
