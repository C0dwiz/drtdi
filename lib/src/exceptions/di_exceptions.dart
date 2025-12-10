/// Custom exceptions for dependency injection operations.
///
/// This library defines a hierarchy of exceptions that are thrown by the
/// dependency injection container during registration, resolution, and
/// validation operations. All exceptions extend [DIException] and provide
/// detailed error messages to help diagnose configuration issues.
///
/// See also:
/// - [DIContainer] for the main container class that throws these exceptions
/// - [DependencyResolver] for resolution-specific exceptions

/// Base exception class for all dependency injection related errors.
///
/// All specific DI exceptions extend this class, allowing consumers to catch
/// either specific exception types or all DI-related exceptions at once.
///
/// Example:
/// ```dart
/// try {
///   final service = container.resolve<MyService>();
/// } on DIException catch (e) {
///   // Handle any DI-related error
///   logger.error('Dependency injection failed: $e');
/// }
/// ```
class DIException implements Exception {
  /// A descriptive message explaining the error.
  final String message;

  /// Creates a new DI exception with the given [message].
  DIException(this.message);

  @override
  String toString() => 'DIException: $message';
}

/// Thrown when a dependency cannot be resolved for reasons other than
/// missing registration or circular dependencies.
///
/// This exception typically indicates an error within a factory function
/// or a lifecycle-specific issue. It serves as a catch-all for resolution
/// errors that don't fit other more specific exception categories.
///
/// Example scenarios:
/// - Factory function throws an exception
/// - Lifecycle management error (e.g., scoped instance disposal during resolution)
/// - Type casting or conversion errors during resolution
///
/// See also:
/// - [DependencyResolver.resolve] which may throw this exception
class DependencyResolutionException extends DIException {
  /// Creates a new dependency resolution exception with the given [message].
  DependencyResolutionException(String message) : super(message);
}

/// Thrown when a circular dependency is detected during resolution.
///
/// A circular dependency occurs when a type directly or indirectly depends
/// on itself. The container uses [ResolutionContext] to track the resolution
/// chain and throws this exception when a type appears twice in the chain.
///
/// The [dependencyChain] property contains the complete resolution path
/// that led to the circular dependency, which is useful for debugging.
///
/// Example:
/// ```dart
/// // This configuration will cause a circular dependency
/// container.register<ServiceA>((c) => ServiceA(c.resolve<ServiceB>()));
/// container.register<ServiceB>((c) => ServiceB(c.resolve<ServiceA>()));
///
/// // Throws: CircularDependencyException: ServiceA -> ServiceB -> ServiceA
/// final service = container.resolve<ServiceA>();
/// ```
///
/// To fix circular dependencies, consider:
/// 1. Using property injection instead of constructor injection
/// 2. Introducing an interface to break the direct dependency
/// 3. Using a lazy resolution pattern
class CircularDependencyException extends DIException {
  /// The chain of types being resolved when the circular dependency was detected.
  ///
  /// The list represents the resolution path, with the last element being
  /// the type that caused the circular reference. For example, if resolving
  /// `ServiceA` requires `ServiceB`, which requires `ServiceA` again, the
  /// chain would be `[ServiceA, ServiceB, ServiceA]`.
  final List<Type> dependencyChain;

  /// Creates a new circular dependency exception with the given [dependencyChain].
  ///
  /// The exception message is automatically generated to show the dependency
  /// chain in a human-readable format.
  CircularDependencyException(this.dependencyChain)
      : super(
            'Circular dependency detected: ${dependencyChain.map((t) => t.toString()).join(' -> ')}');
}

/// Thrown when attempting to use a disposed container or registration.
///
/// This exception is thrown by any method on [DIContainer], [ContainerScope],
/// or [DependencyRegistration] after the object has been disposed. Once
/// disposed, these objects cannot be used for any operations.
///
/// Example:
/// ```dart
/// final container = DIContainer();
/// container.register<Service>((c) => Service());
/// container.dispose();
///
/// // Throws ContainerDisposedException
/// final service = container.resolve<Service>();
/// ```
///
/// Always check if a container is still needed before disposing it, or
/// implement proper lifecycle management to ensure disposed containers
/// are not accessed.
class ContainerDisposedException extends DIException {
  /// Creates a new container disposed exception.
  ///
  /// The exception message is fixed as this exception doesn't require
  /// additional context.
  ContainerDisposedException() : super('Container has been disposed');
}

/// Thrown when no registration is found for a requested type (and optional key).
///
/// This exception is thrown when attempting to resolve a type that hasn't
/// been registered in the container or any of its parent containers.
///
/// Example:
/// ```dart
/// container.register<Service>((c) => Service());
///
/// // Throws RegistrationNotFoundException for `AnotherService`
/// final service = container.resolve<AnotherService>();
///
/// // Throws RegistrationNotFoundException for key 'special'
/// final special = container.resolve<Service>(key: 'special');
/// ```
///
/// To avoid this exception:
/// 1. Ensure all required types are registered before resolution
/// 2. Check if a type is registered using [DIContainer.isRegistered]
/// 3. Provide fallback values or optional dependencies where appropriate
class RegistrationNotFoundException extends DIException {
  /// Creates a new registration not found exception.
  ///
  /// The [type] parameter specifies the type that was requested.
  /// The optional [key] parameter specifies the registration key that was requested.
  ///
  /// The exception message clearly indicates whether a key was involved.
  RegistrationNotFoundException(Type type, [String? key])
      : super(
            'No registration found for type $type${key != null ? " with key \'$key\'" : ""}');
}

/// Thrown when attempting to register a duplicate type/key combination.
///
/// The container does not allow multiple registrations for the same type
/// and key combination within the same container. This exception helps
/// prevent accidental overwrites of existing registrations.
///
/// Example:
/// ```dart
/// container.register<Service>((c) => ServiceV1());
///
/// // Throws DuplicateRegistrationException
/// container.register<Service>((c) => ServiceV2());
///
/// // This is allowed - different key
/// container.register<Service>((c) => ServiceV2(), key: 'v2');
/// ```
///
/// To fix duplicate registration issues:
/// 1. Use different keys for different implementations of the same type
/// 2. Remove the existing registration before adding a new one
/// 3. Use [ContainerBuilder] which allows replacing registrations
class DuplicateRegistrationException extends DIException {
  /// Creates a new duplicate registration exception.
  ///
  /// The [type] parameter specifies the type that has duplicate registrations.
  /// The optional [key] parameter specifies the registration key that caused
  /// the duplicate (if any).
  ///
  /// The exception message clearly indicates whether a key was involved.
  DuplicateRegistrationException(Type type, [String? key])
      : super(
            'Duplicate registration for type $type${key != null ? " with key \'$key\'" : ""}');
}
