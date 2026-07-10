import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/environment.dart';
import '../models/product.dart';

class ProductApiService {
  ProductApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? Environment.apiBaseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<Product>> getAllProducts() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/products'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    }
    throw ApiException('Failed to load products', response.statusCode);
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
      return data['Id'] as int;
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
