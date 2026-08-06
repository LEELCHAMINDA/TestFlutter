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
    await _authService.init();
    notifyListeners();
  }

  Future<AuthResponse> login(String username, String password) async {
    final result = await _authService.login(username, password);
    notifyListeners();
    return result;
  }

  Future<AuthResponse> register(
      String username, String password, String email, {String? fullName}) async {
    final result = await _authService.register(username, password, email, fullName: fullName);
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
