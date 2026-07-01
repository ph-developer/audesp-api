import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/audesp_text_field.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../models/assinatura_model.dart';
import '../providers/assinaturas_provider.dart';

class EstimativaAssinaturasDialog extends ConsumerStatefulWidget {
  const EstimativaAssinaturasDialog({super.key});

  @override
  ConsumerState<EstimativaAssinaturasDialog> createState() =>
      _EstimativaAssinaturasDialogState();
}

class _EstimativaAssinaturasDialogState
    extends ConsumerState<EstimativaAssinaturasDialog> {
  final _nomeController = TextEditingController();
  final _cargoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<AssinaturaModel> _selectedAssinaturas = [];

  @override
  void dispose() {
    _nomeController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  void _adicionarAssinatura() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(assinaturasProvider.notifier)
          .addAssinatura(_nomeController.text, _cargoController.text);
      _nomeController.clear();
      _cargoController.clear();
    }
  }

  void _removerAssinatura(int id) {
    ref.read(assinaturasProvider.notifier).removeAssinatura(id);
    setState(() {
      _selectedAssinaturas.removeWhere((a) => a.id == id);
    });
  }

  void _toggleSelection(AssinaturaModel assinatura, bool? value) {
    setState(() {
      final isSelected = _selectedAssinaturas.any((a) => a.id == assinatura.id);
      if (value == true && !isSelected) {
        _selectedAssinaturas.add(assinatura);
      } else if (value == false && isSelected) {
        _selectedAssinaturas.removeWhere((a) => a.id == assinatura.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final assinaturasState = ref.watch(assinaturasProvider);

    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.draw),
          SizedBox(width: 12),
          Text('Selecionar Assinaturas para Exportação SEI'),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nova Assinatura Predefinida',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AudespTextField(
                      controller: _nomeController,
                      label: 'Nome',
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Obrigatório'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AudespTextField(
                      controller: _cargoController,
                      label: 'Cargo',
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Obrigatório'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: AudespIconButton(
                      onPressed: _adicionarAssinatura,
                      icon: Icons.add,
                      tooltip: 'Adicionar',
                      outlined: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Flexible(
              child: assinaturasState.when(
                data: (assinaturas) {
                  if (assinaturas.isEmpty) {
                    return Text('Nenhuma assinatura cadastrada.');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: assinaturas.length,
                    itemBuilder: (context, index) {
                      final assinatura = assinaturas[index];
                      final isSelected = _selectedAssinaturas.any(
                        (a) => a.id == assinatura.id,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: isSelected,
                          onChanged: (val) => _toggleSelection(assinatura, val),
                          title: Text(
                            assinatura.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(assinatura.cargo),
                          secondary: AudespIconButton(
                            icon: Icons.delete,
                            color: Colors.red,
                            onPressed: () => _removerAssinatura(assinatura.id),
                            tooltip: 'Excluir Assinatura',
                            size: 32,
                            iconSize: 20,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Text('Erro ao carregar assinaturas: $error'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedAssinaturas);
          },
          child: Text(
            'Confirmar',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
