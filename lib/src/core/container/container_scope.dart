import 'package:drtdi/drtdi.dart';

class ContainerScope implements Disposable {
  final DIContainer _container;
  bool _isDisposed = false;

  ContainerScope(this._container);

  T resolve<T>({String? key}) {
    _checkDisposed();
    return _container.resolve<T>(key: key);
  }

  List<T> resolveAll<T>() {
    _checkDisposed();
    return _container.resolveAll<T>();
  }

  bool isRegistered<T>({String? key}) {
    _checkDisposed();
    return _container.isRegistered<T>(key: key);
  }

  ContainerScope createScope() {
    _checkDisposed();
    return ContainerScope(_container.createScope());
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _container.dispose();
    _isDisposed = true;
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw ContainerDisposedException();
    }
  }
}
