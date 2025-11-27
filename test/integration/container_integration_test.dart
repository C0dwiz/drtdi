import 'package:test/test.dart';
import 'package:drtdi/drtdi.dart';
import '../test_utils/test_classes.dart';

void main() {
  group('Container Integration Tests', () {
    test('should handle complex dependency graph', () {
      final container = DIContainer();

      container.register<Database>((c) => Database('main'),
          lifecycle: Lifecycle.singleton);
      container.register<Repository>((c) => Repository(c.resolve<Database>()));
      container.register<UserService>((c) => UserService(
            c.resolve<Repository>(),
            c.resolve<Database>(),
          ));
      container.register<AuthService>((c) => AuthService(
            c.resolve<UserService>(),
            c.resolve<Database>(),
          ));

      final authService = container.resolve<AuthService>();
      expect(authService, isA<AuthService>());
      expect(authService.userService, isA<UserService>());
      expect(authService.db, isA<Database>());

      container.validate();
      container.dispose();
    });

    test('should work with mixed lifecycles', () {
      final container = DIContainer();

      container.register<Database>((c) => Database('db'),
          lifecycle: Lifecycle.singleton);
      container.register<Repository>((c) => Repository(c.resolve<Database>()),
          lifecycle: Lifecycle.transient);
      container.register<Service>((c) => Service(),
          lifecycle: Lifecycle.scoped);

      final scope = container.createScope();
      final repo1 = scope.resolve<Repository>();
      final repo2 = scope.resolve<Repository>();
      final service1 = scope.resolve<Service>();
      final service2 = scope.resolve<Service>();

      expect(repo1, isNot(equals(repo2)));
      expect(service1, equals(service2));

      scope.dispose();
      container.dispose();
    });

    test('should handle multiple scopes', () {
      final root = DIContainer();
      root.register<Database>((c) => Database('root'),
          lifecycle: Lifecycle.singleton);
      root.register<Service>((c) => Service(), lifecycle: Lifecycle.scoped);

      final scope1 = root.createScope();
      final scope2 = root.createScope();

      final service1 = scope1.resolve<Service>();
      final service2 = scope2.resolve<Service>();

      expect(service1, isNot(equals(service2)));

      final service1again = scope1.resolve<Service>();
      expect(service1, equals(service1again));

      scope1.dispose();
      scope2.dispose();
      root.dispose();
    });

    test('should work with modules', () {
      final container = DIContainer();
      container.addModule(TestModule());

      final db = container.resolve<Database>();
      expect(db.connectionString, equals('module'));

      container.dispose();
    });

    test('should have different instances in different scopes', () {
      final root = DIContainer();
      root.register<Service>((c) => Service(), lifecycle: Lifecycle.scoped);

      final scope1 = root.createScope();
      final scope2 = root.createScope();

      final instances = <Service>[];

      instances.add(scope1.resolve<Service>());
      instances.add(scope1.resolve<Service>());
      instances.add(scope2.resolve<Service>());
      instances.add(scope2.resolve<Service>());

      expect(instances[0], equals(instances[1]));

      expect(instances[2], equals(instances[3]));

      expect(instances[0], isNot(equals(instances[2])));

      final uniqueInstances = instances.toSet();
      expect(uniqueInstances.length, equals(2));

      scope1.dispose();
      scope2.dispose();
      root.dispose();
    });
  });
}
