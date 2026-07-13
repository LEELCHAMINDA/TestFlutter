import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/product_provider.dart';
import 'utils/constants.dart';
import 'widgets/mdi_home_page.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    final exception = details.exception;
    if (exception is FlutterError && exception.message.contains('overflowed')) {
      return;
    }
    FlutterError.presentError(details);
  };
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProductProvider()..fetchProducts(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MDIHomePage(),
    );
  }
}
