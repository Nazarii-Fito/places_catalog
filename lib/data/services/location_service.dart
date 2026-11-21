import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_strings.dart';

enum LocationFailureType {
  /// The user refused (this time); asking again may work.
  denied,

  /// Refused for good: only the Settings app can change it.
  deniedForever,

  /// Location services are switched off on the device.
  servicesOff,

  /// No fix could be obtained (timeout, no signal).
  unavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.type);

  final LocationFailureType type;

  String get message => switch (type) {
    LocationFailureType.denied => AppStrings.locationDenied,
    LocationFailureType.deniedForever => AppStrings.locationDeniedForever,
    LocationFailureType.servicesOff => AppStrings.locationServicesOff,
    LocationFailureType.unavailable => AppStrings.locationUnavailable,
  };

  @override
  String toString() => 'LocationFailure($type)';
}

/// Where the phone is right now. An interface so the picker can be tested
/// without a GPS; the real one asks the user for permission.
abstract interface class LocationService {
  /// One position fix. Throws [LocationFailure].
  Future<({double latitude, double longitude})> currentPosition();
}

/// [LocationService] on `geolocator`: asks for "while in use" permission
/// when needed, then reads one position.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<({double latitude, double longitude})> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(LocationFailureType.servicesOff);
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const LocationFailure(LocationFailureType.denied);
      case LocationPermission.deniedForever:
        throw const LocationFailure(LocationFailureType.deniedForever);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        break;
    }
    try {
      final Position p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // Street-level is plenty to pick a venue and saves battery.
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return (latitude: p.latitude, longitude: p.longitude);
    } on TimeoutException {
      throw const LocationFailure(LocationFailureType.unavailable);
    } on PermissionDeniedException {
      throw const LocationFailure(LocationFailureType.denied);
    } on LocationServiceDisabledException {
      throw const LocationFailure(LocationFailureType.servicesOff);
    }
  }
}

/// Scripted location for tests and the screenshot mode.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.latitude = 49.8419,
    this.longitude = 24.0315,
    this.failure,
  });

  final double latitude;
  final double longitude;
  LocationFailure? failure;
  int calls = 0;

  @override
  Future<({double latitude, double longitude})> currentPosition() async {
    calls++;
    final LocationFailure? f = failure;
    if (f != null) throw f;
    return (latitude: latitude, longitude: longitude);
  }
}
