# ЛР №4 — приклади коду для звіту

Код у файлах нижче вставлено без змін (повні файли) або фрагментами (позначено).

## 1. Репозиторій автентифікації

### 1.1. `lib/data/repositories/auth_repository.dart` — контракт (повністю)

Екрани знають лише цей інтерфейс, а не Firebase SDK. Тому в тестах і в скриншот-режимі підставляється `FakeAuthRepository`.

```dart
import '../models/app_user.dart';

/// Everything the app needs from authentication.
///
/// Screens depend on this interface only — never on `firebase_auth` — so
/// the backend can be swapped (e.g. `FakeAuthRepository` in tests and the
/// screenshot mode). Every method throws `AuthFailure` on error.
abstract interface class AuthRepository {
  /// Emits on sign-in / sign-out; drives `AuthGate` and session restore.
  Stream<AppUser?> authStateChanges();

  /// Also emits after profile changes (name, photo, linked providers).
  Stream<AppUser?> userChanges();

  AppUser? get currentUser;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  /// Returns `false` when the user cancels the Google sheet (not an error).
  /// Throws `AuthFailureType.accountExistsWithDifferentCredential` when the
  /// e-mail already has a password account — see [completeGoogleLink].
  Future<bool> signInWithGoogle();

  /// Signs in with the existing password account and links the Google
  /// credential that was rejected by [signInWithGoogle].
  Future<void> completeGoogleLink({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> reauthenticate({required String currentPassword});

  /// Re-authenticates with [currentPassword], then sets [newPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> updateProfile({String? displayName, String? photoUrl});

  /// Links Google to the signed-in account. `false` if cancelled.
  Future<bool> linkGoogle();

  Future<void> signOut();
}
```

### 1.2. `lib/data/repositories/firebase_auth_repository.dart` — реалізація на Firebase Auth + Google Sign-In (повністю)

Це єдиний файл застосунку, що імпортує `firebase_auth` і `google_sign_in`. Усі помилки SDK перетворюються на `AuthFailure` у методі `_guard`.

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/auth_failure.dart';
import '../models/app_user.dart';
import '../services/crash_reporter.dart';
import 'auth_repository.dart';

