import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:drtdi/drtdi.dart';

class SimpleTransientBenchmark extends BenchmarkBase {
  SimpleTransientBenchmark() : super('SimpleTransient');

  late DIContainer container;

  @override
  void setup() {
    container = DIContainer();
    container.register<A>((c) => A());
  }

  @override
  void teardown() {
    container.dispose();
  }

  @override
  void run() {
    container.resolve<A>();
  }
}

class DeepTransientBenchmark extends BenchmarkBase {
  DeepTransientBenchmark() : super('DeepTransient');

  late DIContainer container;

  @override
  void setup() {
    container = DIContainer();
    container.register<A>((c) => A());
    container.register<B>((c) => B(c.resolve<A>()));
    container.register<C>((c) => C(c.resolve<B>()));
    container.register<D>((c) => D(c.resolve<C>()));
  }

  @override
  void teardown() {
    container.dispose();
  }

  @override
  void run() {
    container.resolve<D>();
  }
}

class SingletonBenchmark extends BenchmarkBase {
  SingletonBenchmark() : super('Singleton');

  late DIContainer container;

  @override
  void setup() {
    container = DIContainer();
    container.register<A>((c) => A(), lifecycle: Lifecycle.singleton);
    container.register<B>((c) => B(c.resolve<A>()),
        lifecycle: Lifecycle.singleton);
  }

  @override
  void teardown() {
    container.dispose();
  }

  @override
  void run() {
    container.resolve<B>();
  }
}

class MixedLifecycleBenchmark extends BenchmarkBase {
  MixedLifecycleBenchmark() : super('MixedLifecycle');

  late DIContainer container;

  @override
  void setup() {
    container = DIContainer();
    container.register<A>((c) => A(), lifecycle: Lifecycle.singleton);
    container.register<B>((c) => B(c.resolve<A>()),
        lifecycle: Lifecycle.transient);
    container.register<C>((c) => C(c.resolve<B>()),
        lifecycle: Lifecycle.scoped);
  }

  @override
  void teardown() {
    container.dispose();
  }

  @override
  void run() {
    container.resolve<C>();
  }
}

class ScopeBenchmark extends BenchmarkBase {
  ScopeBenchmark() : super('ScopeCreation');

  late DIContainer root;

  @override
  void setup() {
    root = DIContainer();
    root.register<A>((c) => A(), lifecycle: Lifecycle.singleton);
    root.register<B>((c) => B(c.resolve<A>()), lifecycle: Lifecycle.scoped);
  }

  @override
  void teardown() {
    root.dispose();
  }

  @override
  void run() {
    final scope = root.createScope();
    scope.resolve<B>();
    scope.dispose();
  }
}

class A {
  final String id = 'A';
}

class B {
  final A a;
  B(this.a);
}

class C {
  final B b;
  C(this.b);
}

class D {
  final C c;
  D(this.c);
}

void main() {
  print('=== Performance Benchmarks ===');
  SimpleTransientBenchmark().report();
  DeepTransientBenchmark().report();
  SingletonBenchmark().report();
  MixedLifecycleBenchmark().report();
  ScopeBenchmark().report();
}
