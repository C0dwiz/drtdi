import 'package:drtdi/drtdi.dart';
import 'package:meta/meta.dart';
import '../../utils/type_utils.dart';

/// A function that creates an instance of type [T] using the provided [container].
typedef FactoryFunc<T> = T Function(DIContainer container);

/// Holds the registration information for a single dependency in the container.
///
/// Manages the lifecycle ([Lifecycle]) of the dependency instance and provides
/// methods to retrieve or create the instance according to its lifecycle rules.
/// Also handles disposal of disposable instances when the registration is disposed.
class Registration<T> {
  final FactoryFunc<T> factory;
  final Lifecycle lifecycle;
  final String? key;
  T? _instance;
  bool _isDisposed = false;

  /// Creates a new registration for type [T].
  ///
  /// The [factory] function will be called to create instances when needed.
  /// The [lifecycle] determines how instances are cached and reused.
  /// The optional [key] allows multiple registrations for the same type.
  Registration({
    required this.factory,
    required this.lifecycle,
    required this.key,
  });

  /// The cached instance for singleton registrations, or `null` for other lifecycles.
  T? get instance => _instance;

  /// Whether this registration has been disposed.
  bool get isDisposed => _isDisposed;

  /// Retrieves or creates an instance of type [T] according to the registration's lifecycle.
  ///
  /// For [Lifecycle.transient], calls the factory each time.
  /// For [Lifecycle.singleton], caches the instance after the first creation.
  /// For [Lifecycle.scoped], caches the instance in the container's [_scopedInstances] map.
  ///
  /// Throws [ContainerDisposedException] if the registration has been disposed.
  /// Returns the created or cached instance.
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

  /// Builds a unique key for scoped instances.
  ///
  /// Combines the type [T] with the optional [key] to create a unique identifier
  /// for storing scoped instances in the container's map.
  String _buildKey() {
    return key != null ? '$T-$key' : T.toString();
  }

  /// Manually sets the instance for this registration.
  ///
  /// Primarily used when registering pre-existing instances as singletons.
  /// The provided [instance] will be cached and returned for subsequent requests.
  void setInstance(T instance) {
    _instance = instance;
  }

  /// Disposes this registration and its instance if disposable.
  ///
  /// If the cached instance implements [Disposable], its [Disposable.dispose]
  /// method will be called. After disposal, the instance is cleared and
  /// [isDisposed] is set to `true`.
  void dispose() {
    if (_isDisposed) return;

    if (_instance is Disposable) {
      (_instance as Disposable).dispose();
    }

    _instance = null;
    _isDisposed = true;
  }

  /// Resets the cached instance for testing purposes only.
  ///
  /// This method is annotated with `@visibleForTesting` and should not be
  /// used in production code. It clears the cached instance without disposing it.
  @visibleForTesting
  void reset() {
    _instance = null;
  }
}

/// A dependency injection container that manages registration and resolution of dependencies.
///
/// Supports hierarchical containers, three lifecycles ([Lifecycle.transient],
/// [Lifecycle.singleton], [Lifecycle.scoped]), decorators, and circular dependency detection.
/// Implements the [Disposable] interface for proper resource cleanup.
/// Always call [dispose] when the container is no longer needed.
class DIContainer implements Disposable {
  final Map<Type, List<Registration>> _registrations = {};
  final Map<Type, List<Function>> _decorators = {};
  final Map<String, Object> _scopedInstances = {};
  final DIContainer? _parent;
  final List<Disposable> _disposables = [];
  bool _isDisposed = false;
  final List<Type> _resolutionStack = [];

  /// Creates a new [DIContainer].
  ///
  /// An optional [_parent] container can be provided to create a hierarchical
  /// container structure. Child containers can resolve dependencies from parent
  /// containers but cannot modify parent registrations.
  DIContainer([this._parent]);

  /// Registers a factory function for type [T].
  ///
  /// The [factory] function receives this container and returns an instance of [T].
  /// The [lifecycle] parameter controls instance caching:
  /// - [Lifecycle.transient]: New instance each time (default)
  /// - [Lifecycle.singleton]: Single instance for container lifetime
  /// - [Lifecycle.scoped]: Single instance per scope (see [createScope])
  ///
  /// If a [key] is provided, the registration can be resolved using that key.
  /// Registering with the same type and key replaces the previous registration.
  ///
  /// Throws [ContainerDisposedException] if the container has been disposed.
  ///
  /// Example:
  /// ```dart
  /// container.register<Logger>(
  ///   (c) => FileLogger('app.log'),
  ///   lifecycle: Lifecycle.singleton,
  /// );
  /// ```
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

  /// Registers a pre-existing [instance] as a singleton for type [T].
  ///
  /// The instance is immediately available for resolution. If the instance
  /// implements [Disposable], it will be tracked and disposed when the
  /// container is disposed.
  ///
  /// The optional [key] allows named registration. Registering with the same
  /// type and key replaces the previous registration.
  ///
  /// Throws [ContainerDisposedException] if the container has been disposed.
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

