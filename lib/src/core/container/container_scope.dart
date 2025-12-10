import 'package:drtdi/drtdi.dart';

/// A scoped lifetime context for a dependency injection container.
///
/// The scope controls the lifetime of dependencies with [Lifecycle.scoped]
/// lifecycle. When a scope is [dispose]d, all disposable instances created
/// within that scope are disposed. Attempting to use a disposed scope will
/// throw a [ContainerDisposedException].
class ContainerScope implements Disposable {
  final DIContainer _container;
  bool _isDisposed = false;

  /// Creates a new [ContainerScope] for the given [container].
  ContainerScope(this._container);

  /// Resolves a single instance of type [T] from the container.
  ///
  /// If a dependency is registered with a [key], it must be provided to
  /// resolve the correct instance. Dependencies are resolved according to
  /// the container's registration and lifecycle rules.
  ///
  /// Throws a [ContainerDisposedException] if the scope has been disposed.
  /// Throws a [RegistrationNotFoundException] if no registration for type [T]
  /// (and optional [key]) is found.
  ///
  /// Example:
  /// ```dart
  /// final myService = scope.resolve<MyService>();
  /// final namedService = scope.resolve<MyService>(key: 'special');
  /// ```
  T resolve<T>({String? key}) {
    _checkDisposed();
    return _container.resolve<T>(key: key);
  }

  /// Resolves all registered instances of type [T] from the container.
  ///
  /// This method is useful when multiple implementations of the same interface
  /// are registered. They are returned in the order of registration.
  ///
  /// Throws a [ContainerDisposedException] if the scope has been disposed.
  ///
  /// Example:
  /// ```dart
  /// final validators = scope.resolveAll<Validator>();
  /// for (final validator in validators) {
  ///   validator.validate(data);
  /// }
  /// ```
  List<T> resolveAll<T>() {
    _checkDisposed();
    return _container.resolveAll<T>();
  }

  /// Checks if a dependency of type [T] is registered in the container.
  ///
  /// The optional [key] can be used to check for a named registration.
  /// Returns `true` if a matching registration exists, `false` otherwise.
  ///
  /// Throws a [ContainerDisposedException] if the scope has been disposed.
  bool isRegistered<T>({String? key}) {
    _checkDisposed();
    return _container.isRegistered<T>(key: key);
  }

  /// Creates a new nested scope from the current scope.
  ///
  /// Nested scopes inherit registrations from their parent but manage their
  /// own set of scoped instances. Disposing a child scope does not affect
  /// the parent scope.
  ///
  /// Throws a [ContainerDisposedException] if the current scope has been
  /// disposed.
  ///
  /// Returns a new [ContainerScope] instance.
  ContainerScope createScope() {
    _checkDisposed();
    return ContainerScope(_container.createScope());
  }

  /// Disposes the scope and all disposable instances created within it.
  ///
  /// After calling this method, any attempt to use the scope will result in
  /// a [ContainerDisposedException]. Calling [dispose] multiple times has no
  /// effect after the first call.
  @override
  void dispose() {
    if (_isDisposed) return;
    _container.dispose();
    _isDisposed = true;
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw ContainerDisposedException();
    }
  }
}