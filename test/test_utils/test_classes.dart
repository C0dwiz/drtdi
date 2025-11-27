import 'package:drtdi/drtdi.dart';

class Service {
  static int _counter = 0;
  final String id;

  Service()
      : id = 'Service-${_counter++}-${DateTime.now().millisecondsSinceEpoch}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Service{id: $id}';
}

class Repository implements Disposable {
  final Database db;
  bool isDisposed = false;

  Repository(this.db);

  @override
  void dispose() {
    isDisposed = true;
  }
}

class Database implements Disposable {
  final String connectionString;
  bool isDisposed = false;

  Database(this.connectionString);

  @override
  void dispose() {
    isDisposed = true;
  }
}

class UserService {
  final Repository repository;
  final Database db;

  UserService(this.repository, this.db);
}

class AuthService {
  final UserService userService;
  final Database db;

  AuthService(this.userService, this.db);
}

abstract class Storage {}

class FileStorage implements Storage {}

class CloudStorage implements Storage {}

class A {
  final B b;
  A(this.b);
}

class B {
  final A a;
  B(this.a);
}

class TestModule implements DIModule {
  @override
  void configure(DIContainer container) {
    container.register<Database>((c) => Database('module'),
        lifecycle: Lifecycle.singleton);
  }
}
