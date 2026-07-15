import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/product.dart';

List<int> _parseIds(String jsonStr) {
  final List<dynamic> data = json.decode(jsonStr);
  return data.map((e) => e as int).toList();
}

List<Product> _parseProducts(String jsonStr) {
  final List<dynamic> data = json.decode(jsonStr);
  return data.map((e) => Product.fromJson(e)).toList();
}

class ProductApiService {
  ProductApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? Environment.apiBaseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<int>> getAllProductIds() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/products'));
    if (response.statusCode == 200) {
      return compute(_parseIds, response.body);
    }
    throw ApiException('Failed to load product IDs', response.statusCode);
  }

  Future<List<Product>> searchProducts(String searchTerm) async {
    final uri = Uri.parse('$baseUrl/api/products/search').replace(queryParameters: {'term': searchTerm});
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      return compute(_parseProducts, response.body);
    }
    throw ApiException('Failed to search products', response.statusCode);
  }

  Future<Product?> getProductById(int id) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/products/$id'));
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    }
    if (response.statusCode == 404) return null;
    throw ApiException('Failed to load product', response.statusCode);
  }

  Future<int> createProduct(Product product) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id'] as int? ?? 0;
    }
    throw ApiException('Failed to create product', response.statusCode);
  }

  Future<void> updateProduct(Product product) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );
    if (response.statusCode != 204) {
      throw ApiException('Failed to update product', response.statusCode);
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/products/$id'),
    );
    if (response.statusCode != 204) {
      throw ApiException('Failed to delete product', response.statusCode);
    }
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => '$message (status: $statusCode)';
}
