import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_modules.dart';

/// Rail compacto com separação entre os grupos que têm módulos visíveis.
class AppNavigationRail extends StatelessWidget {
  final List<AppModule> modules;
  final Widget leading;
  final Widget trailing;

  const AppNavigationRail({
    super.key,
    required this.modules,
    required this.leading,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final railTheme = NavigationRailTheme.of(context);
    final colors = theme.colorScheme;
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: railTheme.minWidth ?? 80,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: Material(
        color: railTheme.backgroundColor ?? colors.surface,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              leading,
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < modules.length; i++) ...[
                        if (i > 0 && modules[i - 1].group != modules[i].group)
                          const Divider(height: 16, indent: 24, endIndent: 24),
                        _ModuleDestination(
                          module: modules[i],
                          selected: modules[i].matchesLocation(currentPath),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleDestination extends StatelessWidget {
  final AppModule module;
  final bool selected;

  const _ModuleDestination({required this.module, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      container: true,
      label: module.label,
      button: true,
      selected: selected,
      child: Tooltip(
        message: module.label,
        excludeFromSemantics: true,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(40),
          onTap: () => context.go(module.route),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 32,
                      decoration: ShapeDecoration(
                        color: selected
                            ? colors.secondaryContainer
                            : Colors.transparent,
                        shape: const StadiumBorder(),
                      ),
                      child: Icon(
                        selected ? module.activeIcon : module.icon,
                        size: 24,
                        color: selected
                            ? colors.onSecondaryContainer
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
