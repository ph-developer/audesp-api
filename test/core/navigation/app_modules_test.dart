import 'package:audesp_api/core/database/models/user.dart';
import 'package:audesp_api/core/navigation/app_modules.dart';
import 'package:flutter_test/flutter_test.dart';

User _user({int permissions = 0, bool isAdmin = false}) => User(
  id: 1,
  nome: 'Usuário',
  email: 'usuario@example.com',
  permissions: permissions,
  isAdmin: isAdmin,
  createdAt: DateTime(2026),
);

void main() {
  test('kAppModules mantém a ordem e os grupos, com Logs separado', () {
    expect(kAppModules.map((module) => module.route), [
      '/estimativa',
      '/edital',
      '/licitacao',
      '/ata',
      '/ajuste',
    ]);
    expect(kAppModules.map((module) => module.label), [
      'Estimativa',
      'Edital',
      'Licitação',
      'Ata',
      'Ajuste',
    ]);
    expect(kAppModules.map((module) => module.group), [
      AppModuleGroup.planejamento,
      AppModuleGroup.contratacao,
      AppModuleGroup.contratacao,
      AppModuleGroup.contratos,
      AppModuleGroup.contratos,
    ]);
    expect(kLogsModule.route, '/logs');
    expect(kLogsModule.group, isNull);
  });

  const profiles = [
    (
      name: 'Planejamento',
      permissions: AppPermissions.estimativa,
      isAdmin: false,
      routes: ['/estimativa'],
      home: '/estimativa',
    ),
    (
      name: 'Contratação',
      permissions: AppPermissions.edital | AppPermissions.licitacao,
      isAdmin: false,
      routes: ['/edital', '/licitacao'],
      home: '/edital',
    ),
    (
      name: 'Contratos',
      permissions: AppPermissions.ata | AppPermissions.ajuste,
      isAdmin: false,
      routes: ['/ata', '/ajuste'],
      home: '/ata',
    ),
    (
      name: 'admin sem bits de permissão',
      permissions: AppPermissions.none,
      isAdmin: true,
      routes: ['/estimativa', '/edital', '/licitacao', '/ata', '/ajuste'],
      home: '/estimativa',
    ),
    (
      name: 'sem permissões',
      permissions: AppPermissions.none,
      isAdmin: false,
      routes: <String>[],
      home: '/profile',
    ),
  ];

  for (final profile in profiles) {
    final user = _user(
      permissions: profile.permissions,
      isAdmin: profile.isAdmin,
    );

    test('modulosPara: ${profile.name}', () {
      expect(modulosPara(user).map((module) => module.route), profile.routes);
    });

    test('homeLocationFor: ${profile.name}', () {
      expect(homeLocationFor(user), profile.home);
    });

    test('canAccessLocation: módulos e subrotas de ${profile.name}', () {
      for (final module in kAppModules) {
        final allowed = profile.routes.contains(module.route);
        for (final suffix in ['', '/', '/new', '/42', '/42/detalhes']) {
          expect(
            canAccessLocation(user, '${module.route}$suffix'),
            allowed,
            reason: '${profile.name}: ${module.route}$suffix',
          );
        }
      }
    });
  }

  test('permissões individuais não liberam outros módulos', () {
    const permissions = [
      AppPermissions.estimativa,
      AppPermissions.edital,
      AppPermissions.licitacao,
      AppPermissions.ata,
      AppPermissions.ajuste,
    ];
    for (var i = 0; i < permissions.length; i++) {
      expect(modulosPara(_user(permissions: permissions[i])), [kAppModules[i]]);
      expect(
        homeLocationFor(_user(permissions: permissions[i])),
        kAppModules[i].route,
      );
    }
  });

  test('Logs exige alguma permissão de envio ou admin', () {
    final deniedUsers = [
      _user(),
      _user(permissions: AppPermissions.estimativa),
      _user(permissions: 1 << 10),
    ];
    final allowedUsers = [
      _user(permissions: AppPermissions.edital),
      _user(permissions: AppPermissions.licitacao),
      _user(permissions: AppPermissions.ata),
      _user(permissions: AppPermissions.ajuste),
      _user(permissions: AppPermissions.ata | AppPermissions.ajuste),
      _user(isAdmin: true),
    ];

    for (final user in deniedUsers) {
      expect(kLogsModule.podeAcessar(user), isFalse);
      expect(canAccessLocation(user, '/logs'), isFalse);
      expect(canAccessLocation(user, '/logs/42'), isFalse);
    }
    for (final user in allowedUsers) {
      expect(kLogsModule.podeAcessar(user), isTrue);
      expect(canAccessLocation(user, '/logs'), isTrue);
      expect(canAccessLocation(user, '/logs/42'), isTrue);
    }
  });

  test('rotas externas e prefixos sem barra continuam liberados', () {
    final user = _user();
    for (final location in [
      '/login',
      '/profile',
      '/admin',
      '/outra-rota',
      '/editais',
      '/edital-extra',
      '/logs-extra',
    ]) {
      expect(canAccessLocation(user, location), isTrue, reason: location);
    }
  });
}
