import 'package:meta/meta.dart';

import '../../exceptions/di_exceptions.dart';
import '../../interfaces/disposable.dart';
import '../../interfaces/module.dart';
import '../../utils/collection_utils.dart';

import '../registration/dependency_registration.dart';
import '../registration/lifecycle.dart';

import '../resolution/dependency_resolver.dart';
import '../resolution/resolution_context.dart';
import '../validation/container_validator.dart';

class DIContainer implements Disposable {
  final Map<Type, Map<String, DependencyRegistration>> _registrations = {};
  final Map<Type, List<Function>> _decorators = {};
  final Map<String, dynamic> _scopedInstances = {};
  final List<Disposable> _disposables = [];
  final ResolutionContext _resolutionContext = ResolutionContext();
  late final DependencyResolver _resolver;

  final DIContainer? parent;
  bool _isDisposed = false;

  DIContainer([this.parent]) {
    _resolver = DependencyResolver(this, _resolutionContext);
  }

  DependencyResolver get resolver => _resolver;

  Map<Type, Map<String, DependencyRegistration>> get registrationsMap =>
      Map.unmodifiable(_registrations);

  Map<Type, List<DependencyRegistration>> get registrations {
    final result = <Type, List<DependencyRegistration>>{};
    for (final entry in _registrations.entries) {
      result[entry.key] = List.unmodifiable(entry.value.values);
    }
    return Map.unmodifiable(result);
  }

  Map<Type, List<Function>> get decorators => Map.unmodifiable(_decorators);

  Map<String, dynamic> get scopedInstances => _scopedInstances;

  List<Disposable> get disposables => _disposables;

  T resolve<T>({String? key}) {
    _checkDisposed();
    return _resolver.resolve<T>(key: key);
  }

  List<T> resolveAll<T>() {
    _checkDisposed();
    return _resolver.resolveAll<T>();
  }

  bool isRegistered<T>({String? key}) {
    _checkDisposed();
    try {
      _resolver.findRegistration<T>(key: key);
      return true;
    } on RegistrationNotFoundException {
      return false;
    }
  }

  DIContainer createScope() {
    _checkDisposed();
    return DIContainer(this);
  }

  void register<T>(
    FactoryFunc<T> factory, {
    String? key,
    Lifecycle lifecycle = Lifecycle.transient,
  }) {
    _checkDisposed();
    final registration = DependencyRegistration<T>(
      factory: factory,
      lifecycle: lifecycle,
      key: key,
    );
    _addRegistration(registration);
  }

  void registerInstance<T>(T instance, {String? key}) {
    _checkDisposed();
    final registration = DependencyRegistration<T>(
      factory: (_) => instance,
      lifecycle: Lifecycle.singleton,
      key: key,
    );
    registration.setInstance(instance);
    _addRegistration(registration);

    if (instance is Disposable) {
      _disposables.add(instance);
    }
  }

  void addRegistration<T>(DependencyRegistration<T> registration) {
    _checkDisposed();
    _addRegistration(registration);
  }

  void _addRegistration<T>(DependencyRegistration<T> registration) {
    final type = T;
    final key = registration.key ?? '';

    if (!_registrations.containsKey(type)) {
      _registrations[type] = {};
    }

    final typeRegistrations = _registrations[type]!;

    if (typeRegistrations.containsKey(key)) {
      throw DuplicateRegistrationException(type, key.isEmpty ? null : key);
    }

    typeRegistrations[key] = registration;
  }

  void addModule(DIModule module) {
    _checkDisposed();
    module.configure(this);
  }

  void addDecorator<T>(T Function(T) decorator) {
    _checkDisposed();
    CollectionUtils.addToMapList(_decorators, T, decorator);
  }

  void validate() {
    _checkDisposed();
    ContainerValidator.validate(this);
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    for (final instance in _scopedInstances.values) {
      if (instance is Disposable) {
        instance.dispose();
      }
    }
    _scopedInstances.clear();

    for (final typeRegistrations in _registrations.values) {
      for (final registration in typeRegistrations.values) {
        registration.dispose();
      }
    }
    _registrations.clear();

    for (final disposable in _disposables) {
      disposable.dispose();
    }
    _disposables.clear();

    _decorators.clear();
    _resolutionContext.clear();
    _isDisposed = true;
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw ContainerDisposedException();
    }
  }

  @visibleForTesting
  void clear() {
    _registrations.clear();
    _decorators.clear();
    _scopedInstances.clear();
    _disposables.clear();
    _resolutionContext.clear();
  }
}