  /// Resolves a single instance of type [T] from the container.
  ///
  /// Traverses the container hierarchy (parent containers) if no matching
  /// registration is found in the current container.
  ///
  /// The resolution process:
  /// 1. Checks for circular dependencies using [_resolutionStack]
  /// 2. Finds the appropriate registration by type and optional [key]
  /// 3. Gets the instance according to its lifecycle
  /// 4. Applies any registered decorators for type [T]
  /// 5. Tracks disposable instances for non-transient lifecycles
  ///
  /// Throws [ContainerDisposedException] if the container has been disposed.
  /// Throws [CircularDependencyException] if a circular dependency is detected.
  /// Throws [RegistrationNotFoundException] if no matching registration is found.
  /// Throws [DependencyResolutionException] for other resolution errors.
  ///
  /// Example:
  /// ```dart
  /// final logger = container.resolve<Logger>();
  /// final apiKey = container.resolve<String>(key: 'apiKey');
  /// ```
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

  /// Resolves all registered instances of type [T] from this container and its parents.
  ///
  /// Useful when multiple implementations of the same interface are registered.
  /// Instances are returned in the order they are found (current container first,
  /// then parent containers).
  ///
  /// Applies the same lifecycle, decoration, and disposal tracking as [resolve].
  ///
  /// Throws [ContainerDisposedException] if the container has been disposed.
  /// Throws [DependencyResolutionException] if any instance fails to resolve.
  ///
  /// Example:
  /// ```dart
  /// final validators = container.resolveAll<Validator>();
  /// for (final validator in validators) {
  ///   validator.validate(data);
  /// }
  /// ```
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

  /// Checks if a dependency of type [T] is registered in this container or its parents.
  ///
  /// If a [key] is provided, checks for a registration with that specific key.
  /// Returns `true` if a matching registration is found, `false` otherwise.
  ///
  /// Throws [ContainerDisposedException] if the container has been disposed.
  bool isRegistered<T>({String? key}) {
    _checkDisposed();

    try {
      _findRegistration<T>(key);
      return true;
    } on RegistrationNotFoundException {
      return false;
    }
  }

  /// Creates a new child container with this container as its parent.
  ///
  /// Child containers inherit all registrations from their parent but can
  /// override them with their own registrations. Scoped instances are
  /// managed separately in each container.
  ///
  /// Throws [ContainerDisposedException] if this container has been disposed.
  /// Returns a new [DIContainer] instance.
  DIContainer createScope() {
    _checkDisposed();
    return DIContainer(this);
  }

  /// Adds a decorator function for type [T].
  ///
  /// Decorators are invoked after an instance is created but before it's returned
  /// from [resolve] or [resolveAll]. Multiple decorators for the same type are
  /// applied in the order they were added.
  ///
  /// Throws [ContainerDisposedException] if the container has been disposed.
  ///
  /// Example:
  /// ```dart
  /// container.addDecorator<HttpClient>((client) {
  ///   return LoggingHttpClientDecorator(client);
  /// });
  /// ```
  void addDecorator<T>(T Function(T) decorator) {
    _checkDisposed();

    final type = T;
    if (!_decorators.containsKey(type)) {
      _decorators[type] = [];
    }
    _decorators[type]!.add(decorator);
  }

  /// Validates that all registrations in the container can be successfully resolved.
  ///
  /// Attempts to create an instance of each registered dependency and collects
  /// any errors that occur. This is useful for catching configuration errors
  /// during application startup rather than at runtime.
  ///
  /// Throws [ContainerDisposedException] if the container has been disposed.
  /// Throws [DIException] with details of any validation failures.
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

  /// Disposes the container and all its managed resources.
  ///
  /// Disposes:
  /// 1. All scoped instances that implement [Disposable]
  /// 2. All registrations and their cached instances
  /// 3. All tracked disposable instances
  ///
  /// After disposal, any attempt to use the container will throw
  /// [ContainerDisposedException]. Errors during disposal are caught and
  /// printed to the console but don't stop the disposal process.
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

  /// Finds a registration for type [T] with optional [key] in the container hierarchy.
  ///
  /// Searches the current container first, then recursively searches parent containers.
  /// Throws [RegistrationNotFoundException] if no matching registration is found.
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

  /// Finds all registrations for type [T] in the container hierarchy.
  ///
  /// Returns registrations from the current container first, followed by
  /// registrations from parent containers (closest parent first).
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

  /// Applies all decorators registered for type [T] to the [instance].
  ///
  /// Decorators are applied in the order they were added to the container.
  /// Returns the decorated instance.
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

  /// Checks if the container has been disposed.
  ///
  /// Throws [ContainerDisposedException] if the container is disposed.
  void _checkDisposed() {
    if (_isDisposed) {
      throw ContainerDisposedException();
    }
  }

  /// Returns the total number of registrations in this container (excluding parents).
  ///
  /// This method is annotated with `@visibleForTesting` and should only be
  /// used in unit tests to verify registration counts.
  @visibleForTesting
  int get registrationCount =>
      _registrations.values.fold(0, (sum, list) => sum + list.length);
}
