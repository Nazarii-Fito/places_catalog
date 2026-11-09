import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/places_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/analytics_service.dart';
import '../data/services/crash_reporter.dart';
import '../features/home/bloc/catalog_view_cubit.dart';
import '../features/places/bloc/places_bloc.dart';
import '../features/profile/bloc/profile_bloc.dart';
import '../features/session/bloc/auth_bloc.dart';

/// Creates the *per-user* blocs (`PlacesBloc`, `CatalogViewCubit`,
/// `ProfileBloc`) while somebody is signed in.
///
/// It sits in `MaterialApp.builder`, i.e. **above the Navigator**. That is
/// the key point: pushed routes (Details, forms) are not descendants of
/// the `AuthGate` route, so blocs provided there would be invisible to them.
///
/// `ValueKey(uid)` makes Flutter discard both blocs when the account
/// changes, so a new user starts with a fresh state and their own files.
class UserScope extends StatelessWidget {
  const UserScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (AuthState a, AuthState b) => _uid(a) != _uid(b),
      builder: (BuildContext context, AuthState state) {
        final String? uid = _uid(state);
        if (uid == null) return child;
        return MultiBlocProvider(
          key: ValueKey<String>(uid),
          providers: [
            BlocProvider<PlacesBloc>(
              create: (BuildContext context) => PlacesBloc(
                uid: uid,
                repository: context.read<PlacesRepository>(),
                analytics: context.read<AnalyticsService>(),
                crashReporter: context.read<CrashReporter>(),
              )..add(const PlacesLoadRequested()),
            ),
            BlocProvider<CatalogViewCubit>(
              create: (BuildContext context) => CatalogViewCubit(
                uid: uid,
                settings: context.read<SettingsRepository>(),
              ),
            ),
            BlocProvider<ProfileBloc>(
              create: (BuildContext context) => ProfileBloc(
                auth: context.read<AuthRepository>(),
                analytics: context.read<AnalyticsService>(),
              )..add(const ProfileStarted()),
            ),
          ],
          child: child,
        );
      },
    );
  }

  static String? _uid(AuthState state) =>
      state is Authenticated ? state.user.uid : null;
}
