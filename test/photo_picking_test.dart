import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/data/mock/mock_places.dart';
import 'package:places_catalog/data/models/place_photo.dart';
import 'package:places_catalog/data/services/photo_picker_service.dart';
import 'package:places_catalog/data/repositories/fake_media_repository.dart';
import 'package:places_catalog/features/places/screens/place_form_screen.dart';
import 'package:places_catalog/features/profile/screens/edit_profile_screen.dart';

import 'helpers/test_harness.dart';

/// A 1×1 transparent PNG, so `Image.file` has something real to decode.
final List<int> _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  setUpAll(loadInterFont);

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('photos'));
  tearDown(() => dir.deleteSync(recursive: true));

  PlacePhoto picked(String name) {
    final File f = File('${dir.path}/$name.png')..writeAsBytesSync(_png);
    return PlacePhoto.local(
      f.path,
      fileSizeBytes: _png.length,
      contentType: 'image/png',
    );
  }

  group('PhotoRules.validate', () {
    test('accepts jpeg, png and webp and returns the MIME type', () {
      expect(PhotoRules.validate('/a/b.JPG', 100), 'image/jpeg');
      expect(PhotoRules.validate('/a/b.jpeg', 100), 'image/jpeg');
      expect(PhotoRules.validate('/a/b.png', 100), 'image/png');
      expect(PhotoRules.validate('/a/b.webp', 100), 'image/webp');
    });

    test('rejects other types', () {
      for (final String path in ['/a/b.gif', '/a/b.heic', '/a/b', '/a/b.pdf']) {
        expect(
          () => PhotoRules.validate(path, 100),
          throwsA(
            isA<PhotoPickFailure>().having(
              (PhotoPickFailure f) => f.type,
              'type',
              PhotoPickFailureType.unsupportedType,
            ),
          ),
        );
      }
    });

    test('rejects files over 5 MB, accepts exactly 5 MB', () {
      expect(PhotoRules.validate('/a.jpg', PhotoRules.maxBytes), 'image/jpeg');
      expect(
        () => PhotoRules.validate('/a.jpg', PhotoRules.maxBytes + 1),
        throwsA(isA<PhotoPickFailure>()),
      );
    });
  });

  group('photo picking in the form', () {
    Future<void> openForm(
      WidgetTester tester,
      FakePhotoPickerService picker, {
      bool withPhotos = false,
    }) async {
      useIPhone(tester, size: const Size(390, 2000));
      await tester.pumpWidget(
        testApp(
          PlaceFormScreen(initial: withPhotos ? mockPlaces.first : null),
          picker: picker,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('library: sheet → photos appear at once', (tester) async {
      final FakePhotoPickerService picker = FakePhotoPickerService(
        library: [picked('a'), picked('b')],
      );
      await openForm(tester, picker);
      expect(find.text('5 left'), findsOneWidget);

      await tester.tap(find.text('Add Photos'));
      await tester.pumpAndSettle();
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Library'), findsOneWidget);
      await tester.tap(find.text('Choose from Library'));
      await tester.pumpAndSettle();

      expect(picker.libraryCalls, 1);
      expect(picker.lastLimit, 5);
      expect(find.text('3 left'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove photo'), findsNWidgets(2));
    });

    testWidgets('only the free slots are requested (max 5 photos)', (
      tester,
    ) async {
      final FakePhotoPickerService picker = FakePhotoPickerService(
        library: [picked('a'), picked('b'), picked('c')],
      );
      await openForm(tester, picker, withPhotos: true); // already 4 photos
      await tester.tap(find.text('1 left'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Library'));
      await tester.pumpAndSettle();

      expect(picker.lastLimit, 1);
      // The picker returned 3, the form keeps room for one only.
      expect(find.bySemanticsLabel('Remove photo'), findsNWidgets(5));
      expect(find.textContaining('left'), findsNothing); // tile is gone
    });

    testWidgets('cancelling the sheet or the picker changes nothing', (
      tester,
    ) async {
      final FakePhotoPickerService picker = FakePhotoPickerService();
      await openForm(tester, picker);
      await tester.tap(find.text('Add Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(picker.libraryCalls + picker.cameraCalls, 0);

      await tester.tap(find.text('Add Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle(); // camera returns null = cancelled
      expect(picker.cameraCalls, 1);
      expect(find.text('5 left'), findsOneWidget);
      expect(find.text('Photo Not Added'), findsNothing);
    });

    testWidgets('camera photo is added', (tester) async {
      final FakePhotoPickerService picker = FakePhotoPickerService(
        camera: picked('cam'),
      );
      await openForm(tester, picker);
      await tester.tap(find.text('Add Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();
      expect(find.text('4 left'), findsOneWidget);
    });

    testWidgets('a denied permission shows a clear message, no crash', (
      tester,
    ) async {
      final FakePhotoPickerService picker = FakePhotoPickerService(
        failure: const PhotoPickFailure(PhotoPickFailureType.photosDenied),
      );
      await openForm(tester, picker);
      await tester.tap(find.text('Add Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Library'));
      await tester.pumpAndSettle();
      expect(find.text('Photo Not Added'), findsOneWidget);
      expect(find.textContaining('Allow it in Settings'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('5 left'), findsOneWidget);
    });

    testWidgets('no camera (simulator) is explained', (tester) async {
      final FakePhotoPickerService picker = FakePhotoPickerService(
        failure: const PhotoPickFailure(PhotoPickFailureType.noCamera),
      );
      await openForm(tester, picker);
      await tester.tap(find.text('Add Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not available'), findsOneWidget);
    });

    testWidgets('the cross removes a photo', (tester) async {
      final FakePhotoPickerService picker = FakePhotoPickerService(
        library: [picked('a'), picked('b')],
      );
      await openForm(tester, picker);
      await tester.tap(find.text('Add Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Remove photo').first);
      await tester.pumpAndSettle();
      expect(find.text('4 left'), findsOneWidget);
    });
  });

  group('profile picture from the device', () {
    testWidgets('pick → preview → Save uploads it and shows the new photo', (
      tester,
    ) async {
      useIPhone(tester, size: const Size(390, 2400));
      final FakeMediaRepository media = FakeMediaRepository();
      final FakePhotoPickerService picker = FakePhotoPickerService(
        library: [picked('me')],
      );
      await tester.pumpWidget(
        testApp(const EditProfileScreen(), media: media, picker: picker),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Upload from Device'));
      await tester.pumpAndSettle();
      expect(find.text('Choose from Library'), findsOneWidget);
      await tester.tap(find.text('Choose from Library'));
      await tester.pumpAndSettle();
      expect(picker.lastLimit, 1);

      await tester.tap(find.text('Save Changes'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(media.uploaded.single, startsWith('users/demo-uid/avatar/'));
      expect(find.text('Profile Updated'), findsOneWidget);
    });

    testWidgets('a denied photo permission is explained', (tester) async {
      useIPhone(tester, size: const Size(390, 2400));
      final FakePhotoPickerService picker = FakePhotoPickerService(
        failure: const PhotoPickFailure(PhotoPickFailureType.photosDenied),
      );
      await tester.pumpWidget(
        testApp(const EditProfileScreen(), picker: picker),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Upload from Device'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Library'));
      await tester.pumpAndSettle();
      expect(find.text('Photo Not Added'), findsOneWidget);
    });

    testWidgets('without storage keys the save says so', (tester) async {
      useIPhone(tester, size: const Size(390, 2400));
      await tester.pumpWidget(
        testApp(
          const EditProfileScreen(),
          media: FakeMediaRepository(configured: false),
          picker: FakePhotoPickerService(library: [picked('me')]),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Upload from Device'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Cloud storage is not configured.'), findsOneWidget);
    });
  });
}
