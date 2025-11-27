class ResolutionContext {
  final List<Type> _resolutionStack = [];

  void push(Type type) {
    _resolutionStack.add(type);
  }

  void pop() {
    _resolutionStack.removeLast();
  }

  bool contains(Type type) {
    for (var i = _resolutionStack.length - 1; i >= 0; i--) {
      if (_resolutionStack[i] == type) {
        return true;
      }
    }
    return false;
  }

  List<Type> get chain => List.unmodifiable(_resolutionStack);

  void clear() {
    _resolutionStack.clear();
  }
}
