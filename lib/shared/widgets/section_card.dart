import 'package:flutter/material.dart';

/// Card de seção reutilizável para os formulários AUDESP.
///
/// Exibe um [Card] com título destacado, divisor e lista de widgets filhos.
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
