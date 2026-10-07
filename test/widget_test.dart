import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/app/app.dart';
import 'package:places_catalog/core/widgets/place_card.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/features/home/screens/home_screen.dart';
import 'package:places_catalog/features/places/screens/place_details_screen.dart';
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
    await tester.pumpWidget(
      testApp(
        HomeScreen(
          places: mockPlaces,
          onToggleFavorite: (_) {},
          onOpenPlace: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlaceCard), findsNWidgets(mockPlaces.length));

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

  testWidgets('Heart on Home updates the Favorites tab (lifted state)', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favorites').last);
    await tester.pumpAndSettle();
    expect(find.text('All (3)'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    // Osteria Del Sole is the second card and not a favourite yet.
    await tester.tap(find.bySemanticsLabel('Toggle favorite').at(1));
    await tester.tap(find.text('Favorites').last);
    await tester.pumpAndSettle();
    expect(find.text('All (4)'), findsOneWidget);
  });

  testWidgets('Card opens details; Delete asks for confirmation', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kurobuta Ramen'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceDetailsScreen), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Delete Place'), 200);
    await tester.tap(find.text('Delete Place'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Place?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceDetailsScreen), findsNothing);
    expect(find.text('Kurobuta Ramen'), findsNothing);
  });
}
