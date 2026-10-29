import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// App-level analytics API. Screens talk to this interface, never to the
/// Firebase SDK, so tests and screenshot mode can use [NoopAnalyticsService].
abstract interface class AnalyticsService {
  /// Logs screen views for every named route (Navigator 1.0 `push`/`pop`).
  NavigatorObserver get navigatorObserver;

  Future<void> setUserId(String? uid);
  Future<void> logScreenView(String screenName);
  Future<void> logSignUp(String method);
  Future<void> logLogin(String method);
  Future<void> logPasswordResetRequested();
  Future<void> logPasswordChanged();
  Future<void> logProfileUpdated({required String photoSource});
  Future<void> logPlaceFavoriteToggled({
    required String placeId,
    required bool isFavorite,
  });
  Future<void> logPlaceOpened({
    required String placeId,
    required String category,
  });
  Future<void> logAccountLinked(String provider);
}

/// [AnalyticsService] backed by Firebase Analytics.
///
/// `logSignUp` / `logLogin` / `logScreenView` are Google's recommended
/// events; the rest are custom events created with `logEvent`. Parameter
/// values must be strings or numbers, so booleans are sent as 0/1.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  late final NavigatorObserver navigatorObserver = FirebaseAnalyticsObserver(
    analytics: _analytics,
  );

  @override
  Future<void> setUserId(String? uid) => _analytics.setUserId(id: uid);

  @override
  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  @override
  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  @override
  Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  @override
  Future<void> logPasswordResetRequested() =>
      _analytics.logEvent(name: 'password_reset_requested');

  @override
  Future<void> logPasswordChanged() =>
      _analytics.logEvent(name: 'password_changed');

  @override
  Future<void> logProfileUpdated({required String photoSource}) =>
      _analytics.logEvent(
        name: 'profile_updated',
        parameters: {'photo_source': photoSource},
      );

  @override
  Future<void> logPlaceFavoriteToggled({
    required String placeId,
    required bool isFavorite,
  }) => _analytics.logEvent(
    name: 'place_favorite_toggled',
    parameters: {'place_id': placeId, 'is_favorite': isFavorite ? 1 : 0},
  );

  @override
  Future<void> logPlaceOpened({
    required String placeId,
    required String category,
  }) => _analytics.logEvent(
    name: 'place_opened',
    parameters: {'place_id': placeId, 'category': category},
  );

  @override
  Future<void> logAccountLinked(String provider) => _analytics.logEvent(
    name: 'account_linked',
    parameters: {'provider': provider},
  );
}

/// Does nothing — used by widget tests and the screenshot mode.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  NavigatorObserver get navigatorObserver => NavigatorObserver();

  @override
  Future<void> setUserId(String? uid) async {}
  @override
  Future<void> logScreenView(String screenName) async {}
  @override
  Future<void> logSignUp(String method) async {}
  @override
  Future<void> logLogin(String method) async {}
  @override
  Future<void> logPasswordResetRequested() async {}
  @override
  Future<void> logPasswordChanged() async {}
  @override
  Future<void> logProfileUpdated({required String photoSource}) async {}
  @override
  Future<void> logPlaceFavoriteToggled({
    required String placeId,
    required bool isFavorite,
  }) async {}
  @override
  Future<void> logPlaceOpened({
    required String placeId,
    required String category,
  }) async {}
  @override
  Future<void> logAccountLinked(String provider) async {}
}
