import 'package:drtdi/drtdi.dart';

typedef FactoryFunc<T> = T Function(DIContainer container);

class DependencyRegistration<T> implements Disposable {
  final FactoryFunc<T> factory;
  final Lifecycle lifecycle;
  final String? key;
  T? _instance;
  bool _isDisposed = false;
  final String _instanceKey;

  DependencyRegistration({
    required this.factory,
    required this.lifecycle,
    required this.key,
  }) : _instanceKey = _buildInstanceKey(T, key);

  T? get instance => _instance;
  bool get isDisposed => _isDisposed;

  T resolve(DIContainer container) {
    if (_isDisposed) {
      throw ContainerDisposedException();
    }

    switch (lifecycle) {
      case Lifecycle.transient:
        return factory(container);
      case Lifecycle.singleton:
        return _instance ??= factory(container);
      case Lifecycle.scoped:
        final instances = container.scopedInstances;
        return instances[_instanceKey] ??= factory(container);
    }
  }

  static String _buildInstanceKey(Type type, String? key) {
    return key != null ? '$type-$key' : type.toString();
  }

  void setInstance(T instance) {
    _instance = instance;
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    if (_instance is Disposable) {
      (_instance as Disposable).dispose();
    }

    _instance = null;
    _isDisposed = true;
  }

  void reset() {
    _instance = null;
  }
}
