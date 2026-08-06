import '../models/product.dart';

/// A bounded, insertion-ordered LRU cache for products.
/// Prevents unbounded memory growth during long sessions.
class ProductCache {
  ProductCache({int maxSize = 100}) : _maxSize = maxSize;

  final int _maxSize;
  final Map<int, Product> _cache = {};

  Product? get(int id) => _cache[id];

  void put(int id, Product product) {
    if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[id] = product;
  }

  void remove(int id) => _cache.remove(id);

  void clear() => _cache.clear();
}
