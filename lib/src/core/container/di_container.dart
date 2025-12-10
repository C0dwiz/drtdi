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

/// A dependency injection container that manages the registration and
/// resolution of dependencies.
///
/// The container supports different lifecycles ([Lifecycle]), scopes,
/// decorators, and modules. It implements the [Disposable] interface to
/// properly clean up resources. Always call [dispose] when the container is
/// no longer needed.
class DIContainer implements Disposable {
  final Map<Type, Map<String, DependencyRegistration>> _registrations = {};
  final Map<Type, List<Function>> _decorators = {};
  final Map<String, dynamic> _scopedInstances = {};
  final List<Disposable> _disposables = [];
  final ResolutionContext _resolutionContext = ResolutionContext();
  late final DependencyResolver _resolver;

  final DIContainer? parent;
  bool _isDisposed = false;

  /// Creates a new [DIContainer].
  ///
  /// An optional [parent] container can be provided to create a hierarchical
  /// container. The child container can resolve dependencies from its parent.
  DIContainer([this.parent]) {
    _resolver = DependencyResolver(this, _resolutionContext);
  }

  DependencyResolver get resolver => _resolver;

  /// An unmodifiable view of the registrations map.
  ///
  /// The outer map key is the dependency type, the inner map key is the
  /// registration key (or empty string for default).
  Map<Type, Map<String, DependencyRegistration>> get registrationsMap =>
      Map.unmodifiable(_registrations);

  /// An unmodifiable view of registrations grouped by type.
  ///
  /// Returns a map where each key is a dependency type and the value is an
  /// unmodifiable list of all [DependencyRegistration]s for that type.
  Map<Type, List<DependencyRegistration>> get registrations {
    final result = <Type, List<DependencyRegistration>>{};
    for (final entry in _registrations.entries) {
      result[entry.key] = List.unmodifiable(entry.value.values);
    }
    return Map.unmodifiable(result);
  }

  /// An unmodifiable view of all registered decorators.
  Map<Type, List<Function>> get decorators => Map.unmodifiable(_decorators);

  /// The map of scoped instances currently held by this container.
  Map<String, dynamic> get scopedInstances => _scopedInstances;

  /// A list of disposable objects tracked by this container.
  List<Disposable> get disposables => _disposables;

  /// Resolves a single instance of type [T] from the container.
  ///
  /// The optional [key] parameter is used to resolve named registrations.
  /// Dependencies are resolved according to their lifecycle and the current
  /// resolution context.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  /// Throws a [RegistrationNotFoundException] if no registration for type [T]
  /// (and optional [key]) is found.
  ///
  /// Example:
  /// ```dart
  /// final myService = container.resolve<MyService>();
  /// final namedService = container.resolve<MyService>(key: 'backup');
  /// ```
  T resolve<T>({String? key}) {
    _checkDisposed();
    return _resolver.resolve<T>(key: key);
  }

  /// Resolves all registered instances of type [T].
  ///
  /// Useful when multiple implementations of the same interface are registered.
  /// Returns instances in the order they were registered.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  List<T> resolveAll<T>() {
    _checkDisposed();
    return _resolver.resolveAll<T>();
  }

  /// Checks if a dependency of type [T] is registered in this container.
  ///
  /// The optional [key] parameter checks for a named registration.
  /// Returns `true` if a matching registration exists, `false` otherwise.
  /// This method does not consider registrations in parent containers.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  bool isRegistered<T>({String? key}) {
    _checkDisposed();
    try {
      _resolver.findRegistration<T>(key: key);
      return true;
    } on RegistrationNotFoundException {
      return false;
    }
  }

  /// Creates a new child container with this container as its parent.
  ///
  /// The child container inherits all registrations from its parent but
  /// can override them. Scoped instances are managed separately.
  ///
  /// Throws a [ContainerDisposedException] if this container has been disposed.
  ///
  /// Returns a new [DIContainer] instance.
  DIContainer createScope() {
    _checkDisposed();
    return DIContainer(this);
  }

  /// Registers a factory function for type [T].
  ///
  /// The [factory] function is called to create instances when needed.
  /// The [lifecycle] controls how instances are cached and reused:
  /// - [Lifecycle.transient]: A new instance is created every time.
  /// - [Lifecycle.singleton]: A single instance is reused for the container's lifetime.
  /// - [Lifecycle.scoped]: A single instance is reused within a [ContainerScope].
  ///
  /// The optional [key] allows multiple registrations for the same type.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  /// Throws a [DuplicateRegistrationException] if a registration for the same
  /// type and key already exists.
  ///
  /// Example:
  /// ```dart
  /// container.register<ApiService>(
  ///   (c) => ApiServiceImpl(c.resolve<HttpClient>()),
  ///   lifecycle: Lifecycle.singleton,
  /// );
  /// ```
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

  /// Registers a pre-created [instance] as a singleton for type [T].
  ///
  /// The instance is immediately available for resolution and will be returned
  /// for all subsequent requests for type [T] (with the optional [key]).
  /// If the instance implements [Disposable], it will be tracked and disposed
  /// when the container is disposed.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  /// Throws a [DuplicateRegistrationException] if a registration for the same
  /// type and key already exists.
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

  /// Adds a pre-configured [DependencyRegistration] to the container.
  ///
  /// This method provides full control over the registration configuration.
  /// It's useful for advanced scenarios where the standard [register] method
  /// is insufficient.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  /// Throws a [DuplicateRegistrationException] if a registration for the same
  /// type and key already exists.
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

  /// Configures the container using a [DIModule].
  ///
  /// Modules are a way to organize and group related registrations.
  /// The [module]'s `configure` method is called with this container as
  /// an argument.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  void addModule(DIModule module) {
    _checkDisposed();
    module.configure(this);
  }

  /// Adds a decorator function for type [T].
  ///
  /// Decorators are called after an instance of type [T] is resolved,
  /// allowing for cross-cutting concerns like logging or caching.
  /// Multiple decorators for the same type are executed in the order they
  /// were added.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  ///
  /// Example:
  /// ```dart
  /// container.addDecorator<ApiService>((instance) {
  ///   return LoggingApiServiceDecorator(instance);
  /// });
  /// ```
  void addDecorator<T>(T Function(T) decorator) {
    _checkDisposed();
    CollectionUtils.addToMapList(_decorators, T, decorator);
  }

  /// Validates the container's configuration.
  ///
  /// This method checks for common configuration errors, such as circular
  /// dependencies or missing registrations. It should be called before using
  /// the container in production, preferably during application startup.
  ///
  /// Throws a [ContainerDisposedException] if the container has been disposed.
  /// Throws a [ContainerValidationException] if validation fails.
  void validate() {
    _checkDisposed();
    ContainerValidator.validate(this);
  }

  /// Disposes the container and all its managed resources.
  ///
  /// This method disposes all tracked [Disposable] instances, clears all
  /// registrations, and marks the container as disposed. After calling
  /// [dispose], any attempt to use the container will throw a
  /// [ContainerDisposedException]. Calling [dispose] multiple times has no
  /// effect after the first call.
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

  /// Clears all registrations and state for testing purposes only.
  ///
  /// This method is annotated with `@visibleForTesting` and should not be
  /// used in production code. It resets the container to an empty state.
  @visibleForTesting
  void clear() {
    _registrations.clear();
    _decorators.clear();
    _scopedInstances.clear();
    _disposables.clear();
    _resolutionContext.clear();
  }
}
