import 'dependency_registration.dart';
import 'lifecycle.dart';

/// A fluent builder for configuring and creating [DependencyRegistration] instances.
///
/// Provides a chainable API to configure the key, lifecycle, and other properties
/// of a dependency registration before building the final [DependencyRegistration] object.
/// This pattern is especially useful when used in conjunction with a [ContainerBuilder].
///
/// Example:
/// ```dart
/// final registration = RegistrationBuilder<ApiService>((c) => ApiServiceImpl())
///   .withKey('default')
///   .asSingleton()
///   .build();
/// ```
class RegistrationBuilder<T> {
  final FactoryFunc<T> factory;
  String? _key;
  Lifecycle _lifecycle = Lifecycle.transient;

  /// Creates a new [RegistrationBuilder] for type [T] with the given [factory].
  ///
  /// The [factory] function will be called by the container to create instances
  /// of type [T] when needed. The default lifecycle is [Lifecycle.transient].
  RegistrationBuilder(this.factory);

  /// Assigns a [key] to the registration.
  ///
  /// Keys allow multiple registrations for the same type to be distinguished
  /// during resolution. Returns this builder for method chaining.
  RegistrationBuilder<T> withKey(String key) {
    _key = key;
    return this;
  }

  /// Configures the registration to have [Lifecycle.singleton] lifecycle.
  ///
  /// The container will create a single instance that will be reused for the
  /// lifetime of the container. Returns this builder for method chaining.
  RegistrationBuilder<T> asSingleton() {
    _lifecycle = Lifecycle.singleton;
    return this;
  }

  /// Configures the registration to have [Lifecycle.scoped] lifecycle.
  ///
  /// The container will create a single instance that will be reused within
  /// the same scope ([ContainerScope]). Returns this builder for method chaining.
  RegistrationBuilder<T> asScoped() {
    _lifecycle = Lifecycle.scoped;
    return this;
  }

  /// Configures the registration to have [Lifecycle.transient] lifecycle.
  ///
  /// The container will create a new instance every time the dependency is
  /// resolved. This is the default lifecycle. Returns this builder for method chaining.
  RegistrationBuilder<T> asTransient() {
    _lifecycle = Lifecycle.transient;
    return this;
  }

  /// Configures the registration with a custom [lifecycle].
  ///
  /// This method provides full control over the lifecycle setting.
  /// Returns this builder for method chaining.
  RegistrationBuilder<T> withLifecycle(Lifecycle lifecycle) {
    _lifecycle = lifecycle;
    return this;
  }

  /// Builds and returns a [DependencyRegistration] with the configured properties.
  ///
  /// This method finalizes the configuration and creates an immutable
  /// registration object that can be added to a container.
  ///
  /// Returns a new [DependencyRegistration<T>] instance.
  DependencyRegistration<T> build() {
    return DependencyRegistration<T>(
      factory: factory,
      lifecycle: _lifecycle,
      key: _key,
    );
  }
}
