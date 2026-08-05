import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/product.dart';

List<Product> _parseProducts(String jsonStr) {
  final List<dynamic> data = json.decode(jsonStr);
  return data.map((e) => Product.fromJson(e)).toList();
}

List<Product> _parsePagedProducts(String jsonStr) {
  final Map<String, dynamic> data = json.decode(jsonStr);
  final List<dynamic> items = data['items'] ?? [];
  return items.map((e) => Product.fromJson(e)).toList();
}

Product _parseSingleProduct(String jsonStr) => Product.fromJson(json.decode(jsonStr));

class ProductApiService {
  ProductApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? Environment.apiBaseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  Map<String, String> Function()? _authHeadersFn;

  static const String _apiVersion = 'v1';
  static const String _apiBase = '/api';

  // Bounded, insertion-ordered LRU cache (max 100 entries) so a long session
  // does not grow the cache without limit.
  static const int _maxCacheSize = 100;
  final Map<int, Product> _productCache = {};

  Future<List<Product>> getAllProducts({int pageNumber = 1, int pageSize = 100}) async {
    final uri = Uri.parse('$baseUrl$_apiBase/$_apiVersion/products').replace(
      queryParameters: {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      },
    );
    final headers = {...(_authHeadersFn?.call() ?? {})};
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final products = await compute(_parsePagedProducts, response.body);
      for (final p in products) {
        _cachePut(p.id, p);
      }
      return products;
    }
    throw ApiException('Failed to load products', response.statusCode);
  }

  Future<List<Product>> searchProducts(String searchTerm) async {
    final uri = Uri.parse('$baseUrl$_apiBase/$_apiVersion/products/search').replace(
      queryParameters: {'term': searchTerm},
    );
    final headers = {...(_authHeadersFn?.call() ?? {})};
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final products = await compute(_parseProducts, response.body);
      for (final p in products) {
        _cachePut(p.id, p);
      }
      return products;
    }
    throw ApiException('Failed to search products', response.statusCode);
  }

  Future<Product?> getProductById(int id) async {
    final cached = _productCache[id];
    if (cached != null) {
      return cached;
    }
    final headers = {...(_authHeadersFn?.call() ?? {})};
    final response = await _client.get(
      Uri.parse('$baseUrl$_apiBase/$_apiVersion/products/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final product = await compute(_parseSingleProduct, response.body);
      _cachePut(id, product);
      return product;
    }
    if (response.statusCode == 404) return null;
    throw ApiException('Failed to load product', response.statusCode);
  }

  Future<int> createProduct(Product product) async {
    final headers = {
      'Content-Type': 'application/json',
      ...(_authHeadersFn?.call() ?? {}),
    };
    final response = await _client.post(
      Uri.parse('$baseUrl$_apiBase/$_apiVersion/products'),
      headers: headers,
      body: json.encode(product.toJson()),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id'] as int? ?? 0;
    }
    throw ApiException('Failed to create product', response.statusCode);
  }

  Future<void> updateProduct(Product product) async {
    final headers = {
      'Content-Type': 'application/json',
      ...(_authHeadersFn?.call() ?? {}),
    };
    final response = await _client.put(
      Uri.parse('$baseUrl$_apiBase/$_apiVersion/products/${product.id}'),
      headers: headers,
      body: json.encode(product.toJson()),
    );
    if (response.statusCode == 204) {
      _cachePut(product.id, product);
      return;
    }
    if (response.statusCode == 404) {
      throw const ApiException('Product not found', 404);
    }
    throw ApiException('Failed to update product', response.statusCode);
  }

  Future<void> deleteProduct(int id) async {
    final headers = {...(_authHeadersFn?.call() ?? {})};
    final response = await _client.delete(
      Uri.parse('$baseUrl$_apiBase/$_apiVersion/products/$id'),
      headers: headers,
    );
    if (response.statusCode == 204) {
      _productCache.remove(id);
      return;
    }
    if (response.statusCode == 404) {
      throw const ApiException('Product not found', 404);
    }
    throw ApiException('Failed to delete product', response.statusCode);
  }

  void _cachePut(int id, Product product) {
    if (_productCache.length >= _maxCacheSize) {
      _productCache.remove(_productCache.keys.first);
    }
    _productCache[id] = product;
  }

  void setAuthHeaders(Map<String, String> Function() headersFn) {
    _authHeadersFn = headersFn;
  }

  void clearCache() => _productCache.clear();

  void dispose() {
    _productCache.clear();
    _client.close();
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => '$message (status: $statusCode)';
}
