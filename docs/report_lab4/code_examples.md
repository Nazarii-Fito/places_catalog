# ЛР №4 — приклади коду для звіту

Код нижче вставлено без змін із репозиторію (станом на останній коміт): або файл повністю, або фрагмент (позначено). Файл згенеровано скриптом із поточних джерел, тож він збігається з кодом проєкту.

## 1. Репозиторій автентифікації

Уся робота з Firebase Auth, Google Sign-In і Sign in with Apple зосереджена в `FirebaseAuthRepository`. Жоден файл у `lib/features/` і `lib/core/` не імпортує `firebase_auth`, `google_sign_in` чи `sign_in_with_apple` — екрани працюють лише з абстрактним `AuthRepository` (перевірено `grep`).


### 1.1. `lib/data/repositories/auth_repository.dart` — контракт (повністю)

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

  /// Native Sign in with Apple (iOS). Returns `false` when the user cancels.
  /// Apple shares the name only on the first sign-in, so it is saved then.
  Future<bool> signInWithApple();

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


### 1.2. `lib/data/repositories/firebase_auth_repository.dart` — реалізація: Firebase Auth + Google Sign-In + Sign in with Apple (повністю)

Метод `signInWithApple()` — нативний потік: випадковий nonce, SHA-256 для Apple і сирий nonce для Firebase; ім'я Apple віддає лише при першому вході. `_guard` перетворює будь-яку помилку SDK на `AuthFailure`, а невідомі коди додатково надсилає в Crashlytics як non-fatal.

