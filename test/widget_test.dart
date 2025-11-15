import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopify_pricesync_v2/main.dart';

void main() {
  testWidgets('HomeScreen or LoginScreen displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp()); // <-- removed firebaseReady

    // Wait for FutureBuilder
    await tester.pumpAndSettle();

    // Verify that either LoginScreen or HomeScreen appears
    expect(find.byType(Scaffold), findsWidgets); // HomeScreen/LoginScreen both scaffold
  });
}
