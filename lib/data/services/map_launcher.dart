import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a point in the phone's own Maps app.
abstract interface class MapLauncher {
  /// Returns whether a maps app was opened.
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  });
}

/// [MapLauncher] on `url_launcher`: Apple Maps on iOS, a `geo:` link on
/// Android (the user's default maps app), a web link elsewhere.
class UrlLauncherMapLauncher implements MapLauncher {
  const UrlLauncherMapLauncher();

  /// Builds the link for the current platform (a public method so it can be
  /// tested without launching anything).
  static Uri uriFor({
    required double latitude,
    required double longitude,
    String? label,
    TargetPlatform? platform,
  }) {
    final String point = '$latitude,$longitude';
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return Uri.https('maps.apple.com', '/', {
          'll': point,
          if (label != null && label.isNotEmpty) 'q': label,
        });
      case TargetPlatform.android:
        return Uri(
          scheme: 'geo',
          path: point,
          queryParameters: {'q': '$point(${label ?? ''})'},
        );
      default:
        return Uri.https('www.openstreetmap.org', '/', {
          'mlat': '$latitude',
          'mlon': '$longitude',
          'zoom': '17',
        });
    }
  }

  @override
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      return await launchUrl(
        uriFor(latitude: latitude, longitude: longitude, label: label),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Records the request; opens nothing. For tests and the screenshot mode.
class FakeMapLauncher implements MapLauncher {
  FakeMapLauncher({this.succeeds = true});

  final bool succeeds;
  final List<(double, double, String?)> opened = [];

  @override
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    opened.add((latitude, longitude, label));
    return succeeds;
  }
}
