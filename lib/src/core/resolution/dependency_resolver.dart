import 'package:drtdi/drtdi.dart';
import 'package:drtdi/src/core/resolution/resolution_context.dart';

/// Orchestrates the resolution of dependencies from a [DIContainer].
///
/// Manages the complete resolution process including:
/// - Circular dependency detection using [ResolutionContext]
/// - Finding appropriate registrations (including parent container lookup)
/// - Creating instances according to their lifecycle
/// - Applying decorators to instances
/// - Tracking disposable instances for non-transient lifecycles
///
/// This class encapsulates the core resolution logic that is used by
/// [DIContainer.resolve] and [DIContainer.resolveAll].
class DependencyResolver {
  final DIContainer container;
  final ResolutionContext resolutionContext;

  /// Creates a resolver for the given [container] and [resolutionContext].
  DependencyResolver(this.container, this.resolutionContext);

  /// Resolves a single instance of type [T] from the container.
  ///
  /// The resolution process follows these steps:
  /// 1. Checks for circular dependencies using [resolutionContext]
  /// 2. Finds the appropriate [DependencyRegistration] for type [T] and optional [key]
  /// 3. Creates or retrieves the instance according to its [Lifecycle]
  /// 4. Applies any registered decorators for type [T]
  /// 5. Registers the instance for disposal if it's non-transient and [Disposable]
  ///
  /// Throws [CircularDependencyException] if a circular dependency is detected.
  /// Throws [RegistrationNotFoundException] if no matching registration is found.
  /// Throws [DependencyResolutionException] for other resolution errors.
  ///
  /// Example:
  /// ```dart
  /// final resolver = container.resolver;
  /// final service = resolver.resolve<MyService>();
  /// final named = resolver.resolve<String>(key: 'apiKey');
  /// ```
  T resolve<T>({String? key}) {
    final type = T;
    if (resolutionContext.contains(type)) {
      throw CircularDependencyException([...resolutionContext.chain, type]);
    }

    resolutionContext.push(type);
    try {
      final registration = findRegistration<T>(key: key);
      final instance = registration.resolve(container);
      final decoratedInstance = _applyDecorators<T>(instance);
      _registerDisposableIfNeeded(registration, decoratedInstance);
      return decoratedInstance;
    } catch (e) {
      if (e is DIException) rethrow;
      throw DependencyResolutionException('Failed to resolve $T: $e');
    } finally {
      resolutionContext.pop();
    }
  }

  /// Resolves all registered instances of type [T] from the container hierarchy.
  ///
  /// Searches for all registrations of type [T] in the current container and
  /// all parent containers. Each instance is resolved independently with the
  /// full resolution process (lifecycle, decoration, disposal tracking).
  ///
  /// Returns a list of instances in the order they are found (current container
  /// registrations first, then parent container registrations).
  ///
  /// Throws [DependencyResolutionException] if any instance fails to resolve.
  ///
  /// Example:
  /// ```dart
  /// final resolvers = container.resolver.resolveAll<IValidator>();
  /// for (final validator in validators) {
  ///   if (validator.canValidate(data)) {
  ///     validator.validate(data);
  ///   }
  /// }
  /// ```
  List<T> resolveAll<T>() {
    final registrations = findAllRegistrations<T>();
    final instances = <T>[];
    final type = T;

    for (final registration in registrations) {
      resolutionContext.push(type);
      try {
        final instance = registration.resolve(container);
        final decoratedInstance = _applyDecorators<T>(instance);
        _registerDisposableIfNeeded(registration, decoratedInstance);
        instances.add(decoratedInstance);
      } catch (e) {
        if (e is DIException) rethrow;
        throw DependencyResolutionException('Failed to resolve $T: $e');
      } finally {
        resolutionContext.pop();
      }
    }

    return instances;
  }

  /// Finds a single [DependencyRegistration] for type [T] with optional [key].
  ///
  /// Search order:
  /// 1. Exact match for type and key in the current container
  /// 2. Default registration (empty key) for the type in current container
  /// 3. Recursive search in parent container (if exists)
  ///
  /// Throws [RegistrationNotFoundException] if no matching registration is found
  /// in the container hierarchy.
  ///
  /// Returns the found [DependencyRegistration<T>].
  DependencyRegistration<T> findRegistration<T>({String? key}) {
    final type = T;
    final searchKey = key ?? '';

    final typeRegistrations = container.registrationsMap[type];
    if (typeRegistrations != null) {
      final registration = typeRegistrations[searchKey];
      if (registration != null) {
        return registration as DependencyRegistration<T>;
      }

      if (searchKey.isNotEmpty) {
        final defaultRegistration = typeRegistrations[''];
        if (defaultRegistration != null) {
          return defaultRegistration as DependencyRegistration<T>;
        }
      }
    }

    if (container.parent != null) {
      return container.parent!.resolver.findRegistration<T>(key: key);
    }

    throw RegistrationNotFoundException(
        type, searchKey.isEmpty ? null : searchKey);
  }

  /// Finds all [DependencyRegistration]s for type [T] in the container hierarchy.
  ///
  /// Returns registrations from the current container first, followed by
  /// registrations from parent containers (closest parent first).
  /// This method does not throw if no registrations are found - it returns an empty list.
  ///
  /// Returns a list of all found [DependencyRegistration<T>] instances.
  List<DependencyRegistration<T>> findAllRegistrations<T>() {
    final result = <DependencyRegistration<T>>[];
    final type = T;

    final typeRegistrations = container.registrationsMap[type];
    if (typeRegistrations != null) {
      result.addAll(typeRegistrations.values.cast<DependencyRegistration<T>>());
    }

    if (container.parent != null) {
      result.addAll(container.parent!.resolver.findAllRegistrations<T>());
    }

    return result;
  }

  /// Applies all decorators registered for type [T] to the given [instance].
  ///
  /// Decorators are applied in the order they were registered in the container.
  /// If no decorators are registered for type [T], returns the original [instance].
  ///
  /// Returns the decorated instance.
  T _applyDecorators<T>(T instance) {
    final type = T;
    final decorators = container.decorators[type];
    if (decorators != null) {
      var result = instance;
      for (final decorator in decorators) {
        result = (decorator as T Function(T))(result);
      }
      return result;
    }
    return instance;
  }

  /// Registers a [Disposable] [instance] for later disposal if needed.
  ///
  /// Only registers instances with non-transient lifecycles ([Lifecycle.singleton]
  /// or [Lifecycle.scoped]) since transient instances are not cached by the container.
  /// The instance is added to the container's [DIContainer.disposables] list.
  void _registerDisposableIfNeeded<T>(
      DependencyRegistration<T> registration, T instance) {
    if (registration.lifecycle != Lifecycle.transient &&
        instance is Disposable) {
      container.disposables.add(instance);
    }
  }
}
