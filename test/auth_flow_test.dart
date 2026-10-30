import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/app/app.dart';
import 'package:places_catalog/core/constants/app_strings.dart';
import 'package:places_catalog/core/errors/auth_failure.dart';
import 'package:places_catalog/data/models/app_user.dart';
import 'package:places_catalog/data/repositories/fake_auth_repository.dart';
import 'package:places_catalog/features/auth/screens/forgot_password_screen.dart';
import 'package:places_catalog/features/auth/screens/login_screen.dart';
import 'package:places_catalog/features/auth/screens/register_screen.dart';
import 'package:places_catalog/features/profile/screens/change_password_screen.dart';
import 'package:places_catalog/features/shell/main_shell.dart';

import 'helpers/test_harness.dart';

/// Auth scenarios from the Lab 4 checklist, against [FakeAuthRepository].
void main() {
  setUpAll(loadInterFont);

  Finder field(int index) => find.byType(EditableText).at(index);

  testWidgets('Failed log-in shows the error banner and stays on Login', (
    WidgetTester tester,
  ) async {
    useIPhone(tester);
    final FakeAuthRepository auth = FakeAuthRepository()
      ..nextFailure = const AuthFailure(AuthFailureType.invalidCredentials);
    await tester.pumpWidget(testApp(const LoginScreen(), auth: auth));

    await tester.enterText(field(0), 'me@icloud.com');
    await tester.enterText(field(1), 'wrong-password');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.errorInvalidCredentials), findsOneWidget);
    expect(auth.currentUser, isNull);
  });

  testWidgets('Apple button signs in through the repository', (
    WidgetTester tester,
  ) async {
    useIPhone(tester);
    final FakeAuthRepository auth = FakeAuthRepository();
    await tester.pumpWidget(withScope(const PlacesCatalogApp(), auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apple'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signInWithApple']);
    expect(auth.currentUser!.providerIds, contains(AppUser.appleProvider));
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('Loading state blocks a second request', (
    WidgetTester tester,
  ) async {
    useIPhone(tester);
    final FakeAuthRepository auth = FakeAuthRepository()
      ..gate = Completer<void>();
    await tester.pumpWidget(testApp(const LoginScreen(), auth: auth));

    await tester.enterText(field(0), 'me@icloud.com');
    await tester.enterText(field(1), 'places2026');
    await tester.tap(find.text('Log In'));
    await tester.pump();

    // Spinner instead of the label; tapping again sends nothing.
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.text('Log In'), findsNothing);
    await tester.tap(find.byType(CupertinoActivityIndicator));
    await tester.pump();
    expect(auth.calls, ['signIn']);

    auth.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Invalid sign-up form shows errors and does not call signUp', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1000));
    final FakeAuthRepository auth = FakeAuthRepository();
    await tester.pumpWidget(testApp(const RegisterScreen(), auth: auth));

    await tester.enterText(field(1), 'not-an-email');
    await tester.enterText(field(2), 'short');
    await tester.tap(find.text('Create Account').last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.validationRequired), findsOneWidget); // name
    expect(find.text(AppStrings.validationEmail), findsOneWidget);
    expect(find.text(AppStrings.validationPassword), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('Sign-up with a taken e-mail shows the Firebase error', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1000));
    final FakeAuthRepository auth = FakeAuthRepository()
      ..nextFailure = const AuthFailure(AuthFailureType.emailAlreadyInUse);
    await tester.pumpWidget(testApp(const RegisterScreen(), auth: auth));

    await tester.enterText(field(0), 'Nazarii Fito');
    await tester.enterText(field(1), 'nazarii.fito@gmail.com');
    await tester.enterText(field(2), 'places2026');
    await tester.tap(find.text('Create Account').last);
    await tester.pumpAndSettle();

    expect(auth.calls, ['signUp']);
    expect(find.text(AppStrings.errorEmailInUse), findsOneWidget);
  });

  testWidgets('Session restore: a saved user opens Home; Log Out → Login', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    final FakeAuthRepository auth = FakeAuthRepository.signedIn();
    await tester.pumpWidget(withScope(const PlacesCatalogApp(), auth: auth));
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Nazarii Fito'), findsOneWidget);
    expect(find.text('nazarii.fito@gmail.com'), findsOneWidget);

    await tester.tap(find.text('Log Out').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out').last); // destructive dialog action
    await tester.pumpAndSettle();

    expect(auth.calls, contains('signOut'));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Forgot Password sends the link and shows the neutral state', (
    WidgetTester tester,
  ) async {
    useIPhone(tester);
    final FakeAuthRepository auth = FakeAuthRepository();
    await tester.pumpWidget(testApp(const ForgotPasswordScreen(), auth: auth));

    await tester.enterText(field(0), 'me@icloud.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['sendPasswordResetEmail']);
    expect(find.text('Check your email'), findsOneWidget);
  });

  testWidgets('Change Password: wrong current password → field error', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1000));
    final FakeAuthRepository auth = FakeAuthRepository.signedIn()
      ..nextFailure = const AuthFailure(AuthFailureType.invalidCredentials);
    await tester.pumpWidget(testApp(const ChangePasswordScreen(), auth: auth));

    await tester.enterText(field(0), 'wrong-one');
    await tester.enterText(field(1), 'catalog2027');
    await tester.enterText(field(2), 'catalog2027');
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['changePassword']);
    expect(find.text(AppStrings.errorInvalidCredentials), findsOneWidget);
  });

  testWidgets('Change Password: requires-recent-login offers to log in again', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1000));
    final FakeAuthRepository auth = FakeAuthRepository.signedIn()
      ..nextFailure = const AuthFailure(AuthFailureType.requiresRecentLogin);
    await tester.pumpWidget(testApp(const ChangePasswordScreen(), auth: auth));

    await tester.enterText(field(0), 'places2026');
    await tester.enterText(field(1), 'catalog2027');
    await tester.enterText(field(2), 'catalog2027');
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.signInAgainTitle), findsOneWidget);
    expect(find.text(AppStrings.errorRecentLogin), findsOneWidget);
  });

  testWidgets('Change Password: success dialog is shown without a spinner', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1000));
    final FakeAuthRepository auth = FakeAuthRepository.signedIn();
    await tester.pumpWidget(testApp(const ChangePasswordScreen(), auth: auth));

    await tester.enterText(field(0), 'places2026');
    await tester.enterText(field(1), 'catalog2027');
    await tester.enterText(field(2), 'catalog2027');
    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    expect(find.text('Password Updated'), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
  });

  testWidgets('Link Google in Profile marks it as Linked', (
    WidgetTester tester,
  ) async {
    useIPhone(tester, size: const Size(390, 1400));
    final FakeAuthRepository auth = FakeAuthRepository.signedIn();
    await tester.pumpWidget(testApp(const MainShell(), auth: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.link));
    await tester.pumpAndSettle();

    expect(auth.calls, ['linkGoogle']);
    expect(auth.currentUser!.providerIds, contains(AppUser.googleProvider));
    expect(find.text(AppStrings.linked), findsNWidgets(2));
  });
}
