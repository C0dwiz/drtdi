class DIException implements Exception {
  final String message;
  DIException(this.message);

  @override
  String toString() => 'DIException: $message';
}

class DependencyResolutionException extends DIException {
  DependencyResolutionException(String message) : super(message);
}

class CircularDependencyException extends DIException {
  final List<Type> dependencyChain;

  CircularDependencyException(this.dependencyChain)
      : super(
            'Circular dependency detected: ${dependencyChain.map((t) => t.toString()).join(' -> ')}');
}

class ContainerDisposedException extends DIException {
  ContainerDisposedException() : super('Container has been disposed');
}

class RegistrationNotFoundException extends DIException {
  RegistrationNotFoundException(Type type, [String? key])
      : super(
            'No registration found for type $type${key != null ? " with key '$key'" : ""}');
}

class DuplicateRegistrationException extends DIException {
  DuplicateRegistrationException(Type type, [String? key])
      : super(
            'Duplicate registration for type $type${key != null ? " with key '$key'" : ""}');
}
