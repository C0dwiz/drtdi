class CollectionUtils {
  static void addToMapList<K, V>(Map<K, List<V>> map, K key, V value) {
    if (!map.containsKey(key)) {
      map[key] = [];
    }
    map[key]!.add(value);
  }

  static List<V> getFromMapList<K, V>(Map<K, List<V>> map, K key) {
    return map[key] ?? [];
  }
}
