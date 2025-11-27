import 'package:drtdi/drtdi.dart';

class Database implements Disposable {
  final String connectionString;

  Database(this.connectionString);

  @override
  void dispose() {
    print('Database disposed: $connectionString');
  }
}

class Repository implements Disposable {
  final Database db;

  Repository(this.db);

  @override
  void dispose() {
    print('Repository disposed');
  }
}

class UserService {
  final Repository repository;
  final Database db;

  UserService(this.repository, this.db);
}

class TestModule implements DIModule {
  @override
  void configure(DIContainer container) {
    container.register<Database>((c) => Database('module'),
        lifecycle: Lifecycle.singleton);
  }
}

void main() {
  final container = DIContainer();

  container.register<Database>((c) => Database('main'),
      lifecycle: Lifecycle.singleton);

  container.register<Repository>((c) => Repository(c.resolve<Database>()),
      lifecycle: Lifecycle.scoped);

  container.register<UserService>((c) => UserService(
        c.resolve<Repository>(),
        c.resolve<Database>(),
      ));

  container.addDecorator<UserService>((service) {
    print('UserService created at ${DateTime.now()}');
    return service;
  });

  container.addModule(TestModule());

  final scope1 = container.createScope();
  final scope2 = container.createScope();

  final userService1 = scope1.resolve<UserService>();
  final userService2 = scope2.resolve<UserService>();

  print('User services from different scopes: ${userService1 == userService2}');
  print('UserService1 repository: ${userService1.repository}');
  print('UserService2 repository: ${userService2.repository}');

  scope1.dispose();
  scope2.dispose();
  container.dispose();
}
