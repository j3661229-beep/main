import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrimart/main.dart';

void main() {
  testWidgets('AgriMart app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgriMartApp()));
    // Just ensure it builds without crashing
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
