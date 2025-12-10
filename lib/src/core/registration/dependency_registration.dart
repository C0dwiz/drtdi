import 'package:drtdi/drtdi.dart';

/// A function that creates an instance of type [T] using the provided [container].
typedef FactoryFunc<T> = T Function(DIContainer container);

/// Represents a configurable registration for a single dependency within a [DIContainer].
///
/// Encapsulates a factory function, its [Lifecycle], and manages the caching and disposal
/// of the created instance according to that lifecycle. Implements [Disposable] to
/// properly clean up resources when the container is disposed.
///
/// See also:
/// - [Lifecycle] for details on different lifetime management strategies.
/// - [RegistrationBuilder] for a fluent API to create instances of this class.
class DependencyRegistration<T> implements Disposable {
  final FactoryFunc<T> factory;
  final Lifecycle lifecycle;
  final String? key;
  T? _instance;
  bool _isDisposed = false;
  final String _instanceKey;

  /// Creates a new dependency registration.
  ///
  /// The [factory] function is called to create instances when needed.
  /// The [lifecycle] determines how instances are cached and reused.
  /// The optional [key] allows multiple registrations for the same type.
  DependencyRegistration({
    required this.factory,
    required this.lifecycle,
    required this.key,
  }) : _instanceKey = _buildInstanceKey(T, key);

  /// The cached instance for singleton registrations.
  ///
  /// Returns `null` for registrations with [Lifecycle.transient] or [Lifecycle.scoped]
  /// lifecycles, or if no instance has been created yet for a singleton.
  T? get instance => _instance;

  /// Whether this registration has been disposed.
  bool get isDisposed => _isDisposed;

  /// Creates or retrieves an instance of [T] according to the configured [lifecycle].
  ///
  /// The behavior depends on the [lifecycle]:
  /// - [Lifecycle.transient]: Calls the [factory] function and returns a new instance.
  /// - [Lifecycle.singleton]: Returns the cached instance, creating it via [factory] on the first call.
  /// - [Lifecycle.scoped]: Returns the instance cached in the container's `scopedInstances` map,
  ///   creating it via [factory] on the first call within that scope.
  ///
  /// Throws a [ContainerDisposedException] if this registration has been disposed.
  /// Returns the resolved instance.
  T resolve(DIContainer container) {
    if (_isDisposed) {
      throw ContainerDisposedException();
    }

    switch (lifecycle) {
      case Lifecycle.transient:
        return factory(container);
      case Lifecycle.singleton:
        return _instance ??= factory(container);
      case Lifecycle.scoped:
        final instances = container.scopedInstances;
        return instances[_instanceKey] ??= factory(container);
    }
  }

  /// Builds a unique key for storing scoped instances in a container's map.
  ///
  /// Combines the [type] and optional [key] to create a string identifier.
  /// This key is used internally to store and retrieve scoped instances.
  static String _buildInstanceKey(Type type, String? key) {
    return key != null ? '$type-$key' : type.toString();
  }

  /// Manually sets the cached [instance] for this registration.
  ///
  /// Primarily used when registering a pre-existing object as a singleton
  /// via methods like [DIContainer.registerInstance]. Overwrites any previously cached instance.
  void setInstance(T instance) {
    _instance = instance;
  }

  /// Disposes this registration and its cached instance if it implements [Disposable].
  ///
  /// If a singleton instance has been created and implements [Disposable],
  /// its `dispose` method will be called. The cached instance is then cleared.
  /// After calling this method, [isDisposed] returns `true`.
  @override
  void dispose() {
    if (_isDisposed) return;

    if (_instance is Disposable) {
      (_instance as Disposable).dispose();
    }

    _instance = null;
    _isDisposed = true;
  }

  /// Clears the cached instance without disposing it.
  ///
  /// **Warning**: This method is intended for testing scenarios (e.g., resetting
  /// container state between tests). It does not call `dispose` on the instance.
  void reset() {
    _instance = null;
  }
}
