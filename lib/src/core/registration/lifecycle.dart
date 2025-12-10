/// Defines the lifetime and caching behavior of a dependency instance within a container.
///
/// The lifecycle determines how many times a factory function is called and how
/// long the created instance is retained and reused by the dependency injection container.
enum Lifecycle {
  /// A new instance is created every time the dependency is resolved.
  ///
  /// No caching is performed. The factory function is executed on each resolution request.
  /// This is suitable for lightweight, stateless services or services that should not
  /// share state between consumers.
  transient,

  /// A single instance is created and reused for the entire lifetime of the container.
  ///
  /// The instance is created on first resolution and then cached. The same instance
  /// is returned for all subsequent resolution requests within the same container.
  /// Disposable instances are disposed when the container is disposed.
  singleton,

  /// A single instance is created and reused within a specific [ContainerScope].
  ///
  /// Similar to singleton, but the instance is tied to a specific scope rather than
  /// the root container. Different scopes will have different instances.
  /// This is useful for unit-of-work patterns or request-specific data in web applications.
  /// Disposable instances are disposed when the scope that created them is disposed.
  scoped,
}
