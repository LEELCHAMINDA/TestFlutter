import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/environment.dart';

class AuthUser {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final bool isActive;
  final DateTime? createdDate;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.isActive = true,
    this.createdDate,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'] as String)
          : null,
    );
  }
}

class AuthResponse {
  final String token;
  final AuthUser? user;

  const AuthResponse({required this.token, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: json['user'] != null
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AuthService {
  AuthService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? Environment.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const String _apiVersion = 'v1';
  static const String _apiBase = '/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  String? _token;
  AuthUser? _user;
  bool _isLoading = false;

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _user = AuthUser.fromJson(json.decode(userJson));
      } catch (_) {
        _user = null;
      }
    }
  }

  Future<AuthResponse> login(String username, String password) async {
    _isLoading = true;

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$_apiBase/$_apiVersion/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveToken(authResponse.token);
        _token = authResponse.token;

        try {
          _user = await _fetchCurrentUser();
          await _saveUser(_user!);
        } catch (_) {}

        _isLoading = false;
        return authResponse;
      }

      final message = response.body.isNotEmpty
          ? (json.decode(response.body)['message'] ??
             json.decode(response.body)['detail'] ??
             'Login failed')
          : 'Invalid username or password';
      _isLoading = false;
      throw AuthException(message, response.statusCode);
    } catch (e) {
      _isLoading = false;
      if (e is AuthException) rethrow;
      throw AuthException('Login failed: $e', 0);
    }
  }

  Future<AuthResponse> register(
      String username, String password, String email, {String? fullName}) async {
    _isLoading = true;

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$_apiBase/$_apiVersion/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'email': email,
          if (fullName != null) 'fullName': fullName,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveToken(authResponse.token);
        _token = authResponse.token;

        try {
          _user = await _fetchCurrentUser();
          await _saveUser(_user!);
        } catch (_) {}

        _isLoading = false;
        return authResponse;
      }

      final message = response.body.isNotEmpty
          ? (json.decode(response.body)['message'] ??
             json.decode(response.body)['detail'] ??
             'Registration failed')
          : 'Registration failed';
      _isLoading = false;
      throw AuthException(message, response.statusCode);
    } catch (e) {
      _isLoading = false;
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed: $e', 0);
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<AuthUser> _fetchCurrentUser() async {
    if (_token == null) throw AuthException('Not authenticated', 401);

    final response = await _client.get(
      Uri.parse('$_baseUrl$_apiBase/$_apiVersion/auth/me'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return AuthUser.fromJson(json.decode(response.body));
    }

    throw AuthException('Failed to fetch user', response.statusCode);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode({
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'fullName': user.fullName,
      'isActive': user.isActive,
      'createdDate': user.createdDate?.toIso8601String(),
    }));
  }

  Map<String, String> get authHeaders {
    if (_token == null || _token!.isEmpty) {
      return {};
    }
    return {'Authorization': 'Bearer $_token'};
  }

  void dispose() {
    _client.close();
  }
}

class AuthException implements Exception {
  final String message;
  final int statusCode;

  const AuthException(this.message, this.statusCode);

  @override
  String toString() => '$message (status: $statusCode)';
}
