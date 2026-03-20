
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:knocklogs/providers/theme_provider.dart';
import 'package:knocklogs/screens/landing/landing_page.dart';

void main() {

  testWidgets('App renders landing actions', (WidgetTester tester) async {
    tester.view.physicalSize = const ui.Size(1440, 2960);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MaterialApp(home: LandingPage()),
      ),
    );
    await tester.pump();

  testWidgets('Landing page renders primary actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('KnockLogs'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
