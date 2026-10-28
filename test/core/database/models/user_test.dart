import 'package:audesp_api/core/database/models/user.dart';
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
  group('User.hasAnyPermission', () {
    test('admin tem acesso mesmo sem bits ou com máscara zero', () {
      final user = _user(isAdmin: true);

      expect(user.hasAnyPermission(AppPermissions.edital), isTrue);
      expect(user.hasAnyPermission(AppPermissions.none), isTrue);
      expect(user.hasAnyPermission(1 << 10), isTrue);
    });

    test('basta um bit da máscara, em qualquer posição', () {
      const mask = AppPermissions.edital | AppPermissions.licitacao;

      expect(
        _user(permissions: AppPermissions.edital).hasAnyPermission(mask),
        isTrue,
      );
      expect(
        _user(permissions: AppPermissions.licitacao).hasAnyPermission(mask),
        isTrue,
      );
      expect(_user(permissions: mask).hasAnyPermission(mask), isTrue);
    });

    test('nega quando não há interseção ou permissões', () {
      const mask = AppPermissions.edital | AppPermissions.licitacao;

      expect(
        _user(permissions: AppPermissions.ata).hasAnyPermission(mask),
        isFalse,
      );
      expect(_user().hasAnyPermission(mask), isFalse);
    });

    test('máscara zero não concede acesso a não-admin', () {
      expect(_user().hasAnyPermission(AppPermissions.none), isFalse);
      expect(
        _user(
          permissions: AppPermissions.edital,
        ).hasAnyPermission(AppPermissions.none),
        isFalse,
      );
    });

    test('hasPermission continua exigindo todos os bits', () {
      final user = _user(permissions: AppPermissions.edital);
      const mask = AppPermissions.edital | AppPermissions.licitacao;

      expect(user.hasAnyPermission(mask), isTrue);
      expect(user.hasPermission(mask), isFalse);
      expect(user.hasPermission(AppPermissions.none), isTrue);
    });
  });
}
