import 'package:test/test.dart';
import 'package:drtdi/drtdi.dart';
import '../../test_utils/test_classes.dart';

void main() {
  group('DIContainer', () {
    late DIContainer container;

    setUp(() {
      container = DIContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should resolve transient dependency', () {
      var counter = 0;
      final instances = <Service>[];

      container.register<Service>((c) {
        counter++;
        final service = Service();
        instances.add(service);
        return service;
      }, lifecycle: Lifecycle.transient);

      final instance1 = container.resolve<Service>();
      final instance2 = container.resolve<Service>();

      expect(instance1, isNot(equals(instance2)));

      expect(counter, equals(2));

      expect(instances.toSet().length, equals(2));
    });

    test('should resolve singleton dependency', () {
      var counter = 0;

      container.register<Service>((c) {
        counter++;
        return Service();
      }, lifecycle: Lifecycle.singleton);

      final instance1 = container.resolve<Service>();
      final instance2 = container.resolve<Service>();

      expect(instance1, equals(instance2));
      expect(counter, equals(1));
    });

    test('should resolve with key', () {
      container.register<Storage>((c) => FileStorage(), key: 'file');
      container.register<Storage>((c) => CloudStorage(), key: 'cloud');

      final fileStorage = container.resolve<Storage>(key: 'file');
      final cloudStorage = container.resolve<Storage>(key: 'cloud');

      expect(fileStorage, isA<FileStorage>());
      expect(cloudStorage, isA<CloudStorage>());
    });

    test('should resolve all implementations', () {
      container.register<Storage>((c) => FileStorage(), key: 'file');
      container.register<Storage>((c) => CloudStorage(), key: 'cloud');

      final storages = container.resolveAll<Storage>();

      expect(storages, hasLength(2));
      expect(storages[0], isA<FileStorage>());
      expect(storages[1], isA<CloudStorage>());
    });

    test('should check if type is registered', () {
      container.register<Service>((c) => Service());

      expect(container.isRegistered<Service>(), isTrue);
      expect(container.isRegistered<Database>(), isFalse);
    });

    test('should detect circular dependencies', () {
      container.register<A>((c) => A(c.resolve<B>()));
      container.register<B>((c) => B(c.resolve<A>()));

      expect(() => container.resolve<A>(),
          throwsA(isA<CircularDependencyException>()));
    });

    test('should validate container', () {
      container.register<Service>((c) => Service());

      expect(() => container.validate(), returnsNormally);
    });

    test('should throw on validation failure', () {
      container.register<A>((c) => A(c.resolve<B>()));

      expect(() => container.validate(), throwsA(isA<DIException>()));
    });

    test('should dispose disposable objects', () {
      final db = Database('test');
      final repo = Repository(db);

      container.registerInstance<Database>(db);
      container.registerInstance<Repository>(repo);

      container.resolve<Database>();
      container.resolve<Repository>();

      container.dispose();

      expect(db.isDisposed, isTrue);
      expect(repo.isDisposed, isTrue);
    });

    test('should work with registration builder', () {
      final registration = RegistrationBuilder<Service>((c) => Service())
          .asSingleton()
          .withKey('test')
          .build();

      container.addRegistration(registration);

      final service1 = container.resolve<Service>(key: 'test');
      final service2 = container.resolve<Service>(key: 'test');

      expect(service1, equals(service2));
    });
  });
}
