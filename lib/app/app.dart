import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_routes.dart';

/// Root widget: theme + Navigator 1.0 with named routes.
class PlacesCatalogApp extends StatelessWidget {
  const PlacesCatalogApp({super.key});

  /// Start screen. Defaults to Login; for screenshots a screen can be opened
  /// directly: `flutter run --dart-define=INITIAL_ROUTE=/home`.
  static const String _initialRoute = String.fromEnvironment(
    'INITIAL_ROUTE',
    defaultValue: AppRoutes.login,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: _initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
