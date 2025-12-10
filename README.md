# DRTDI - Dart Dependency Injection

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-2.17%2B-blue)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue)](https://flutter.dev)

A lightweight, high-performance dependency injection container for Dart and Flutter with support for multiple lifecycles, scoping, and advanced features.

## 🚀 Features

- **🏗️ Multiple Lifecycles** - Transient, Singleton, and Scoped dependencies
- **🔗 Hierarchical Containers** - Parent-child container relationships
- **🎯 Constructor Injection** - Automatic dependency resolution
- **🏷️ Keyed Registrations** - Multiple implementations of the same interface
- **🎨 Decorators** - Modify instances after creation
- **📦 Module System** - Group related registrations
- **⚡ High Performance** - Optimized for speed and memory usage
- **🧪 Container Validation** - Detect configuration errors early
- **🔄 Disposable Support** - Automatic resource cleanup
- **📱 Flutter Ready** - Perfect for Flutter applications

## 📦 Installation

Add `drtdi` to your `pubspec.yaml`:

```yaml
dependencies:
  drtdi: ^1.0.2
```

## 🎯 Quick Start

### Basic Usage

```dart
import 'package:drtdi/drtdi.dart';

void main() {
  // Create container
  final container = DIContainer();
  
  // Register dependencies
  container.register<ApiService>((c) => ApiService(), 
    lifecycle: Lifecycle.singleton);
  container.register<UserRepository>((c) => UserRepository(c.resolve<ApiService>()));
  container.register<UserService>((c) => UserService(c.resolve<UserRepository>()));
  
  // Resolve dependencies
  final userService = container.resolve<UserService>();
  
  // Validate container configuration
  container.validate();
}
```

### Flutter Integration

```dart
import 'package:flutter/material.dart';
import 'package:drtdi/drtdi.dart';

void main() {
  final container = DIContainer();
  
  // Configure dependencies
  container.register<ApiService>((c) => ApiService(), lifecycle: Lifecycle.singleton);
  container.register<UserRepository>((c) => UserRepository(c.resolve<ApiService>()));
  container.register<UserBloc>((c) => UserBloc(c.resolve<UserRepository>()));
  
  runApp(MyApp(container: container));
}

class MyApp extends StatelessWidget {
  final DIContainer container;
  
  const MyApp({super.key, required this.container});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ContainerProvider(
        container: container,
        child: const HomeScreen(),
      ),
    );
  }
}

class ContainerProvider extends InheritedWidget {
  final DIContainer container;
  
  const ContainerProvider({
    super.key,
    required this.container,
    required super.child,
  });
  
  static ContainerProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ContainerProvider>()!;
  }
  
  @override
  bool updateShouldNotify(ContainerProvider oldWidget) => false;
}

extension ContainerContext on BuildContext {
  DIContainer get container => ContainerProvider.of(this).container;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final userBloc = context.container.resolve<UserBloc>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('DRTDI Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => userBloc.loadUsers(),
          child: const Text('Load Users'),
        ),
      ),
    );
  }
}
```

## 📚 Lifecycles

### Transient
New instance every time:
```dart
container.register<Service>((c) => Service(), 
  lifecycle: Lifecycle.transient);
```

### Singleton
Single instance per container:
```dart
container.register<Service>((c) => Service(), 
  lifecycle: Lifecycle.singleton);
```

### Scoped
Single instance per scope:
```dart
container.register<Service>((c) => Service(), 
  lifecycle: Lifecycle.scoped);

final scope = container.createScope();
final service = scope.resolve<Service>(); // New instance
```

## 🔑 Keyed Registrations

Register multiple implementations of the same interface:

```dart
container.register<Storage>((c) => FileStorage(), key: 'file');
container.register<Storage>((c) => CloudStorage(), key: 'cloud');

final fileStorage = container.resolve<Storage>(key: 'file');
final cloudStorage = container.resolve<Storage>(key: 'cloud');
```

## 🎨 Decorators

Modify instances after creation:

```dart
container.addDecorator<Service>((service) {
  print('Service created at ${DateTime.now()}');
  return LoggingService(service);
});
```

## 📦 Modules

Group related registrations:

```dart
class ApiModule implements DIModule {
  @override
  void configure(DIContainer container) {
    container.register<ApiClient>((c) => ApiClient(), 
      lifecycle: Lifecycle.singleton);
    container.register<UserApi>((c) => UserApi(c.resolve<ApiClient>()));
  }
}

// Use module
container.addModule(ApiModule());
```

## 🔧 Advanced Usage

### Container Builder

Fluent API for container configuration:

```dart
final container = ContainerBuilder()
    .register<Database>((c) => Database())
    .asSingleton()
    .register<UserRepository>((c) => UserRepository(c.resolve<Database>()))
    .asScoped()
    .addModule(ApiModule())
    .build();
```

### Scoped Containers

```dart
final root = DIContainer();
root.register<Service>((c) => Service(), lifecycle: Lifecycle.scoped);

final scope1 = root.createScope();
final scope2 = root.createScope();

final service1 = scope1.resolve<Service>();
final service2 = scope2.resolve<Service>();

print(service1 == service2); // false - different scopes
```

### Disposable Objects

```dart
class Database implements Disposable {
  @override
  void dispose() {
    // Cleanup resources
    print('Database disposed');
  }
}

container.register<Database>((c) => Database(), 
  lifecycle: Lifecycle.singleton);

// Automatically disposed when container is disposed
container.dispose();
```

## ⚡ Performance

DRTDI is optimized for performance:

```dart
// Benchmark Results
SimpleTransient(RunTime): 3.984322354236861 us.
DeepTransient(RunTime): 19.186531567342165 us.
Singleton(RunTime): 4.195086666666667 us.
MixedLifecycle(RunTime): 4.15242 us.
ScopeCreation(RunTime): 11.840668376323931 us.
```

## 🧪 Testing

Easy testing with dependency mocking:

```dart
test('should test with mocked dependencies', () {
  final container = DIContainer();
  
  // Register mock implementation
  container.register<ApiService>((c) => MockApiService());
  container.register<UserRepository>((c) => UserRepository(c.resolve<ApiService>()));
  
  final userRepository = container.resolve<UserRepository>();
  
  // Test with mocked dependencies
  expect(userRepository, isA<UserRepository>());
});
```

## 🎯 API Reference

### Core Classes

- `DIContainer` - Main dependency injection container
- `ContainerScope` - Scoped container for isolated dependency graphs
- `DependencyRegistration` - Individual dependency registration
- `Lifecycle` - Lifecycle enum (Transient, Singleton, Scoped)

### Key Methods

- `register<T>()` - Register a dependency
- `resolve<T>()` - Resolve a dependency
- `resolveAll<T>()` - Resolve all implementations of a type
- `createScope()` - Create a scoped container
- `addModule()` - Add a configuration module
- `validate()` - Validate container configuration
- `dispose()` - Clean up resources

## 🔍 Error Handling

DRTDI provides clear error messages:

```dart
try {
  container.resolve<UnregisteredService>();
} on RegistrationNotFoundException catch (e) {
  print(e.message); // "No registration found for type UnregisteredService"
}

try {
  container.resolve<ServiceA>(); // ServiceA depends on ServiceB which depends on ServiceA
} on CircularDependencyException catch (e) {
  print(e.message); // "Circular dependency detected: ServiceA -> ServiceB -> ServiceA"
}
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development

```bash
# Clone repository
git clone https://github.com/c0dwiz/drtdi.git

# Run tests
flutter test

# Run benchmarks
dart benchmark/performance_benchmark.dart

# Run examples
dart example/basic_usage.dart
```

## 📄 License

DRTDI is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

Thanks to all contributors and the Dart/Flutter community for inspiration and support.

---

<div align="center">

**Built with ❤️ for the Dart and Flutter community**

[📖 Documentation](https://c0dwiz.github.io/doc/api/) •
[🐛 Report Bug](https://github.com/c0dwiz/drtdi/issues) •
[💡 Request Feature](https://github.com/c0dwiz/drtdi/issues)

</div>