```dart
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/errors/auth_failure.dart';
import '../models/app_user.dart';
import '../services/crash_reporter.dart';
import 'auth_repository.dart';

/// [AuthRepository] implemented with Firebase Auth, Google Sign-In 7.x and
/// native Sign in with Apple.
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
  Future<bool> signInWithApple() => _guard('signInWithApple', () async {
    if (!await SignInWithApple.isAvailable()) {
      throw const AuthFailure(AuthFailureType.appleUnavailable);
    }
    // Firebase checks the nonce: Apple gets its SHA-256, Firebase the raw one.
    final String rawNonce = _randomNonce();
    final String hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return false;
      rethrow;
    }
    final String? idToken = apple.identityToken;
    if (idToken == null) {
      throw const AuthFailure(AuthFailureType.appleUnavailable);
    }
    final UserCredential result = await _auth.signInWithCredential(
      OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      ),
    );
    // Apple sends the name only the very first time.
    final User? user = result.user;
    final String name = [
      apple.givenName,
      apple.familyName,
    ].whereType<String>().join(' ').trim();
    if (user != null && (user.displayName ?? '').isEmpty && name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }
    return true;
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

  static String _randomNonce([int length = 32]) {
    const String charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final Random random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
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
    } on SignInWithAppleException catch (e, stack) {
      await _crash.recordError(e, stack, reason: 'Apple $action');
      throw const AuthFailure(AuthFailureType.appleUnavailable);
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
  appleUnavailable,
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
    AuthFailureType.appleUnavailable => AppStrings.errorAppleUnavailable,
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
class _ProfileScreenState extends State<ProfileScreen> {
  Stream<AppUser?>? _user;
  bool _linkingGoogle = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Created once (not in build) so the StreamBuilder keeps its listener.
    _user ??= AppScope.of(context).auth.userChanges();
  }

  void _openChangePassword(AppUser user) {
    if (!user.hasPassword) {
      // Google-only account: there is no password to re-authenticate with.
      AppConfirmDialog.show(
        context,
        title: AppStrings.noPasswordTitle,
        message: AppStrings.noPasswordMessage,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.changePassword);
  }

  Future<void> _linkGoogle() async {
    if (_linkingGoogle) return;
    final AppScope scope = AppScope.of(context);
    setState(() => _linkingGoogle = true);
    try {
      final bool linked = await scope.auth.linkGoogle();
      if (linked) await scope.analytics.logAccountLinked('google.com');
    } on AuthFailure catch (failure) {
      if (mounted) {
        await AppConfirmDialog.show(
          context,
          title: AppStrings.linkFailedTitle,
          message: failure.message,
          confirmLabel: AppStrings.ok,
          cancelLabel: null,
        );
      }
    } finally {
      if (mounted) setState(() => _linkingGoogle = false);
    }
  }

  Future<void> _confirmLogOut() async {
    final AppScope scope = AppScope.of(context);
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.logOutDialogTitle,
      message: AppStrings.logOutDialogMessage,
      confirmLabel: AppStrings.logOut,
      isDestructive: true,
    );
    if (!confirmed) return;
    // AuthGate notices the signed-out state and shows Login.
    try {
      await scope.auth.signOut();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      await AppConfirmDialog.show(
        context,
        title: AppStrings.logOut,
        message: failure.message,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
    }
  }

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
          final EdgeInsets insets = MediaQuery.paddingOf(context);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              insets.top,
              AppSpacing.screen,
              insets.bottom + AppSpacing.sm,
            ),
            children: [
              ProfileHero(
                name: user.name,
                email: user.email ?? '',
                photoUrl: user.photoUrl,
                initials: user.initials,
                onEdit: () =>
                    Navigator.of(context).pushNamed(AppRoutes.editProfile),
              ),
              const SizedBox(height: AppSpacing.l),
              // Visit statistics stay a mock until places live in Firestore.
              ActivitySummaryCard(stats: mockUser.stats),
              const SizedBox(height: AppSpacing.l),
              const SectionLabel(AppStrings.accountSettings),
              const SizedBox(height: AppSpacing.s),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: const AppSvgIcon(
                      AppAssets.iconLock,
                      height: 14,
                      color: AppColors.textPrimary,
                    ),
                    title: AppStrings.changePassword,
                    onTap: () => _openChangePassword(user),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              const SectionLabel(AppStrings.connectedAccounts),
              const SizedBox(height: AppSpacing.s),
              ConnectedAccountsGroup(
                user: user,
                linkingGoogle: _linkingGoogle,
                onLinkGoogle: _linkGoogle,
              ),
              const SizedBox(height: AppSpacing.l),
              const SectionLabel(AppStrings.dataAndPrivacy),
              const SizedBox(height: AppSpacing.s),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: const AppSvgIcon(AppAssets.iconDownload),
                    title: AppStrings.exportArchive,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.exportArchive,
                      arguments: widget.places,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l + AppSpacing.xs),
              LogOutButton(onPressed: _confirmLogOut),
              const SizedBox(height: AppSpacing.sm),
              const VersionFooter(),
            ],
          );
        },
      ),
    );
  }
}
```


### 2.2. Виклик методу з обробкою завантаження і помилок: `LoginScreen` (фрагмент)

