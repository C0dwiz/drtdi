import '../core/container/di_container.dart';

/// A configuration module for organizing related dependency registrations.
///
/// Modules provide a way to group and organize dependency registrations by
/// feature, layer, or concern. By implementing this interface, you can create
/// reusable configuration units that can be loaded into a container using
/// [DIContainer.addModule].
///
/// Modules are especially useful for:
/// - Separating configuration code from application logic
/// - Creating reusable component libraries
/// - Enabling feature toggles by conditionally loading modules
/// - Simplifying testing by providing test-specific modules
///
/// Example implementation:
/// ```dart
/// class ApiModule implements DIModule {
///   @override
///   void configure(DIContainer container) {
///     container.register<HttpClient>(
///       (c) => HttpClientImpl(baseUrl: 'https://api.example.com'),
///       lifecycle: Lifecycle.singleton,
///     );
///
///     container.register<AuthService>(
///       (c) => AuthServiceImpl(c.resolve<HttpClient>()),
///       lifecycle: Lifecycle.scoped,
///     );
///
///     container.register<UserService>(
///       (c) => UserServiceImpl(c.resolve<HttpClient>(), c.resolve<AuthService>()),
///     );
///   }
/// }
///
/// // Usage:
/// final container = DIContainer();
/// container.addModule(ApiModule());
/// container.addModule(DatabaseModule());
/// ```
///
/// See also:
/// - [DIContainer.addModule] for loading modules into a container
/// - [ContainerBuilder.addModule] for fluent module registration
abstract class DIModule {
  /// Configures the dependency registrations for this module.
  ///
  /// This method is called by the container when the module is added.
  /// Implementations should use the provided [container] to register
  /// all dependencies that belong to this module.
  ///
  /// The [container] parameter is the container to configure with this module's registrations.
  void configure(DIContainer container);
}
