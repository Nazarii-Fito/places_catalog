import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/errors/places_failure.dart';
import 'package:places_catalog/core/widgets/place_image_view.dart';
import 'package:places_catalog/data/models/place_photo.dart';
import 'package:places_catalog/data/repositories/fake_media_repository.dart';
import 'package:places_catalog/data/repositories/media_repository.dart';
import 'package:places_catalog/data/repositories/supabase_media_repository.dart';

void main() {
  group('storage paths', () {
    test('are users/<uid>/<placeId>/<file>.<ext>, never the bucket root', () {
      final String path = SupabaseMediaRepository.buildPath(
        uid: 'u1',
        placeId: 'p1',
        fileId: 'abc',
        contentType: 'image/png',
      );
      expect(path, 'users/u1/p1/abc.png');
      expect(path.startsWith('users/'), isTrue);
    });

    test('extension follows the content type, jpeg by default', () {
      expect(SupabaseMediaRepository.extensionFor('image/webp'), 'webp');
      expect(SupabaseMediaRepository.extensionFor('image/jpeg'), 'jpg');
      expect(SupabaseMediaRepository.extensionFor('image/heic'), 'jpg');
    });
  });

  group('MediaRepository', () {
    const PlacePhoto local = PlacePhoto.local(
      '/tmp/a.jpg',
      fileSizeBytes: 10,
      contentType: 'image/jpeg',
    );

    test(
      'without keys, uploads fail with a clear type; deletes are no-ops',
      () {
        const MediaRepository repo = NotConfiguredMediaRepository();
        expect(repo.isConfigured, isFalse);
        expect(
          repo.uploadPlacePhoto(uid: 'u', placeId: 'p', local: local),
          throwsA(
            isA<PlacesFailure>().having(
              (PlacesFailure f) => f.type,
              'type',
              PlacesFailureType.storageNotConfigured,
            ),
          ),
        );
        expect(repo.deleteAll(['x']), completes);
      },
    );

    test('the fake returns a remote photo with metadata', () async {
      final FakeMediaRepository repo = FakeMediaRepository();
      final PlacePhoto remote = await repo.uploadPlacePhoto(
        uid: 'u',
        placeId: 'p',
        local: local,
      );
      expect(remote.isRemote, isTrue);
      expect(remote.storagePath, startsWith('users/u/p/'));
      expect(remote.contentType, 'image/jpeg');
      expect(remote.fileSizeBytes, 10);
    });
  });

  group('PlaceImageView', () {
    testWidgets('chooses the widget by photo kind', (tester) async {
      PlaceImageView.debugRemoteBuilder = (String url) =>
          Text('remote:$url', textDirection: TextDirection.ltr);
      addTearDown(() => PlaceImageView.debugRemoteBuilder = null);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              const PlaceImageView(
                photo: PlacePhoto.asset('assets/images/photo_coffee.jpg'),
                width: 10,
                height: 10,
              ),
              const PlaceImageView(
                photo: PlacePhoto.local('/no/such/file.jpg', fileSizeBytes: 1),
                width: 10,
                height: 10,
              ),
              PlaceImageView(
                photo: PlacePhoto.remote(
                  url: 'https://x/y.jpg',
                  storagePath: 'users/u/p/y.jpg',
                  fileSizeBytes: 1,
                  contentType: 'image/jpeg',
                  uploadedAt: DateTime.utc(2026),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsWidgets);
      expect(find.text('remote:https://x/y.jpg'), findsOneWidget);
    });
  });
}
