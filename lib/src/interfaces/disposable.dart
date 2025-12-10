/// An interface for objects that require explicit cleanup of resources.
///
/// Classes that hold resources such as file handles, network connections,
/// database connections, or native memory should implement this interface
/// to ensure proper cleanup when they are no longer needed.
///
/// The dependency injection container automatically tracks and disposes
/// [Disposable] instances for non-transient lifecycles ([Lifecycle.singleton]
/// and [Lifecycle.scoped]) when the container or scope is disposed.
///
/// Example implementation:
/// ```dart
/// class DatabaseConnection implements Disposable {
///   final Connection _connection;
///
///   DatabaseConnection(this._connection);
///
///   Future<void> query(String sql) {
///     return _connection.execute(sql);
///   }
///
///   @override
///   void dispose() {
///     _connection.close();
///     print('Database connection closed');
///   }
/// }
///
/// // Registration with automatic disposal:
/// container.registerInstance<DatabaseConnection>(DatabaseConnection(connection));
/// // The connection will be automatically disposed when the container is disposed
/// ```
///
/// Important implementation guidelines:
/// 1. Implementations should be idempotent (calling [dispose] multiple times should be safe)
/// 2. After [dispose] is called, the object should not be used
/// 3. Implementations should release all held resources in the [dispose] method
///
/// See also:
/// - [DIContainer] which tracks and disposes disposable instances
/// - [ContainerScope] which manages disposable instances within a scope
/// - [DependencyRegistration] which handles disposal of registered instances
/// - [Lifecycle] which determines when instances are tracked for disposal
abstract class Disposable {
  /// Releases all resources held by this object.
  ///
  /// This method should be called when the object is no longer needed.
  /// After calling this method, the object should generally not be used,
  /// though some implementations may define specific post-disposal behavior.
  ///
  /// Implementation notes:
  /// - Should handle multiple calls gracefully (be idempotent)
  /// - Should not throw exceptions if possible (log instead)
  /// - Should release all managed and unmanaged resources
  /// - Should set internal state to indicate the object is disposed
  void dispose();
}
