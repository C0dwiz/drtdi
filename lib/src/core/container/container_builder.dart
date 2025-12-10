import 'package:drtdi/drtdi.dart';

/// A builder for configuring and creating a [DIContainer].
///
/// Provides a fluent, type-safe API for registering dependencies and
/// configuring the container before it's built. Ensures the container is
/// validated upon building.
class ContainerBuilder {
  /// The container being configured by this builder.
  final DIContainer container;

  /// Creates a [ContainerBuilder] for a new root container.
  ContainerBuilder() : container = DIContainer();

  /// Creates a [ContainerBuilder] for a child container with the given [parent].
  ContainerBuilder.withParent(DIContainer parent)
      : container = DIContainer(parent);

  /// Starts registration of type [T] using a [factory] function.
  ///
  /// This method returns a [RegistrationBuilder] which allows chaining
  /// configuration options like lifecycle and key in a fluent style.
  ///
  /// Example:
  /// ```dart
  /// builder.register<ApiService>((c) => ApiServiceImpl())
  ///   .asSingleton()
  ///   .withKey('default');
  /// ```
  RegistrationBuilder<T> register<T>(FactoryFunc<T> factory) {
    return RegistrationBuilder<T>(factory);
  }

  /// Adds a pre-configured [DependencyRegistration] to the container.
  ///
  /// This is a lower-level method for adding registrations that have already
  /// been built, for example, by a [RegistrationBuilder].
  void addRegistration<T>(DependencyRegistration<T> registration) {
    container.addRegistration(registration);
  }

  /// Registers a pre-created [instance] as a singleton.
  ///
  /// See [DIContainer.registerInstance] for details.
  void registerInstance<T>(T instance, {String? key}) {
    container.registerInstance<T>(instance, key: key);
  }

  /// Adds a configuration module to the container.
  ///
  /// See [DIContainer.addModule] for details.
  void addModule(DIModule module) {
    container.addModule(module);
  }

  /// Adds a decorator for type [T] to the container.
  ///
  /// See [DIContainer.addDecorator] for details.
  void addDecorator<T>(T Function(T) decorator) {
    container.addDecorator<T>(decorator);
  }

  /// Validates and returns the configured container.
  ///
  /// This method calls [DIContainer.validate] on the underlying container
  /// and then returns it. After calling [build], the builder should not
  /// be used further.
  ///
  /// Throws a [ContainerValidationException] if validation fails.
  ///
  /// Returns the fully configured and validated [DIContainer].
  DIContainer build() {
    container.validate();
    return container;
  }
}