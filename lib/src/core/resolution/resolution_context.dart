/// Tracks the chain of types being resolved to detect circular dependencies.
///
/// This class maintains a stack of types currently in the resolution process.
/// It is used internally by [DependencyResolver] to prevent infinite recursion
/// when a dependency directly or indirectly references itself.
///
/// Example of a circular dependency:
/// ```dart
/// class A { A(B b); }
/// class B { B(A a); }
/// // Resolving A requires B, which requires A again...
/// ```
class ResolutionContext {
  final List<Type> _resolutionStack = [];

  /// Adds a [type] to the top of the resolution stack.
  ///
  /// This should be called when beginning to resolve a dependency of the given type.
  void push(Type type) {
    _resolutionStack.add(type);
  }

  /// Removes the most recently added type from the resolution stack.
  ///
  /// This should be called when the resolution of a type is complete.
  void pop() {
    _resolutionStack.removeLast();
  }

  /// Checks if the given [type] is currently in the resolution stack.
  ///
  /// Searches from the most recently added to the oldest.
  /// Returns `true` if the type is found in the stack, indicating a circular dependency.
  bool contains(Type type) {
    for (var i = _resolutionStack.length - 1; i >= 0; i--) {
      if (_resolutionStack[i] == type) {
        return true;
      }
    }
    return false;
  }

  /// Returns an unmodifiable view of the current resolution chain.
  ///
  /// The list represents the hierarchy of types being resolved, where the last
  /// element is the most recent type being resolved. This is primarily used for
  /// generating detailed error messages in [CircularDependencyException].
  List<Type> get chain => List.unmodifiable(_resolutionStack);

  /// Clears all types from the resolution stack.
  ///
  /// This method should be used to reset the context, typically when a container
  /// is being cleared or disposed.
  void clear() {
    _resolutionStack.clear();
  }
}
