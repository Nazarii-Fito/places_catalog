import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/places_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/analytics_service.dart';
import '../data/services/crash_reporter.dart';
import '../features/home/bloc/catalog_view_cubit.dart';
import '../features/places/bloc/places_bloc.dart';

/// Creates the *per-user* blocs while somebody is signed in.
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
    final AuthRepository auth = context.read<AuthRepository>();
    return StreamBuilder<AppUser?>(
      stream: auth.authStateChanges(),
      initialData: auth.currentUser,
      builder: (BuildContext context, AsyncSnapshot<AppUser?> snapshot) {
        final String? uid = snapshot.data?.uid;
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
          ],
          child: child,
        );
      },
    );
  }
}
