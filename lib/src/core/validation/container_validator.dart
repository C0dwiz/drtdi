import '../../exceptions/di_exceptions.dart';
import '../container/di_container.dart';

/// Provides validation utilities for dependency injection containers.
///
/// This class contains static methods to verify the integrity and correctness
/// of a container's configuration before it is used in production.
/// Validation helps catch configuration errors early, such as missing
/// dependencies or misconfigured lifecycles.
class ContainerValidator {
  /// Validates that all registrations in the container can be successfully resolved.
  ///
  /// This method attempts to resolve every registered dependency in the container.
  /// If any registration fails to resolve (throws an exception), the error is
  /// collected and included in a comprehensive validation report.
  ///
  /// **Important Considerations:**
  /// - This operation may have side effects: singleton and scoped instances
  ///   created during validation will be cached in the container.
  /// - Transient instances are created and immediately discarded.
  /// - The validation does not reset the container state after completion.
  ///
  /// Typical errors caught during validation include:
  /// - Missing dependencies ([RegistrationNotFoundException])
  /// - Circular dependencies ([CircularDependencyException])
  /// - Factory function exceptions
  ///
  /// Usage example:
  /// ```dart
  /// final container = DIContainer();
  /// container.register<ServiceA>((c) => ServiceA());
  /// container.register<ServiceB>((c) => ServiceB(c.resolve<ServiceA>()));
  ///
  /// // Validate before using the container
  /// try {
  ///   ContainerValidator.validate(container);
  ///   print('Container validation passed!');
  /// } on DIException catch (e) {
  ///   print('Container validation failed: ${e.message}');
  /// }
  /// ```
  ///
  /// Throws a [DIException] if one or more registrations fail to resolve.
  /// The exception message contains detailed information about each failure.
  ///
  /// The [container] parameter is the container to validate.
  static void validate(DIContainer container) {
    final errors = <String>[];

    for (final entry in container.registrationsMap.entries) {
      final type = entry.key;
      final registrationsByKey = entry.value;

      for (final registrationEntry in registrationsByKey.entries) {
        final key = registrationEntry.key;
        final registration = registrationEntry.value;

        try {
          registration.resolve(container);
        } catch (e) {
          final keyDescription = key.isEmpty ? '' : " with key '$key'";
          errors.add('$type$keyDescription: $e');
        }
      }
    }

    if (errors.isNotEmpty) {
      throw DIException('Container validation failed:\n${errors.join('\n')}');
    }
  }
}