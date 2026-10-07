import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import 'dev_launch_options.dart';
import 'routes/app_routes.dart';

/// Root widget: theme + Navigator 1.0 with named routes.
class PlacesCatalogApp extends StatelessWidget {
  const PlacesCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: DevLaunchOptions.initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