/// [AuthRepository] implemented with Firebase Auth + Google Sign-In 7.x.
///
/// This is the only place in the app that imports `firebase_auth`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required CrashReporter crashReporter,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) : _crash = crashReporter,
       _auth = auth ?? FirebaseAuth.instance,
       _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final CrashReporter _crash;

  /// `GoogleSignIn.initialize` must run exactly once before `authenticate`.
  Future<void>? _googleInit;

  /// Google credential rejected with account-exists, waiting to be linked.
  AuthCredential? _pendingGoogleCredential;

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toApp);

  @override
  Stream<AppUser?> userChanges() => _auth.userChanges().map(_toApp);

  @override
  AppUser? get currentUser => _toApp(_auth.currentUser);

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) => _guard('signUp', () async {
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final User user = result.user!;
    await user.updateDisplayName(fullName);
    // reload + userChanges() lets Profile show the name right away.
    await user.reload();
  });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard('signIn', () async {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      });

  @override
  Future<bool> signInWithGoogle() => _guard('signInWithGoogle', () async {
    final AuthCredential? credential = await _googleCredential();
    if (credential == null) return false;
    try {
      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingGoogleCredential = e.credential ?? credential;
      }
      rethrow;
    }
  });

  @override
  Future<void> completeGoogleLink({
    required String email,
    required String password,
  }) => _guard('completeGoogleLink', () async {
    final AuthCredential? pending = _pendingGoogleCredential;
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (pending != null) {
      await result.user!.linkWithCredential(pending);
      _pendingGoogleCredential = null;
    }
  });

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _guard('sendPasswordResetEmail', () async {
        await _auth.sendPasswordResetEmail(email: email);
      });

  @override
  Future<void> reauthenticate({required String currentPassword}) =>
      _guard('reauthenticate', () => _reauthenticate(currentPassword));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard('changePassword', () async {
    await _reauthenticate(currentPassword);
    await _requireUser().updatePassword(newPassword);
  });

  @override
  Future<void> updateProfile({String? displayName, String? photoUrl}) =>
      _guard('updateProfile', () async {
        final User user = _requireUser();
        if (displayName != null) await user.updateDisplayName(displayName);
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
        await user.reload();
      });

  @override
  Future<bool> linkGoogle() => _guard('linkGoogle', () async {
    final AuthCredential? credential = await _googleCredential();
    if (credential == null) return false;
    await _requireUser().linkWithCredential(credential);
    await _requireUser().reload();
    return true;
  });

  @override
  Future<void> signOut() => _guard('signOut', () async {
    await _auth.signOut();
    if (_googleInit != null) await _google.signOut();
  });

  // ---------------------------------------------------------------------

  Future<void> _reauthenticate(String currentPassword) async {
    final User user = _requireUser();
    final AuthCredential credential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
  }

  User _requireUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure(AuthFailureType.requiresRecentLogin);
    }
    return user;
  }

  /// Runs the Google sheet and converts its ID token into a Firebase
  /// credential. `null` means the user closed the sheet.
  Future<AuthCredential?> _googleCredential() async {
    await (_googleInit ??= _google.initialize());
    try {
      final GoogleSignInAccount account = await _google.authenticate();
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(AuthFailureType.googleUnavailable);
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Converts every SDK error into [AuthFailure]. Unknown codes and
  /// unexpected errors are sent to Crashlytics as non-fatal.
  Future<T> _guard<T>(String action, Future<T> Function() body) async {
    await _crash.log('Auth: $action');
    try {
      return await body();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e, stack) {
      final AuthFailure failure = AuthFailure.fromCode(e.code, email: e.email);
      if (failure.isUnknown) {
        await _crash.recordError(e, stack, reason: 'Auth $action: ${e.code}');
      }
      throw failure;
    } on GoogleSignInException catch (e, stack) {
      await _crash.recordError(e, stack, reason: 'Google $action: ${e.code}');
      throw const AuthFailure(AuthFailureType.googleUnavailable);
    } catch (e, stack) {
      await _crash.recordError(e, stack, reason: 'Auth $action failed');
      throw const AuthFailure(AuthFailureType.unknown);
    }
  }

  static AppUser? _toApp(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providerIds: {
        for (final UserInfo info in user.providerData) info.providerId,
      },
    );
  }
}
```

### 1.3. `lib/core/errors/auth_failure.dart` — мапінг кодів помилок (повністю)

```dart
import '../constants/app_strings.dart';

/// Kinds of authentication errors the UI distinguishes.
enum AuthFailureType {
  invalidEmail,
  invalidCredentials,
  userDisabled,
  emailAlreadyInUse,
  weakPassword,
  tooManyRequests,
  network,
  requiresRecentLogin,
  operationNotAllowed,

  /// Google sign-in for an e-mail that already has a password account —
  /// the UI asks for the password and links both methods.
  accountExistsWithDifferentCredential,
  credentialAlreadyInUse,
  providerAlreadyLinked,
  googleUnavailable,
  unknown,
}

/// Error thrown by `AuthRepository` instead of raw SDK exceptions, so the
/// UI shows a clear message and never the exception text.
class AuthFailure implements Exception {
  const AuthFailure(this.type, {this.code, this.email});

  /// Maps a `FirebaseAuthException.code` to a failure type.
  factory AuthFailure.fromCode(String code, {String? email}) {
    final AuthFailureType type = switch (code) {
      'invalid-email' => AuthFailureType.invalidEmail,
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'INVALID_LOGIN_CREDENTIALS' => AuthFailureType.invalidCredentials,
      'user-disabled' => AuthFailureType.userDisabled,
      'email-already-in-use' => AuthFailureType.emailAlreadyInUse,
      'weak-password' => AuthFailureType.weakPassword,
      'too-many-requests' => AuthFailureType.tooManyRequests,
      'network-request-failed' => AuthFailureType.network,
      'requires-recent-login' ||
      'user-token-expired' => AuthFailureType.requiresRecentLogin,
      'operation-not-allowed' => AuthFailureType.operationNotAllowed,
      'account-exists-with-different-credential' =>
        AuthFailureType.accountExistsWithDifferentCredential,
      'credential-already-in-use' ||
      'email-already-linked' => AuthFailureType.credentialAlreadyInUse,
      'provider-already-linked' => AuthFailureType.providerAlreadyLinked,
      _ => AuthFailureType.unknown,
    };
    return AuthFailure(type, code: code, email: email);
  }

