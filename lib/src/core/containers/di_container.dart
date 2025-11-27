import 'package:drtdi/drtdi.dart';
import 'package:meta/meta.dart';
import '../../utils/type_utils.dart';

typedef FactoryFunc<T> = T Function(DIContainer container);

class Registration<T> {
  final FactoryFunc<T> factory;
  final Lifecycle lifecycle;
  final String? key;
  T? _instance;
  bool _isDisposed = false;

  Registration({
    required this.factory,
    required this.lifecycle,
    required this.key,
  });

  T? get instance => _instance;
  bool get isDisposed => _isDisposed;

  T getInstance(DIContainer container) {
    if (_isDisposed) {
      throw ContainerDisposedException();
    }

    switch (lifecycle) {
      case Lifecycle.transient:
        return factory(container);
      case Lifecycle.singleton:
        _instance ??= factory(container);
        return _instance!;
      case Lifecycle.scoped:
        final instanceKey = _buildKey();
        if (!container._scopedInstances.containsKey(instanceKey)) {
          container._scopedInstances[instanceKey] = factory(container)!;
        }
        return container._scopedInstances[instanceKey] as T;
    }
  }

  String _buildKey() {
    return key != null ? '$T-$key' : T.toString();
  }

  void setInstance(T instance) {
    _instance = instance;
  }

  void dispose() {
    if (_isDisposed) return;

    if (_instance is Disposable) {
      (_instance as Disposable).dispose();
    }

    _instance = null;
    _isDisposed = true;
  }

  @visibleForTesting
  void reset() {
    _instance = null;
  }
}

class DIContainer implements Disposable {
  final Map<Type, List<Registration>> _registrations = {};
  final Map<Type, List<Function>> _decorators = {};
  final Map<String, Object> _scopedInstances = {};
  final DIContainer? _parent;
  final List<Disposable> _disposables = [];
  bool _isDisposed = false;
  final List<Type> _resolutionStack = [];

  DIContainer([this._parent]);

  void register<T>(
    FactoryFunc<T> factory, {
    String? key,
    Lifecycle lifecycle = Lifecycle.transient,
  }) {
    _checkDisposed();

    final registration = Registration<T>(
      factory: factory,
      lifecycle: lifecycle,
      key: key,
    );

    final type = T;
    if (!_registrations.containsKey(type)) {
      _registrations[type] = [];
    }

    _registrations[type]!.removeWhere((r) => (r as Registration<T>).key == key);

    _registrations[type]!.add(registration);
  }

  void registerInstance<T>(T instance, {String? key}) {
    _checkDisposed();

    final registration = Registration<T>(
      factory: (_) => instance,
      lifecycle: Lifecycle.singleton,
      key: key,
    );
    registration.setInstance(instance);

    final type = T;
    if (!_registrations.containsKey(type)) {
      _registrations[type] = [];
    }

    _registrations[type]!.removeWhere((r) => (r as Registration<T>).key == key);
    _registrations[type]!.add(registration);

    if (TypeUtils.isDisposable(instance)) {
      _disposables.add(instance as Disposable);
    }
  }

  T resolve<T>({String? key}) {
    _checkDisposed();

    if (_resolutionStack.contains(T)) {
      throw CircularDependencyException([..._resolutionStack, T]);
    }

    try {
      _resolutionStack.add(T);
      final registration = _findRegistration<T>(key);
      var instance = registration.getInstance(this);

      instance = _applyDecorators<T>(instance);

      if (registration.lifecycle != Lifecycle.transient &&
          TypeUtils.isDisposable(instance)) {
        _disposables.add(instance as Disposable);
      }

      return instance;
    } catch (e) {
      if (e is DIException) rethrow;
      throw DependencyResolutionException('Failed to resolve $T: $e');
    } finally {
      _resolutionStack.remove(T);
    }
  }

  List<T> resolveAll<T>() {
    _checkDisposed();

    final registrations = _findAllRegistrations<T>();
    final instances = <T>[];

    for (final registration in registrations) {
      try {
        _resolutionStack.add(T);
        var instance = registration.getInstance(this);
        instance = _applyDecorators<T>(instance);

        if (registration.lifecycle != Lifecycle.transient &&
            TypeUtils.isDisposable(instance)) {
          _disposables.add(instance as Disposable);
        }

        instances.add(instance);
      } catch (e) {
        if (e is DIException) rethrow;
        throw DependencyResolutionException('Failed to resolve $T: $e');
      } finally {
        _resolutionStack.remove(T);
      }
    }

    return instances;
  }

  bool isRegistered<T>({String? key}) {
    _checkDisposed();

    try {
      _findRegistration<T>(key);
      return true;
    } on RegistrationNotFoundException {
      return false;
    }
  }

  DIContainer createScope() {
    _checkDisposed();
    return DIContainer(this);
  }

  void addDecorator<T>(T Function(T) decorator) {
    _checkDisposed();

    final type = T;
    if (!_decorators.containsKey(type)) {
      _decorators[type] = [];
    }
    _decorators[type]!.add(decorator);
  }

  void validate() {
    _checkDisposed();

    final errors = <String>[];

    for (final entry in _registrations.entries) {
      for (final registration in entry.value) {
        try {
          registration.getInstance(this);
        } catch (e) {
          errors.add(
              '${entry.key}${registration.key != null ? " (key: ${registration.key})" : ""}: $e');
        }
      }
    }

    if (errors.isNotEmpty) {
      throw DIException('Container validation failed:\n${errors.join('\n')}');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    for (final instance in _scopedInstances.values) {
      if (instance is Disposable) {
        try {
          instance.dispose();
        } catch (e) {
          print('Error disposing scoped instance $instance: $e');
        }
      }
    }
    _scopedInstances.clear();

    for (final registrations in _registrations.values) {
      for (final registration in registrations) {
        registration.dispose();
      }
    }

    for (final disposable in _disposables) {
      try {
        disposable.dispose();
      } catch (e) {
        print('Error disposing $disposable: $e');
      }
    }

    _disposables.clear();
    _registrations.clear();
    _decorators.clear();
    _isDisposed = true;
  }

  Registration<T> _findRegistration<T>(String? key) {
    final type = T;

    if (_registrations.containsKey(type)) {
      final registrations = _registrations[type]!.cast<Registration<T>>();

      Registration<T>? foundRegistration;
      if (key != null) {
        foundRegistration = registrations.firstWhere(
          (r) => r.key == key,
          orElse: () => throw RegistrationNotFoundException(type, key),
        );
      } else {
        if (registrations.isNotEmpty) {
          foundRegistration = registrations.first;
        }
      }

      if (foundRegistration != null) {
        return foundRegistration;
      }
    }

    if (_parent != null) {
      return _parent!._findRegistration<T>(key);
    }

    throw RegistrationNotFoundException(type, key);
  }

  List<Registration<T>> _findAllRegistrations<T>() {
    final result = <Registration<T>>[];

    final type = T;
    if (_registrations.containsKey(type)) {
      result.addAll(_registrations[type]!.cast<Registration<T>>());
    }

    if (_parent != null) {
      result.addAll(_parent!._findAllRegistrations<T>());
    }

    return result;
  }

  T _applyDecorators<T>(T instance) {
    final type = T;
    if (_decorators.containsKey(type)) {
      var result = instance;
      for (final decorator in _decorators[type]!) {
        result = (decorator as T Function(T))(result);
      }
      return result;
    }
    return instance;
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw ContainerDisposedException();
    }
  }

  @visibleForTesting
  int get registrationCount =>
      _registrations.values.fold(0, (sum, list) => sum + list.length);
}
