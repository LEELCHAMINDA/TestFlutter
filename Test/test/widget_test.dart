// Smoke test for the Product Manager app.
//
// Verifies the app launches, renders its title, and the home screen builds
// without layout overflow. Replace with richer interaction tests as needed.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:test/main.dart';
import 'package:test/providers/product_provider.dart';

void main() {
  testWidgets('App launches and shows Product Manager title without overflow',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ProductProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product Manager'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
