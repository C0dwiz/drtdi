import 'package:drtdi/drtdi.dart';
import 'package:drtdi/src/core/resolution/resolution_context.dart';

class DependencyResolver {
  final DIContainer container;
  final ResolutionContext resolutionContext;

  DependencyResolver(this.container, this.resolutionContext);

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

  void _registerDisposableIfNeeded<T>(
      DependencyRegistration<T> registration, T instance) {
    if (registration.lifecycle != Lifecycle.transient &&
        instance is Disposable) {
      container.disposables.add(instance);
    }
  }
}
