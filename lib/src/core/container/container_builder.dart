import 'package:drtdi/drtdi.dart';

class ContainerBuilder {
  final DIContainer container;

  ContainerBuilder() : container = DIContainer();

  ContainerBuilder.withParent(DIContainer parent)
      : container = DIContainer(parent);

  RegistrationBuilder<T> register<T>(FactoryFunc<T> factory) {
    return RegistrationBuilder<T>(factory);
  }

  void addRegistration<T>(DependencyRegistration<T> registration) {
    container.addRegistration(registration);
  }

  void registerInstance<T>(T instance, {String? key}) {
    container.registerInstance<T>(instance, key: key);
  }

  void addModule(DIModule module) {
    container.addModule(module);
  }

  void addDecorator<T>(T Function(T) decorator) {
    container.addDecorator<T>(decorator);
  }

  DIContainer build() {
    container.validate();
    return container;
  }
}
