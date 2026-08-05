import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../utils/constants.dart';
import '../widgets/login_screen.dart';
import '../widgets/mdi_home_page.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Product Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: auth.isAuthenticated
          ? ChangeNotifierProvider(
              create: (_) => ProductProvider(
                authService: auth.authService,
              )..fetchProducts(),
              child: const MDIHomePage(),
            )
          : const LoginScreen(),
    );
  }
}
