import 'package:flutter/cupertino.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/places/place_details_args.dart';
import '../../features/places/screens/add_place_screen.dart';
import '../../features/places/screens/location_picker_screen.dart';
import '../../features/places/screens/place_details_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/shell/main_shell.dart';
import '../dev_launch_options.dart';

/// Route names and the single route factory of the app.
///
/// Every screen is wrapped in a [CupertinoPageRoute]: iOS slide transition
/// plus swipe-back from the left edge (HIG — no system "Back" button).
abstract final class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String changePassword = '/change-password';
  static const String placeDetails = '/place-details';
  static const String addPlace = '/add-place';
  static const String locationPicker = '/location-picker';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder builder = switch (settings.name) {
      AppRoutes.register => (_) => const RegisterScreen(),
      AppRoutes.forgotPassword => (_) => const ForgotPasswordScreen(),
      AppRoutes.home => (_) => const MainShell(),
      AppRoutes.changePassword => (_) => const ChangePasswordScreen(),
      // Data for the details screen travels in `settings.arguments`.
      AppRoutes.placeDetails => (_) => PlaceDetailsScreen(
        args:
            settings.arguments as PlaceDetailsArgs? ??
            DevLaunchOptions.previewDetailsArgs,
      ),
      AppRoutes.addPlace => (_) => const AddPlaceScreen(),
      AppRoutes.locationPicker => (_) => const LocationPickerScreen(),
      _ => (_) => const LoginScreen(),
    };
    return CupertinoPageRoute<Object?>(
      builder: builder,
      settings: settings,
      // The picker is a modal task with "Cancel": it slides up from the
      // bottom instead of from the right.
      fullscreenDialog: settings.name == AppRoutes.locationPicker,
    );
  }
}
