import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/environments.dart';

Future<void> showEnvironmentDialog(BuildContext context, WidgetRef ref) =>
    showDialog<void>(
      context: context,
      builder: (_) => const _EnvironmentDialog(),
    );

class _EnvironmentDialog extends ConsumerWidget {
  const _EnvironmentDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(environmentProvider);

    return ContentDialog(
      title: const Text('Ambiente da API AUDESP'),
      content: RadioGroup<Environment>(
        groupValue: current,
        onChanged: (v) {
          if (v != null) {
            ref.read(environmentProvider.notifier).setEnvironment(v);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Environment.values.map((env) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: RadioButton<Environment>(
                value: env,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      env.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      env.baseUrl,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
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
