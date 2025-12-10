import 'package:drtdi/drtdi.dart';

/// Utility methods for type-related operations used throughout the DI framework.
///
/// These methods provide common functionality for working with types, type names,
/// and type checks that are needed in multiple places within the dependency
/// injection system.
class TypeUtils {
  /// Gets a string representation of type [T].
  ///
  /// This method provides a consistent way to get type names throughout the
  /// framework. It's primarily used for debugging, logging, and generating
  /// human-readable error messages.
  ///
  /// Example:
  /// ```dart
  /// print(TypeUtils.getTypeName<String>()); // "String"
  /// print(TypeUtils.getTypeName<DIContainer>()); // "DIContainer"
  /// ```
  ///
  /// Returns a string representation of type [T].
  static String getTypeName<T>() {
    return T.toString();
  }

  /// Checks if an [instance] implements the [Disposable] interface.
  ///
  /// This type check is used throughout the DI container to determine whether
  /// an instance needs to be tracked for disposal. It's a convenience method
  /// that provides a more semantic name than the standard `is` operator.
  ///
  /// Example:
  /// ```dart
  /// final myService = MyService();
  /// if (TypeUtils.isDisposable(myService)) {
  ///   // Track for disposal
  ///   container.disposables.add(myService as Disposable);
  /// }
  /// ```
  ///
  /// Returns `true` if the [instance] implements [Disposable], `false` otherwise.
  static bool isDisposable<T>(T instance) {
    return instance is Disposable;
  }

  /// Builds a unique registration key from a [type] and optional [key].
  ///
  /// This method generates keys used internally by the container to identify
  /// registrations, particularly for scoped instances. The format ensures
  /// uniqueness for different type/key combinations.
  ///
  /// The generated key format is:
  /// - `TypeName` when only type is provided
  /// - `TypeName-key` when both type and key are provided
  ///
  /// Example:
  /// ```dart
  /// TypeUtils.buildRegistrationKey(String); // "String"
  /// TypeUtils.buildRegistrationKey(Logger, 'file'); // "Logger-file"
  /// TypeUtils.buildRegistrationKey(ApiService, 'default'); // "ApiService-default"
  /// ```
  ///
  /// The [type] parameter is the type to use in the key.
  /// The [key] parameter is an optional string key to append.
  /// Returns a unique string key for the type and optional key combination.
  static String buildRegistrationKey(Type type, [String? key]) {
    return key != null ? '$type-$key' : type.toString();
  }
}
