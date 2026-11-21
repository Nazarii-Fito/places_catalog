import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/widgets/nav_back_button.dart';
import 'package:places_catalog/core/widgets/place_image_view.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/data/models/place.dart';
import 'package:places_catalog/data/models/place_photo.dart';
import 'package:places_catalog/data/repositories/fake_media_repository.dart';
import 'package:places_catalog/data/repositories/in_memory_places_repository.dart';
import 'package:places_catalog/data/services/photo_picker_service.dart';
import 'package:places_catalog/features/places/screens/place_form_screen.dart';
import 'package:places_catalog/features/places/screens/place_details_screen.dart';
import 'package:places_catalog/features/shell/main_shell.dart';

import 'helpers/test_harness.dart';

final List<int> _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// The form talks to the real blocs; only storage, picker and database are
/// fakes. Covers what the user sees while a place with photos is saved.
void main() {
  setUpAll(loadInterFont);

  late Directory dir;
  late FakeMediaRepository media;
  late InMemoryPlacesRepository repo;
  late FakePhotoPickerService picker;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('save_flow');
    media = FakeMediaRepository();
    final Place bare = mockPlaces.first.copyWith(
      id: 'solo',
      name: 'Solo Cafe',
      photos: const [],
    );
    repo = InMemoryPlacesRepository(seed: [bare]);
    PlacePhoto photo(String n) {
      final File f = File('${dir.path}/$n.png')..writeAsBytesSync(_png);
      return PlacePhoto.local(
        f.path,
        fileSizeBytes: _png.length,
        contentType: 'image/png',
      );
    }

    picker = FakePhotoPickerService(library: [photo('a'), photo('b')]);
    // No real HTTP in tests: uploaded photos render as plain text.
    PlaceImageView.debugRemoteBuilder = (String url) => const SizedBox();
  });
  tearDown(() {
    PlaceImageView.debugRemoteBuilder = null;
    dir.deleteSync(recursive: true);
  });

  Future<void> openEditForm(WidgetTester tester) async {
    useIPhone(tester, size: const Size(390, 2400));
    await tester.pumpWidget(
      testApp(const MainShell(), places: repo, media: media, picker: picker),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solo Cafe'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Edit place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from Library'));
    await tester.pumpAndSettle();
    expect(find.text('3 left'), findsOneWidget);
  }

  testWidgets('saving shows progress and locks the form until done', (
    tester,
  ) async {
    media.gate = Completer<void>();
    await openEditForm(tester);

    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Uploading photo 1 of 2…'), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

    // Touches are ignored and the form cannot be left.
    await tester.tap(find.byType(NavBackButton), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(PlaceFormScreen), findsOneWidget);

    media.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(PlaceFormScreen), findsNothing);
    expect(find.byType(PlaceDetailsScreen), findsOneWidget);
    expect(media.uploaded, hasLength(2));
    // Real async: the in-memory repository's delay is a timer.
    final List<Place> stored = (await tester.runAsync(
      () => repo.loadPlaces('u'),
    ))!;
    final Place saved = stored.firstWhere((Place p) => p.id == 'solo');
    expect(saved.photos.every((PlacePhoto p) => p.isRemote), isTrue);
  });

  testWidgets('an upload error is shown with Retry, and Retry saves', (
    tester,
  ) async {
    media.failOnUpload = 1;
    await openEditForm(tester);

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(PlaceFormScreen), findsOneWidget); // data not lost
    expect(media.uploaded, isEmpty);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceFormScreen), findsNothing);
    expect(media.uploaded, hasLength(2));
  });

  testWidgets('without storage keys the form says so and keeps the data', (
    tester,
  ) async {
    media = FakeMediaRepository(configured: false);
    await openEditForm(tester);
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Cloud storage is not configured.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing); // retrying cannot help
    expect(find.byType(PlaceFormScreen), findsOneWidget);
  });
}