Файл `lib/features/auth/screens/login_screen.dart`. `GlobalKey<FormState>` живе в `State`; `_submit` спершу валідує форму, потім вмикає стан завантаження (кнопка показує індикатор, поля лише для читання, повторний запит заблоковано), викликає `signIn` і показує помилку Firebase банером. Входи через Apple та Google (`_social`) викликають `runSocialSignIn`.

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

  Future<void> _social(SocialProvider provider) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final String? error = await runSocialSignIn(context, provider);
    if (mounted) {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
    // Gaps are tighter than in Figma so the whole form fits an iPhone 17
    // screen without scrolling (see docs/decisions.md).
    return AuthPage(
      form: [
        const SizedBox(height: AppSpacing.m),
        const AuthHeader(
          title: AppStrings.appName,
          subtitle: TextSpan(text: AppStrings.tagline),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: AppStrings.emailLabel,
                hintText: AppStrings.emailHint,
                prefixIcon: AppAssets.iconMail,
                controller: _emailController,
                readOnly: _submitting,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.l),
              AppTextField(
                label: AppStrings.passwordLabel,
                hintText: AppStrings.passwordHint,
                prefixIcon: AppAssets.iconLock,
                controller: _passwordController,
                isPassword: true,
                readOnly: _submitting,
                // Sign-in only checks presence; the policy applies to new
                // passwords. Whether it is correct is Firebase's answer.
                validator: Validators.required,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: Align(
            alignment: Alignment.centerRight,
            child: AppTextLink(
              label: AppStrings.forgotPassword,
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
            ),
          ),
        ),
        if (error != null) ...[
          ErrorBanner(message: error),
          const SizedBox(height: AppSpacing.m),
        ] else
          const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: AppStrings.logIn,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.m),
        SecondaryButton(
          label: AppStrings.createAccount,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pushNamed(AppRoutes.register),
        ),
        const SizedBox(height: 20),
        const DividerWithText(text: AppStrings.orContinueWith),
        const SizedBox(height: 20),
        SocialAuthRow(onProviderSelected: _social),
      ],
      // Pinned to the bottom edge of the screen.
      footer: const [
        SizedBox(height: AppSpacing.l),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: AuthLegalText(prefix: AppStrings.loginLegalPrefix),
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
```


## 3. Форма реєстрації — `RegisterScreen` і валідатори (`Form`, `GlobalKey`)

Файл `lib/features/auth/screens/register_screen.dart`. Поле `AppTextField` побудоване на `FormField<String>`, тому `validate()` перевіряє всі поля форми. Валідатори — чисті функції з `lib/core/validation/validators.dart`.

### 3.1. `RegisterScreen` (фрагмент)

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

  Future<void> _social(SocialProvider provider) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final String? error = await runSocialSignIn(context, provider);
    if (mounted) {
      setState(() {
        _submitting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
    // Gaps are tighter than in Figma so the form fits an iPhone 17 screen
    // without scrolling (see docs/decisions.md).
    return AuthPage(
      form: [
        // "‹ Log In": the chevron lines up with the 16 pt margin.
        Transform.translate(
          offset: const Offset(-AppSpacing.sm, 0),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: NavBackButton(label: AppStrings.logIn),
          ),
        ),
        const AuthHeader(
          title: AppStrings.createAccount,
          subtitle: TextSpan(text: AppStrings.registerSubtitle),
          iconGap: AppSpacing.l,
        ),
        const SizedBox(height: AppSpacing.l),
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
                autofillHints: const [AutofillHints.name],
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
                autofillHints: const [AutofillHints.email],
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
                autofillHints: const [AutofillHints.newPassword],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        if (error != null) ...[
          ErrorBanner(message: error),
          const SizedBox(height: AppSpacing.m),
        ],
        PrimaryButton(
          label: AppStrings.createAccount,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.ml),
        const DividerWithText(text: AppStrings.orContinueWith),
        const SizedBox(height: AppSpacing.ml),
        SocialAuthRow(onProviderSelected: _social),
      ],
      // Pinned to the bottom edge of the screen.
      footer: [
        const SizedBox(height: AppSpacing.l),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: AuthLegalText(prefix: AppStrings.registerLegalPrefix),
        ),
        AuthSwitchPrompt(
          question: AppStrings.alreadyHaveAccount,
          actionLabel: AppStrings.logIn,
          onAction: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
```

### 3.2. `lib/core/validation/validators.dart` (повністю)

```dart
import '../constants/app_strings.dart';

/// Pure `TextFormField.validator` functions: return `null` when the value is
/// valid, otherwise the message shown under the field. They only check the
/// format locally — whether the password is *correct* is decided by
/// Firebase and reported as an `AuthFailure`.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _digit = RegExp(r'\d');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty)
      ? AppStrings.validationRequired
      : null;

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

  /// Returns a validator that checks the value equals [other]().
  static String? Function(String?) matches(String Function() other) =>
      (String? value) {
        if (value == null || value.isEmpty) {
          return AppStrings.validationRequired;
        }
        return value == other() ? null : AppStrings.validationConfirm;
      };

  /// New password policy + must differ from the current password.
  static String? Function(String?) newPasswordDifferentFrom(
    String Function() current,
  ) => (String? value) {
    final String? policy = newPassword(value);
    if (policy != null) return policy;
    return value == current() ? AppStrings.validationSameAsCurrent : null;
  };

  static String? httpsUrl(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.validationRequired;
    final Uri? uri = Uri.tryParse(text);
    final bool ok =
        uri != null && uri.scheme == 'https' && uri.host.contains('.');
    return ok ? null : AppStrings.validationHttpsUrl;
  }
}
```


## 4. Вхід через соціальні провайдери

### 4.1. `lib/features/auth/widgets/social_sign_in.dart` (повністю)

Apple і Google. Для Google при `account-exists-with-different-credential` показується діалог із паролем, після якого `completeGoogleLink` входить у наявний акаунт і прив'язує Google — це об'єднання кількох способів входу в один акаунт.

```dart
import 'package:flutter/cupertino.dart';

import '../../../app/app_scope.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/auth_failure.dart';
import '../../../core/widgets/social_auth_button.dart';

/// Runs the chosen social sign-in from Login / Create Account.
///
/// Returns an error message for the banner, or `null` on success or
/// cancel.
Future<String?> runSocialSignIn(
  BuildContext context,
  SocialProvider provider,
) async {
  switch (provider) {
    case SocialProvider.apple:
      return _runApple(context);
    case SocialProvider.google:
      return _runGoogle(context);
  }
}

Future<String?> _runApple(BuildContext context) async {
  final AppScope scope = AppScope.of(context);
  try {
    final bool signedIn = await scope.auth.signInWithApple();
    if (signedIn) await scope.analytics.logLogin('apple');
    return null;
  } on AuthFailure catch (failure) {
    return failure.message;
  }
}

Future<String?> _runGoogle(BuildContext context) async {
  final AppScope scope = AppScope.of(context);
  try {
    final bool signedIn = await scope.auth.signInWithGoogle();
    if (signedIn) await scope.analytics.logLogin('google');
    return null;
  } on AuthFailure catch (failure) {
    final String? email = failure.email;
    if (failure.type != AuthFailureType.accountExistsWithDifferentCredential ||
        email == null) {
      return failure.message;
    }
    // Same e-mail already has a password account: confirm the password,
    // then link Google to it — one account, two sign-in methods.
    if (!context.mounted) return null;
    final String? password = await showCupertinoDialog<String>(
      context: context,
      builder: (_) => _LinkPasswordDialog(email: email),
    );
    if (password == null || password.isEmpty) return null;
    try {
      await scope.auth.completeGoogleLink(email: email, password: password);
      await scope.analytics.logAccountLinked('google.com');
      return null;
    } on AuthFailure catch (linkFailure) {
      return linkFailure.message;
    }
  }
}

class _LinkPasswordDialog extends StatefulWidget {
  const _LinkPasswordDialog({required this.email});

  final String email;

  @override
  State<_LinkPasswordDialog> createState() => _LinkPasswordDialogState();
}

class _LinkPasswordDialogState extends State<_LinkPasswordDialog> {
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_password.text);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(AppStrings.linkGoogleTitle),
      content: Column(
        children: [
          Text('${AppStrings.linkGoogleMessage}\n${widget.email}'),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _password,
            autofocus: true,
            obscureText: true,
            placeholder: AppStrings.passwordLabel,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _submit,
          child: const Text(AppStrings.connect),
        ),
      ],
    );
  }
}
```


## 5. Зміна пароля з повторною автентифікацією — `ChangePasswordScreen` (фрагмент)

Файл `lib/features/profile/screens/change_password_screen.dart`. `changePassword` у репозиторії спершу робить `reauthenticateWithCredential`, потім `updatePassword`. Хибний поточний пароль показується помилкою біля поля, `requires-recent-login` — діалогом із пропозицією увійти знову. Діалоги показуються після зупинки індикатора завантаження.

```dart
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _submitting = false;

  /// Firebase rejected the current password — shown under that field.
  String? _currentPasswordError;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
      _currentPasswordError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AppScope scope = AppScope.of(context);
    final NavigatorState navigator = Navigator.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    bool needsSignIn = false;
    bool changed = false;
    try {
      // Re-authenticates with the current password, then updates it.
      await scope.auth.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      await scope.analytics.logPasswordChanged();
      changed = true;
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      switch (failure.type) {
        case AuthFailureType.invalidCredentials:
          setState(() => _currentPasswordError = failure.message);
        case AuthFailureType.requiresRecentLogin:
          needsSignIn = true;
        default:
          setState(() => _error = failure.message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    // Dialogs are shown after the spinner stops, so it doesn't keep
    // spinning behind them.
    if (!mounted) return;
    if (changed) {
      await AppConfirmDialog.show(
        context,
        title: AppStrings.passwordUpdatedTitle,
        message: AppStrings.passwordUpdatedMessage,
        confirmLabel: AppStrings.ok,
        cancelLabel: null,
      );
      navigator.pop();
    } else if (needsSignIn) {
      await _askToSignInAgain(scope);
    }
  }

  /// `requires-recent-login`: the session is too old for a sensitive
  /// change. Explain it and offer to log out and back in.
  Future<void> _askToSignInAgain(AppScope scope) async {
    final bool signOut = await AppConfirmDialog.show(
      context,
      title: AppStrings.signInAgainTitle,
      message: AppStrings.errorRecentLogin,
      confirmLabel: AppStrings.logOut,
    );
    if (signOut) await scope.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppNavHeader(
        leading: NavBackButton(label: AppStrings.tabProfile),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Builder(
          builder: (BuildContext context) {
            final EdgeInsets insets = MediaQuery.paddingOf(context);
            return Form(
              key: _formKey,
              autovalidateMode: _autovalidate,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  insets.top + AppSpacing.sm,
                  AppSpacing.screen,
                  insets.bottom + AppSpacing.xl,
                ),
                children: [
                  const _TitleBlock(),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: AppStrings.currentPasswordLabel,
                    hintText: AppStrings.passwordHint,
                    prefixIcon: AppAssets.iconLock,
                    controller: _currentController,
                    isPassword: true,
                    readOnly: _submitting,
                    validator: Validators.required,
                    errorText: _currentPasswordError,
                    onChanged: (_) {
                      if (_currentPasswordError != null) {
                        setState(() => _currentPasswordError = null);
                      }
                    },
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AppTextLink(
                        label: AppStrings.forgotCurrentPassword,
                        onTap: () =>
                            Navigator.of(context)
                                .pushNamed(AppRoutes.forgotPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  AppTextField(
                    label: AppStrings.newPasswordLabel,
                    hintText: AppStrings.passwordHint,
                    prefixIcon: AppAssets.iconLock,
                    controller: _newController,
                    isPassword: true,
                    readOnly: _submitting,
                    helperText: AppStrings.passwordHelper,
                    validator: Validators.newPasswordDifferentFrom(
                      () => _currentController.text,
                    ),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  AppTextField(
                    label: AppStrings.confirmPasswordLabel,
                    hintText: AppStrings.passwordHint,
                    prefixIcon: AppAssets.iconLock,
                    controller: _confirmController,
                    isPassword: true,
                    readOnly: _submitting,
                    validator: Validators.matches(() => _newController.text),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _updatePassword(),
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: AppSpacing.l + AppSpacing.sm),
                  if (error != null) ...[
                    ErrorBanner(message: error),
                    const SizedBox(height: AppSpacing.m),
                  ],
                  PrimaryButton(
                    label: AppStrings.updatePassword,
                    isLoading: _submitting,
                    onPressed: _updatePassword,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4.5),
        Text(
          AppStrings.accountSecurity.toUpperCase(),
          style: AppTextStyles.overline,
        ),
        const SizedBox(height: 1.5),
        const Text(AppStrings.changePassword, style: AppTextStyles.largeTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.changePasswordSubtitle,
          style: AppTextStyles.subheadline.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
```


## 6. Відновлення сеансу — `AuthGate` (повністю)

Корінь застосунку слухає `authStateChanges()`: поки чекаємо — заставка, без користувача — екран входу, інакше — головний екран. Тому після перезапуску залогінений користувач одразу потрапляє на Home.

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_logo.dart';
import '../data/models/app_user.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/shell/main_shell.dart';
import 'app_scope.dart';

/// Root of the app: shows Login or [MainShell] depending on Firebase Auth.
///
/// * UI = f(auth state): a [StreamBuilder] on `authStateChanges()`.
///   Firebase keeps the session on the device, so after a restart a
///   signed-in user goes straight to [MainShell] — session restore.
/// * Side effects (clearing pushed auth screens, analytics / crash user id)
///   run in a separate subscription, never inside `build()`.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Stream<AppUser?>? _authState;
  StreamSubscription<AppUser?>? _sideEffects;
  String? _lastUid;
  bool _firstEvent = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authState != null) return;
    final AppScope scope = AppScope.of(context);
    _authState = scope.auth.authStateChanges();
    _sideEffects = scope.auth.authStateChanges().listen((AppUser? user) {
      final String? uid = user?.uid;
      scope.analytics.setUserId(uid);
      scope.crashReporter.setUserIdentifier(uid);
      // Sign-in / sign-out from a pushed screen (Register, Forgot, …):
      // drop those routes so the gate's new root is visible.
      if (!_firstEvent && uid != _lastUid && mounted) {
        Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
      }
      _firstEvent = false;
      _lastUid = uid;
    });
  }

  @override
  void dispose() {
    _sideEffects?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _authState,
      builder: (BuildContext context, AsyncSnapshot<AppUser?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final AppUser? user = snapshot.data;
        if (user == null) return const LoginScreen();
        // A new key per user resets tab state after switching accounts.
        return MainShell(key: ValueKey<String>(user.uid));
      },
    );
  }
}

