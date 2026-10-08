import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/app/app.dart';
import 'package:places_catalog/core/widgets/place_card.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/features/auth/screens/login_screen.dart';
import 'package:places_catalog/features/auth/screens/register_screen.dart';
import 'package:places_catalog/features/home/screens/home_screen.dart';
import 'package:places_catalog/features/places/screens/add_place_screen.dart';
import 'package:places_catalog/features/places/widgets/details_sections.dart';
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

  for (final (String name, Widget screen) in [
    ('Login', const LoginScreen()),
    ('Create Account', const RegisterScreen()),
  ]) {
    testWidgets('$name fits iPhone 17 without scrolling', (
      WidgetTester tester,
    ) async {
      useIPhone17(tester);
      await tester.pumpWidget(testApp(screen));
      await tester.pumpAndSettle();
      expect(maxScrollExtent(tester), 0);
    });
  }

  testWidgets('Sort menu reorders Home cards', (WidgetTester tester) async {
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
    String firstCard() =>
        tester.widget<PlaceCard>(find.byType(PlaceCard).first).place.name;
    expect(firstCard(), 'The Daily Grind');

    await tester.tap(find.text('Sorted by Recent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(find.text('Sorted by Name'), findsOneWidget);
    expect(firstCard(), 'Atelier Pastel Cafe');
  });

  testWidgets('Pencil opens Edit Profile; saved name shows on Profile', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('App Settings'), findsNothing);
    expect(find.textContaining('iCloud'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Nazar Fito');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Nazar Fito'), findsOneWidget);
  });

  testWidgets('Notes can be edited and a tag added on Place Details', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 2000));
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Daily Grind'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).first,
      'Great flat white.',
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Great flat white.'), findsOneWidget);

    await tester.tap(find.text('Add Tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Brunch');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('#Brunch'), findsOneWidget);
  });

  testWidgets('Notes box keeps its size when switching to Edit', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 2000));
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Daily Grind'));
    await tester.pumpAndSettle();

    final Finder box = find.descendant(
      of: find.byType(NotesSection),
      matching: find.byType(Container),
    );
    final Rect before = tester.getRect(box.first);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(tester.getRect(box.first), before);
  });

  testWidgets('Add Place uses the same tag control (dialog + remove)', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 2000));
    await tester.pumpWidget(testApp(const AddPlaceScreen()));
    await tester.pumpAndSettle();
    expect(find.text('#Espresso'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Remove tag #Espresso'));
    await tester.pumpAndSettle();
    expect(find.text('#Espresso'), findsNothing);

    await tester.tap(find.text('Add Tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, 'Rooftop');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('#Rooftop'), findsOneWidget);
  });
}
