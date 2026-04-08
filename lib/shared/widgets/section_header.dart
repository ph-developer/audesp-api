import 'package:fluent_ui/fluent_ui.dart';

/// Cabeçalho de seção de formulário com título e divisor.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 4),
          const Divider(),
        ],
      ),
    );
  }
}
