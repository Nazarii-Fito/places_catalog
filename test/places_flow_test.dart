import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/app/app.dart';
import 'package:places_catalog/core/widgets/place_card.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/data/repositories/fake_auth_repository.dart';
import 'package:places_catalog/data/repositories/in_memory_places_repository.dart';
import 'package:places_catalog/data/repositories/in_memory_settings_repository.dart';
import 'package:places_catalog/features/shell/main_shell.dart';

import 'helpers/test_harness.dart';

/// End-to-end flows of the catalog through the real blocs (with in-memory
/// repositories): loading states, deletion across screens, restored view
/// settings and per-user isolation.
void main() {
  setUpAll(loadInterFont);

  testWidgets('Home shows a loader, then the list', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    await tester.pumpWidget(
      testApp(
        const MainShell(),
        places: InMemoryPlacesRepository(
          delay: const Duration(milliseconds: 300),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byType(PlaceCard), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
    expect(find.byType(PlaceCard), findsNWidgets(mockPlaces.length));
  });

  testWidgets('A load failure shows an error and Retry recovers', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    final InMemoryPlacesRepository repo = InMemoryPlacesRepository(
      failLoad: true,
    );
    await tester.pumpWidget(testApp(const MainShell(), places: repo));
    await tester.pumpAndSettle();
    expect(find.text('Could not load your places.'), findsOneWidget);
    expect(find.byType(PlaceCard), findsNothing);

    repo.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceCard), findsNWidgets(mockPlaces.length));
  });

  testWidgets('A deleted place disappears from Home and Favorites', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    await tester.pumpWidget(testApp(const MainShell()));
    await tester.pumpAndSettle();

    // The Daily Grind is a favourite: delete it from its details screen.
    await tester.tap(find.text('The Daily Grind'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete Place'), 200);
    await tester.tap(find.text('Delete Place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('The Daily Grind'), findsNothing);
    await tester.tap(find.text('Favorites').last);
    await tester.pumpAndSettle();
    expect(find.text('The Daily Grind'), findsNothing);
    expect(find.text('All (2)'), findsOneWidget);
  });

  testWidgets('Filter and sort survive a restart; search does not', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    final InMemorySettingsRepository settings = InMemorySettingsRepository();
    final InMemoryPlacesRepository places = InMemoryPlacesRepository();
    Future<void> launch() async {
      await tester.pumpWidget(
        testApp(const MainShell(), places: places, settings: settings),
      );
      await tester.pumpAndSettle();
    }

    await launch();
    await tester.tap(find.text('Restaurants'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sorted by Recent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'kuro');
    await tester.pumpAndSettle();

    // "Restart": a brand-new widget tree over the same stored settings.
    await tester.pumpWidget(const SizedBox());
    await launch();
    expect(find.text('Sorted by Name'), findsOneWidget);
    expect(find.byType(PlaceCard), findsNWidgets(2)); // restaurants, no search
    expect(find.text('Kurobuta Ramen'), findsOneWidget);
    expect(find.text('Osteria Del Sole'), findsOneWidget);
  });

  testWidgets('Switching accounts does not leak one catalog to another', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    final FakeAuthRepository auth = FakeAuthRepository.signedIn();
    final InMemoryPlacesRepository places = InMemoryPlacesRepository();
    await tester.pumpWidget(
      withScope(const PlacesCatalogApp(), auth: auth, places: places),
    );
    await tester.pumpAndSettle();

    // User 1 deletes Kurobuta Ramen.
    await tester.tap(find.text('Kurobuta Ramen'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete Place'), 200);
    await tester.tap(find.text('Delete Place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Kurobuta Ramen'), findsNothing);

    // Another user signs in: their own, untouched catalog.
    await auth.signOut();
    await tester.pumpAndSettle();
    await auth.signIn(email: 'other@icloud.com', password: 'secret123');
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Kurobuta Ramen'), findsOneWidget);
  });
}
