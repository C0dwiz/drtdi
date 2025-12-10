/// Utility methods for working with collections, particularly maps containing lists.
///
/// These helper methods simplify common patterns when dealing with `Map<K, List<V>>`
/// data structures, which are used extensively in the dependency injection container
/// for managing registrations and decorators.
///
/// This class is marked as internal utility and is primarily used by the DI framework itself.
class CollectionUtils {
  /// Adds a [value] to a list in a map, creating the list if it doesn't exist.
  ///
  /// This is a convenience method for the common pattern of storing multiple
  /// values per key in a map. It ensures that a list exists for the given [key]
  /// in the [map] before adding the [value].
  ///
  /// Example:
  /// ```dart
  /// final decorators = <Type, List<Function>>{};
  /// // Instead of:
  /// // if (!decorators.containsKey(Logger)) decorators[Logger] = [];
  /// // decorators[Logger]!.add(myDecorator);
  /// // Use:
  /// CollectionUtils.addToMapList(decorators, Logger, myDecorator);
  /// ```
  ///
  /// The [map] parameter is the map to modify (keys of type K, values are List<V>).
  /// The [key] parameter is the key at which to add the value.
  /// The [value] parameter is the value to add to the list at the given key.
  static void addToMapList<K, V>(Map<K, List<V>> map, K key, V value) {
    if (!map.containsKey(key)) {
      map[key] = [];
    }
    map[key]!.add(value);
  }

  /// Safely retrieves a list from a map, returning an empty list if the key doesn't exist.
  ///
  /// This method provides null-safe access to lists stored in a map. If the [key]
  /// is not present in the [map], an empty list is returned instead of throwing
  /// or returning null.
  ///
  /// Example:
  /// ```dart
  /// final decorators = <Type, List<Function>>{};
  /// // Instead of:
  /// // final list = decorators[Logger] ?? [];
  /// // Use:
  /// final list = CollectionUtils.getFromMapList(decorators, Logger);
  /// for (final decorator in list) {
  ///   // Process decorators, works even if Logger key doesn't exist
  /// }
  /// ```
  ///
  /// The [map] parameter is the map to query (keys of type K, values are List<V>).
  /// The [key] parameter is the key whose list should be retrieved.
  /// Returns the list associated with the [key], or an empty list if the key doesn't exist.
  static List<V> getFromMapList<K, V>(Map<K, List<V>> map, K key) {
    return map[key] ?? [];
  }
}
