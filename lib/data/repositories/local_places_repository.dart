// The constructor takes named parameters for private fields, which cannot
// be initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../mock/mock_places.dart';
import '../models/place.dart';
import '../services/crash_reporter.dart';
import 'places_repository.dart';

/// Stores each user's catalog as a JSON file (`places_<uid>.json`).
///
/// Why a file and not SharedPreferences: the catalog is a growing list of
/// nested objects, while SharedPreferences is meant for a few small
/// key–value settings. Why not a database: the volume is tiny and the
/// whole list is shown at once, so one file is the simplest thing that
/// works (and the brief forbids extra dependencies).
///
/// * Per user: the file name contains the uid, so accounts never see each
///   other's places.
/// * Atomic write: data goes to a temporary file that then *replaces* the
///   real one, so a crash mid-write cannot leave half a JSON document.
/// * Damaged file: reported to Crashlytics as non-fatal and replaced by the
///   demo catalog, so the app still opens.
class LocalPlacesRepository implements PlacesRepository {
  /// [directory] is injected (production: the app documents directory) so
  /// tests can point the repository at a temporary folder.
  LocalPlacesRepository({
    required Future<Directory> Function() directory,
    required CrashReporter crashReporter,
    List<Place>? seed,
  }) : _directory = directory,
       _crashReporter = crashReporter,
       _seed = seed ?? mockPlaces;

  final Future<Directory> Function() _directory;
  final CrashReporter _crashReporter;
  final List<Place> _seed;

  final Map<String, List<Place>> _cache = {};

  /// Writes are chained so two quick changes never interleave on disk.
  Future<void> _lastWrite = Future<void>.value();

  Future<File> _file(String uid) async {
    final Directory dir = await _directory();
    final String safe = uid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${dir.path}/places_$safe.json');
  }

  @override
  Future<List<Place>> loadPlaces(String uid) async {
    final List<Place>? cached = _cache[uid];
    if (cached != null) return List.of(cached);

    final File file = await _file(uid);
    List<Place> places;
    if (!await file.exists()) {
      places = List.of(_seed);
      await _write(uid, places);
    } else {
      try {
        places = _decode(await file.readAsString());
      } catch (error, stack) {
        await _crashReporter.recordError(
          error,
          stack,
          reason: 'Damaged places file, restored demo catalog',
        );
        places = List.of(_seed);
        await _write(uid, places);
      }
    }
    _cache[uid] = places;
    return List.of(places);
  }

  @override
  Future<void> savePlace(String uid, Place place) async {
    final List<Place> list = await _mutable(uid);
    final int index = list.indexWhere((Place p) => p.id == place.id);
    if (index == -1) {
      list.add(place);
    } else {
      list[index] = place;
    }
    await _write(uid, list);
  }

  @override
  Future<void> deletePlace(String uid, String placeId) async {
    final List<Place> list = await _mutable(uid);
    list.removeWhere((Place p) => p.id == placeId);
    await _write(uid, list);
  }

  Future<List<Place>> _mutable(String uid) async {
    await loadPlaces(uid);
    return _cache[uid]!;
  }

  static List<Place> _decode(String source) {
    final Object? root = jsonDecode(source);
    if (root is! Map<String, Object?>) {
      throw const FormatException('Root of the places file is not an object');
    }
    return [
      for (final Object? item in root['places'] as List<Object?>)
        Place.fromJson((item as Map<Object?, Object?>).cast()),
    ];
  }

  Future<void> _write(String uid, List<Place> places) {
    final String json = const JsonEncoder.withIndent(' ').convert({
      'version': 1,
      'places': places.map((Place p) => p.toJson()).toList(),
    });
    return _lastWrite = _lastWrite.then((_) async {
      final File file = await _file(uid);
      final File temp = File('${file.path}.tmp');
      await temp.writeAsString(json, flush: true);
      await temp.rename(file.path);
    });
  }
}
