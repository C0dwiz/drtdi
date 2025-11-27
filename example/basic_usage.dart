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

void main() {
  final container = DIContainer();

  container.register<Database>((c) => Database('postgresql://localhost:5432'),
      lifecycle: Lifecycle.singleton);

  container.register<Repository>((c) => Repository(c.resolve<Database>()));
  container.register<UserService>(
      (c) => UserService(c.resolve<Repository>(), c.resolve<Database>()));

  final userService = container.resolve<UserService>();
  print(
      'User service created with database: ${userService.db.connectionString}');

  container.validate();
  container.dispose();
}
