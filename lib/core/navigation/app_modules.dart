import 'package:flutter/material.dart' show IconData, Icons;

import '../database/models/user.dart';

enum AppModuleGroup { planejamento, contratacao, contratos }

class AppModule {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final AppModuleGroup? group;
  final bool Function(User) podeAcessar;

  const AppModule({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.group,
    required this.podeAcessar,
  });

  bool matchesLocation(String location) =>
      location == route || location.startsWith('$route/');
}

// A ordem também define o módulo inicial. Módulos sem grupo podem ser
// acrescentados no topo sem mudar as regras de navegação ou o rail.
final List<AppModule> kAppModules = List.unmodifiable([
  AppModule(
    route: '/estimativa',
    label: 'Estimativa',
    icon: Icons.calculate_outlined,
    activeIcon: Icons.calculate,
    group: AppModuleGroup.planejamento,
    podeAcessar: (user) => user.hasPermission(AppPermissions.estimativa),
  ),
  AppModule(
    route: '/edital',
    label: 'Edital',
    icon: Icons.description_outlined,
    activeIcon: Icons.description,
    group: AppModuleGroup.contratacao,
    podeAcessar: (user) => user.hasPermission(AppPermissions.edital),
  ),
  AppModule(
    route: '/licitacao',
    label: 'Licitação',
    icon: Icons.gavel_outlined,
    activeIcon: Icons.gavel,
    group: AppModuleGroup.contratacao,
    podeAcessar: (user) => user.hasPermission(AppPermissions.licitacao),
  ),
  AppModule(
    route: '/ata',
    label: 'Ata',
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment,
    group: AppModuleGroup.contratos,
    podeAcessar: (user) => user.hasPermission(AppPermissions.ata),
  ),
  AppModule(
    route: '/ajuste',
    label: 'Ajuste',
    icon: Icons.handshake_outlined,
    activeIcon: Icons.handshake,
    group: AppModuleGroup.contratos,
    podeAcessar: (user) => user.hasPermission(AppPermissions.ajuste),
  ),
]);

final AppModule kLogsModule = AppModule(
  route: '/logs',
  label: 'Logs',
  icon: Icons.history_outlined,
  activeIcon: Icons.history,
  podeAcessar: (user) => user.hasAnyPermission(
    AppPermissions.edital |
        AppPermissions.licitacao |
        AppPermissions.ata |
        AppPermissions.ajuste,
  ),
);

List<AppModule> modulosPara(User user) => [
  for (final module in kAppModules)
    if (module.podeAcessar(user)) module,
];

String homeLocationFor(User user) {
  for (final module in kAppModules) {
    if (module.podeAcessar(user)) return module.route;
  }
  return kLogsModule.podeAcessar(user) ? kLogsModule.route : '/profile';
}

bool canAccessLocation(User user, String location) {
  for (final module in [...kAppModules, kLogsModule]) {
    if (module.matchesLocation(location)) return module.podeAcessar(user);
  }
  return true;
}
