import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/app/app.dart';
import 'package:places_catalog/core/widgets/place_card.dart';
import 'package:places_catalog/features/home/screens/home_screen.dart';
import 'package:places_catalog/features/shell/main_shell.dart';

import 'helpers/test_harness.dart';

void main() {
  setUpAll(loadInterFont);

  testWidgets('Login screen renders the form', (WidgetTester tester) async {
    useIPhone(tester);
    await tester.pumpWidget(const PlacesCatalogApp());
    await tester.pumpAndSettle();

    expect(find.text('PlacesCatalog'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('Tapping "Log In" opens Home and removes Login', (
    WidgetTester tester,
  ) async {
    useIPhone(tester);
    await tester.pumpWidget(const PlacesCatalogApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('My Places'), findsOneWidget);
    expect(find.text('PlacesCatalog'), findsNothing);
  });

  testWidgets('Tab bar switches between Home, Favorites and Profile', (
    WidgetTester tester,
  ) async {
    useIPhone(tester);
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();
    expect(find.text('My Places'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Total Visited Places'), findsOneWidget);
    expect(find.text('My Places'), findsNothing);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('My Places'), findsOneWidget);
  });

  testWidgets('Filter chips and search change the number of cards', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    await tester.pumpWidget(testApp(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceCard), findsNWidgets(4));

    await tester.tap(find.text('Restaurants'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceCard), findsNWidgets(2));

    await tester.tap(find.text('Museums'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceCard), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byType(PlaceCard), findsNothing);
    expect(find.text('No places found'), findsOneWidget);
  });
}