  final AuthFailureType type;

  /// Original SDK code, kept for Crashlytics — never shown to the user.
  final String? code;

  /// E-mail of the existing account (for account-exists linking).
  final String? email;

  bool get isUnknown => type == AuthFailureType.unknown;

  /// User-facing text for this failure.
  String get message => switch (type) {
    AuthFailureType.invalidEmail => AppStrings.errorInvalidEmail,
    AuthFailureType.invalidCredentials => AppStrings.errorInvalidCredentials,
    AuthFailureType.userDisabled => AppStrings.errorUserDisabled,
    AuthFailureType.emailAlreadyInUse => AppStrings.errorEmailInUse,
    AuthFailureType.weakPassword => AppStrings.errorWeakPassword,
    AuthFailureType.tooManyRequests => AppStrings.errorTooManyRequests,
    AuthFailureType.network => AppStrings.errorNetwork,
    AuthFailureType.requiresRecentLogin => AppStrings.errorRecentLogin,
    AuthFailureType.operationNotAllowed => AppStrings.errorNotAllowed,
    AuthFailureType.accountExistsWithDifferentCredential =>
      AppStrings.errorAccountExists,
    AuthFailureType.credentialAlreadyInUse => AppStrings.errorCredentialInUse,
    AuthFailureType.providerAlreadyLinked => AppStrings.errorAlreadyLinked,
    AuthFailureType.googleUnavailable => AppStrings.errorGoogleUnavailable,
    AuthFailureType.unknown => AppStrings.errorUnknown,
  };

  @override
  String toString() => 'AuthFailure($type, code: $code)';
}
```

## 2. Приклад виклику методу репозиторію з відображенням даних

### 2.1. Відображення даних: `ProfileScreen` зі `StreamBuilder` на `userChanges()` (фрагмент)

Файл `lib/features/profile/screens/profile_screen.dart`. Ім'я, email, фото й підключені провайдери приходять із Firebase. Після Edit Profile чи Link Google стрим видає оновленого користувача, і екран перебудовується сам.

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Created once (not in build) so the StreamBuilder keeps its listener.
    _user ??= AppScope.of(context).auth.userChanges();
  }

  // ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(title: AppStrings.tabProfile),
      body: StreamBuilder<AppUser?>(
        stream: _user,
        initialData: AppScope.of(context).auth.currentUser,
        builder: (BuildContext context, AsyncSnapshot<AppUser?> snapshot) {
          final AppUser? user = snapshot.data;
          // Signed out: AuthGate is about to replace this screen.
          if (user == null) return const SizedBox.shrink();
          // ...
          return ListView(
            children: [
              ProfileHero(
                name: user.name,
                email: user.email ?? '',
                photoUrl: user.photoUrl,
                initials: user.initials,
                onEdit: () =>
                    Navigator.of(context).pushNamed(AppRoutes.editProfile),
              ),
              // ... statistics (mock), Change Password, Connected Accounts
              ConnectedAccountsGroup(
                user: user,
                linkingGoogle: _linkingGoogle,
                onLinkGoogle: _linkGoogle,
              ),
              // ... Export, Log Out, VersionFooter
            ],
          );
        },
      ),
    );
  }
```

### 2.2. Виклик методу з обробкою завантаження і помилок: `LoginScreen._submit()` (фрагмент)

Файл `lib/features/auth/screens/login_screen.dart`.

```dart
class _LoginScreenState extends State<LoginScreen> {
  // Created once per State — never in build(), or every rebuild would
  // create a new form and lose the field state.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return; // a second tap must not send a second request
    FocusScope.of(context).unfocus();
    // After the first attempt, fields re-validate while the user types.
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AppScope scope = AppScope.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await scope.auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await scope.analytics.logLogin('password');
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
  // ...
}
```

