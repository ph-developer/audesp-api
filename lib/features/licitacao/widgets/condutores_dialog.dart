import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/audesp_cpf_cnpj_field.dart';
import '../../../shared/widgets/audesp_delete_dialog.dart';
import '../../../shared/widgets/audesp_icon_button.dart';
import '../../../shared/widgets/audesp_snack_bar.dart';
import '../../../shared/widgets/audesp_text_field.dart';
import '../domain/licitacao_condutor.dart';
import '../licitacao_providers.dart';
import '../models/condutor.dart';

/// Cadastro de condutores e seleção dos que conduziram a contratação.
///
/// Retorna os CPFs da licitação conforme [CondutorRules.aplicarSelecao], ou
/// `null` se o usuário cancelar.
class CondutoresDialog extends ConsumerStatefulWidget {
  final List<String> cpfsAtuais;

  const CondutoresDialog({super.key, required this.cpfsAtuais});

  @override
  ConsumerState<CondutoresDialog> createState() => _CondutoresDialogState();
}

class _CondutoresDialogState extends ConsumerState<CondutoresDialog> {
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final Set<String> _selecionados = widget.cpfsAtuais.toSet();
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _adicionar() async {
    if (_salvando || !_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final novo = await ref
          .read(condutoresProvider.notifier)
          .adicionar(
            _nomeController.text.trim(),
            CondutorRules.normalizarCpf(_cpfController.text),
          );
      _nomeController.clear();
      _cpfController.clear();
      if (mounted) setState(() => _selecionados.add(novo.cpf));
    } catch (e) {
      if (mounted) {
        AudespSnackBar.show(context, message: 'Erro ao cadastrar condutor: $e');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover(Condutor condutor) async {
    final confirmado = await showAudespDeleteDialog(
      context: context,
      title: 'Excluir Condutor',
      entityName: condutor.nome,
      entityLabel: 'o condutor',
    );
    if (!confirmado) return;
    try {
      await ref.read(condutoresProvider.notifier).remover(condutor.id);
    } catch (e) {
      if (mounted) {
        AudespSnackBar.show(context, message: 'Erro ao excluir condutor: $e');
      }
    }
  }

  void _confirmar(List<Condutor> cadastrados) {
    Navigator.of(context).pop(
      CondutorRules.aplicarSelecao(
        atuais: widget.cpfsAtuais,
        cadastrados: cadastrados,
        selecionados: _selecionados,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final condutoresState = ref.watch(condutoresProvider);
    final cadastrados = condutoresState.value ?? const <Condutor>[];

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.groups),
          SizedBox(width: 12),
          Text('Selecionar Condutores'),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Novo Condutor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AudespTextField(
                      controller: _nomeController,
                      label: 'Nome',
                      maxLength: 255,
                      textCapitalization: TextCapitalization.words,
                      validator: CondutorRules.validarNome,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AudespCpfCnpjField(
                      controller: _cpfController,
                      label: 'CPF',
                      validator: (v) =>
                          CondutorRules.validarCpf(v, cadastrados),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: AudespIconButton(
                      onPressed: _salvando ? null : _adicionar,
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
              child: condutoresState.when(
                data: (condutores) {
                  if (condutores.isEmpty) {
                    return const Text('Nenhum condutor cadastrado.');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: condutores.length,
                    itemBuilder: (context, index) {
                      final condutor = condutores[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selecionados.contains(condutor.cpf),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selecionados.add(condutor.cpf);
                            } else {
                              _selecionados.remove(condutor.cpf);
                            }
                          }),
                          title: Text(
                            condutor.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            CondutorRules.formatarCpf(condutor.cpf),
                          ),
                          secondary: AudespIconButton(
                            icon: Icons.delete,
                            color: Colors.red,
                            onPressed: () => _remover(condutor),
                            tooltip: 'Excluir Condutor',
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
                    Text('Erro ao carregar condutores: $error'),
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
          onPressed: condutoresState.hasValue
              ? () => _confirmar(cadastrados)
              : null,
          child: const Text(
            'Confirmar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
