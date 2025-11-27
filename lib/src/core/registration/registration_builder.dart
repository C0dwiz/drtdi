import 'dependency_registration.dart';
import 'lifecycle.dart';

class RegistrationBuilder<T> {
  final FactoryFunc<T> factory;
  String? _key;
  Lifecycle _lifecycle = Lifecycle.transient;

  RegistrationBuilder(this.factory);

  RegistrationBuilder<T> withKey(String key) {
    _key = key;
    return this;
  }

  RegistrationBuilder<T> asSingleton() {
    _lifecycle = Lifecycle.singleton;
    return this;
  }

  RegistrationBuilder<T> asScoped() {
    _lifecycle = Lifecycle.scoped;
    return this;
  }

  RegistrationBuilder<T> asTransient() {
    _lifecycle = Lifecycle.transient;
    return this;
  }

  RegistrationBuilder<T> withLifecycle(Lifecycle lifecycle) {
    _lifecycle = lifecycle;
    return this;
  }

  DependencyRegistration<T> build() {
    return DependencyRegistration<T>(
      factory: factory,
      lifecycle: _lifecycle,
      key: _key,
    );
  }
}