Відображення стану в `build()`: банер помилки та кнопка з loading.

```dart
        if (error != null) ...[
          ErrorBanner(message: error),
          const SizedBox(height: AppSpacing.m),
        ] else
          const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: AppStrings.logIn,
          isLoading: _submitting, // spinner + taps ignored
          onPressed: _submit,
        ),
```

## 3. Форма реєстрації — `RegisterScreen` (`Form`, `GlobalKey`, валідатори)

Файл `lib/features/auth/screens/register_screen.dart`. Поле `AppTextField` побудоване на `FormField<String>`, тому `validate()` перевіряє всі поля форми. Валідатори — чисті функції з `lib/core/validation/validators.dart`.

```dart
class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AppScope scope = AppScope.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await scope.auth.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await scope.analytics.logSignUp('password');
      // AuthGate now shows the main shell and pops this screen.
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
  // ... _social(), header

  @override
  Widget build(BuildContext context) {
    // ...
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: AppStrings.fullNameLabel,
                hintText: AppStrings.fullNameHint,
                prefixIcon: AppAssets.iconPerson,
                controller: _nameController,
                readOnly: _submitting,
                validator: Validators.fullName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              AppTextField(
                label: AppStrings.emailLabel,
                hintText: AppStrings.emailHint,
                prefixIcon: AppAssets.iconMail,
                controller: _emailController,
                readOnly: _submitting,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              AppTextField(
                label: AppStrings.passwordLabel,
                hintText: AppStrings.passwordHint,
                prefixIcon: AppAssets.iconLock,
                controller: _passwordController,
                isPassword: true,
                readOnly: _submitting,
                helperText: AppStrings.passwordHelper,
                validator: Validators.newPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        // ... ErrorBanner, PrimaryButton(isLoading: _submitting, onPressed: _submit)
```

Валідатори, що використовуються у формі (фрагмент `validators.dart`):

```dart
  static String? fullName(String? value) {
    final String name = value?.trim() ?? '';
    if (name.isEmpty) return AppStrings.validationRequired;
    if (name.length < 2 || name.length > 50) {
      return AppStrings.validationNameLength;
    }
    return null;
  }

  static String? email(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) return AppStrings.validationRequired;
    return _email.hasMatch(email) ? null : AppStrings.validationEmail;
  }

  /// Policy for new passwords (matches the helper text in the design).
  static String? newPassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return AppStrings.validationRequired;
    if (password.length < 8 || !_digit.hasMatch(password)) {
      return AppStrings.validationPassword;
    }
    return null;
  }
```

## 4. `lib/main.dart` після змін (повністю)

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'app/dev_launch_options.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/fake_auth_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/services/analytics_service.dart';
import 'data/services/crash_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase must be ready before Auth / Analytics / Crashlytics are used.
  //    The options are generated by `flutterfire configure`.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Crashlytics catches everything that is not handled in code:
  //    errors inside the Flutter framework (build/layout/paint) …
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  //    … and asynchronous errors outside of it (futures, platform channels).
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Portrait only, dark status-bar icons on the light background.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  final CrashReporter crashReporter = FirebaseCrashReporter(
    FirebaseCrashlytics.instance,
  );
  final AuthRepository auth = DevLaunchOptions.useFakeAuth
      ? _fakeAuth()
      : FirebaseAuthRepository(crashReporter: crashReporter);

  runApp(
    AppScope(
      auth: auth,
      analytics: FirebaseAnalyticsService(FirebaseAnalytics.instance),
      crashReporter: crashReporter,
      child: const PlacesCatalogApp(),
    ),
  );
}

/// Screenshot mode (debug only): screens without network or a real account.
AuthRepository _fakeAuth() {
  assert(kDebugMode, 'FAKE_AUTH is meant for debug screenshots only.');
  return DevLaunchOptions.fakeAuth == 'signed_in'
      ? FakeAuthRepository.signedIn()
      : FakeAuthRepository();
}
```
