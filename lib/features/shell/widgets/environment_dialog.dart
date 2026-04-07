import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/environments.dart';

Future<void> showEnvironmentDialog(BuildContext context, WidgetRef ref) =>
    showDialog(
      context: context,
      builder: (_) => const _EnvironmentDialog(),
    );

class _EnvironmentDialog extends ConsumerWidget {
  const _EnvironmentDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(environmentProvider);

    return AlertDialog(
      title: const Text('Ambiente da API AUDESP'),
      content: RadioGroup<Environment>(
        groupValue: current,
        onChanged: (v) {
          if (v != null) ref.read(environmentProvider.notifier).setEnvironment(v);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Environment.values.map((env) {
            return RadioListTile<Environment>(
              value: env,
              title: Text(env.label),
              subtitle: Text(env.baseUrl, style: const TextStyle(fontSize: 11)),
              secondary: env == Environment.piloto
                  ? const Chip(label: Text('Teste'))
                  : const Chip(
                      label: Text('Produção'),
                      backgroundColor: Color(0xFFE8F5E9),
                    ),
            );
          }).toList(),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