/// Shown for the split second while Firebase restores the session.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: AppLogo.large()),
    );
  }
}
```


## 7. Analytics і Crashlytics

### 7.1. `lib/data/services/analytics_service.dart` (повністю)

```dart
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
```

### 7.2. `lib/data/services/crash_reporter.dart` (повністю)

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Crash & error reporting API used by the app (wraps Crashlytics).
abstract interface class CrashReporter {
  /// Ties reports to a user. Uses the Firebase uid — never e-mail or name.
  Future<void> setUserIdentifier(String? uid);

  /// Breadcrumb shown in the "Logs" tab of the next report.
  Future<void> log(String message);

  /// Non-fatal by default: the app keeps running, the issue is still
  /// reported. `fatal: true` only marks the report — it does not exit.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Developer menu: a handled test error that appears in Crashlytics.
  Future<void> sendTestNonFatal();

  /// Developer menu: terminates the app with a native test crash.
  void forceTestCrash();
}

class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setUserIdentifier(String? uid) =>
      _crashlytics.setUserIdentifier(uid ?? '');

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) => _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);

  @override
  Future<void> sendTestNonFatal() async {
    await log('Developer menu: test non-fatal error');
    await recordError(
      StateError('PlacesCatalog test non-fatal error'),
      StackTrace.current,
      reason: 'Triggered from the Profile developer menu',
    );
  }

  @override
  void forceTestCrash() => _crashlytics.crash();
}

/// Does nothing — used by widget tests and the screenshot mode.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> setUserIdentifier(String? uid) async {}
  @override
  Future<void> log(String message) async {}
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {}
  @override
  Future<void> sendTestNonFatal() async {}
  @override
  void forceTestCrash() {}
}
```


## 8. `lib/main.dart` (повністю)

Ініціалізація Firebase, глобальні обробники помилок для Crashlytics (`FlutterError.onError`, `PlatformDispatcher.onError`), залежності передаються через `AppScope`.

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
