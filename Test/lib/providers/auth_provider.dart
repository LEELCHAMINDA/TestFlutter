import 'package:flutter/widgets.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  AuthService get authService => _authService;
  AuthUser? get user => _authService.user;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _authService.isLoading;

  Future<void> init() async {
    _authService.addListener(_onAuthChanged);
    await _authService.init();
    notifyListeners();
  }

  void _onAuthChanged() {
    notifyListeners();
  }

  Future<AuthResponse> login(String username, String password) async {
    return await _authService.login(username, password);
  }

  Future<AuthResponse> register(
      String username, String password, String email, {String? fullName}) async {
    return await _authService.register(username, password, email, fullName: fullName);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _authService.dispose();
    super.dispose();
  }
}
