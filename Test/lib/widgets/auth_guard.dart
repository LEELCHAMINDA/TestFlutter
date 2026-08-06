import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/login_screen.dart';
import '../widgets/mdi_home_page.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
        ThemeMode.system => ThemeMode.light,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Product Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: auth.isAuthenticated
          ? ChangeNotifierProvider(
              create: (_) => ProductProvider(
                authService: auth.authService,
              )..fetchProducts(),
              child: MDIHomePage(onToggleTheme: _toggleTheme, themeMode: _themeMode),
            )
          : LoginScreen(onToggleTheme: _toggleTheme, themeMode: _themeMode),
    );
  }
}
