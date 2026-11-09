import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/services/analytics_service.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import 'dev_launch_options.dart';
import 'routes/app_routes.dart';
import 'user_scope.dart';

/// Root widget: theme + Navigator 1.0 with named routes.
///
/// The analytics observer logs a `screen_view` for every named route,
/// which is why `onGenerateRoute` passes `settings` to each page route.
class PlacesCatalogApp extends StatelessWidget {
  const PlacesCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorObservers: [context.read<AnalyticsService>().navigatorObserver],
      initialRoute: DevLaunchOptions.initialRoute,
      builder: (BuildContext context, Widget? child) =>
          UserScope(child: child!),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
