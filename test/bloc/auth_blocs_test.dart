import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/errors/auth_failure.dart';
import 'package:places_catalog/data/models/app_user.dart';
import 'package:places_catalog/data/models/place_photo.dart';
import 'package:places_catalog/data/repositories/fake_auth_repository.dart';
import 'package:places_catalog/data/repositories/fake_media_repository.dart';
import 'package:places_catalog/data/repositories/user_profile_repository.dart';
import 'package:places_catalog/data/services/analytics_service.dart';
import 'package:places_catalog/features/auth/bloc/forgot_password_cubit.dart';
import 'package:places_catalog/features/auth/bloc/login_bloc.dart';
import 'package:places_catalog/features/auth/bloc/register_bloc.dart';
import 'package:places_catalog/features/profile/bloc/change_password_cubit.dart';
import 'package:places_catalog/features/profile/bloc/profile_bloc.dart';
import 'package:places_catalog/features/session/bloc/auth_bloc.dart';

const NoopAnalyticsService _analytics = NoopAnalyticsService();

void main() {
  group('LoginBloc', () {
    late FakeAuthRepository auth;
    setUp(() => auth = FakeAuthRepository());
    LoginBloc make() => LoginBloc(auth: auth, analytics: _analytics);

    blocTest<LoginBloc, LoginState>(
      'success: loading → success, one signIn call',
      build: make,
      act: (LoginBloc b) =>
          b.add(const LoginSubmitted(email: 'a@b.co', password: 'secret123')),
      expect: () => [const LoginLoading(), const LoginSuccess()],
      verify: (_) => expect(auth.calls, ['signIn']),
    );

    blocTest<LoginBloc, LoginState>(
      'wrong credentials: loading → failure with the human message',
      build: make,
      setUp: () => auth.nextFailure = const AuthFailure(
        AuthFailureType.invalidCredentials,
      ),
      act: (LoginBloc b) =>
          b.add(const LoginSubmitted(email: 'a@b.co', password: 'bad')),
      expect: () => [
        const LoginLoading(),
        LoginFailure(
          const AuthFailure(AuthFailureType.invalidCredentials).message,
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'a second submit while loading is ignored',
      build: make,
      setUp: () => auth.gate = Completer<void>(),
      act: (LoginBloc b) async {
        b.add(const LoginSubmitted(email: 'a@b.co', password: 'x1234567'));
        b.add(const LoginSubmitted(email: 'a@b.co', password: 'x1234567'));
        await Future<void>.delayed(Duration.zero);
        auth.gate!.complete();
      },
      expect: () => [const LoginLoading(), const LoginSuccess()],
      verify: (_) => expect(auth.calls, ['signIn']),
    );

    blocTest<LoginBloc, LoginState>(
      'Google on an e-mail with a password account asks to link, then links',
      build: make,
      setUp: () => auth.nextFailure = const AuthFailure(
        AuthFailureType.accountExistsWithDifferentCredential,
        email: 'a@b.co',
      ),
      act: (LoginBloc b) async {
        b.add(const LoginGoogleRequested());
        await b.stream.firstWhere((LoginState s) => s is LoginLinkRequired);
        b.add(
          const LoginGoogleLinkConfirmed(email: 'a@b.co', password: 'pw123456'),
        );
      },
      expect: () => [
        const LoginLoading(),
        const LoginLinkRequired('a@b.co'),
        const LoginLoading(),
        const LoginSuccess(),
      ],
      verify: (_) =>
          expect(auth.calls, ['signInWithGoogle', 'completeGoogleLink']),
    );

    blocTest<LoginBloc, LoginState>(
      'Apple goes through the repository',
      build: make,
      act: (LoginBloc b) => b.add(const LoginAppleRequested()),
      expect: () => [const LoginLoading(), const LoginSuccess()],
      verify: (_) => expect(auth.calls, ['signInWithApple']),
    );
  });

  group('RegisterBloc', () {
    late FakeAuthRepository auth;
    setUp(() => auth = FakeAuthRepository());
    RegisterBloc make() => RegisterBloc(auth: auth, analytics: _analytics);
    const RegisterSubmitted event = RegisterSubmitted(
      fullName: 'Ann Lee',
      email: 'ann@x.co',
      password: 'secret123',
    );

    blocTest<RegisterBloc, RegisterState>(
      'success',
      build: make,
      act: (RegisterBloc b) => b.add(event),
      expect: () => [const RegisterLoading(), const RegisterSuccess()],
      verify: (_) => expect(auth.calls, ['signUp']),
    );

    blocTest<RegisterBloc, RegisterState>(
      'e-mail already in use → failure',
      build: make,
      setUp: () => auth.nextFailure = const AuthFailure(
        AuthFailureType.emailAlreadyInUse,
      ),
      act: (RegisterBloc b) => b.add(event),
      expect: () => [
        const RegisterLoading(),
        RegisterFailure(
          const AuthFailure(AuthFailureType.emailAlreadyInUse).message,
        ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'a second submit while loading is ignored',
      build: make,
      setUp: () => auth.gate = Completer<void>(),
      act: (RegisterBloc b) async {
        b.add(event);
        b.add(event);
        await Future<void>.delayed(Duration.zero);
        auth.gate!.complete();
      },
      verify: (_) => expect(auth.calls, ['signUp']),
    );
  });

  group('ProfileBloc', () {
    late FakeAuthRepository auth;
    late FakeMediaRepository media;
    setUp(() {
      auth = FakeAuthRepository.signedIn();
      media = FakeMediaRepository();
    });
    ProfileBloc make() => ProfileBloc(
      auth: auth,
      analytics: _analytics,
      profiles: const NoopUserProfileRepository(),
      media: media,
    );

    test('starts with the current user already available', () {
      final ProfileBloc bloc = make();
      expect(bloc.state.user?.uid, 'demo-uid');
      expect(bloc.state.status, ProfileStatus.idle);
      bloc.close();
    });

    blocTest<ProfileBloc, ProfileState>(
      'save: saving → idle, and the new name arrives through the stream',
      build: make,
      act: (ProfileBloc b) async {
        b.add(const ProfileStarted());
        b.add(const ProfileUpdated(displayName: 'New Name'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (ProfileBloc b) {
        expect(b.state.status, ProfileStatus.idle);
        expect(b.state.user?.displayName, 'New Name');
        expect(auth.calls, contains('updateProfile'));
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'a failed save → saveFailure with a message',
      build: make,
      setUp: () =>
          auth.nextFailure = const AuthFailure(AuthFailureType.network),
      act: (ProfileBloc b) =>
          b.add(const ProfileUpdated(displayName: 'New Name')),
      verify: (ProfileBloc b) {
        expect(b.state.status, ProfileStatus.saveFailure);
        expect(b.state.message, isNotNull);
      },
    );

    const PlacePhoto picked = PlacePhoto.local(
      '/tmp/me.jpg',
      fileSizeBytes: 100,
      contentType: 'image/jpeg',
    );

    blocTest<ProfileBloc, ProfileState>(
      'a picture from the device is uploaded and becomes the photo URL',
      build: make,
      act: (ProfileBloc b) async {
        b.add(const ProfileStarted());
        b.add(
          const ProfileUpdated(
            displayName: 'Me',
            newAvatar: picked,
            photoSource: 'upload',
          ),
        );
      },
      wait: const Duration(milliseconds: 30),
      verify: (ProfileBloc b) {
        expect(media.uploaded.single, startsWith('users/demo-uid/avatar/'));
        expect(b.state.status, ProfileStatus.idle);
        expect(b.state.user?.photoUrl, contains('users/demo-uid/avatar/'));
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'replacing an uploaded picture deletes the old file (ours only)',
      build: make,
      setUp: () {
        auth = FakeAuthRepository(
          signedInAs: const AppUser(
            uid: 'demo-uid',
            email: 'a@b.co',
            photoUrl: 'https://fake.invalid/place-photos/users/demo-uid/avatar/old.jpg',
            providerIds: {AppUser.passwordProvider},
          ),
        );
      },
      act: (ProfileBloc b) =>
          b.add(const ProfileUpdated(newAvatar: picked, photoSource: 'upload')),
      verify: (ProfileBloc b) {
        expect(media.deleted, ['users/demo-uid/avatar/old.jpg']);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'switching to a preset avatar deletes an old uploaded one; a preset is never deleted',
      build: make,
      setUp: () {
        auth = FakeAuthRepository(
          signedInAs: const AppUser(
            uid: 'demo-uid',
            email: 'a@b.co',
            photoUrl: 'https://fake.invalid/place-photos/users/demo-uid/avatar/old.jpg',
            providerIds: {AppUser.passwordProvider},
          ),
        );
      },
      act: (ProfileBloc b) async {
        b.add(
          const ProfileUpdated(
            photoUrl: 'https://api.dicebear.com/9.x/notionists/png?seed=a',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        b.add(
          const ProfileUpdated(
            photoUrl: 'https://api.dicebear.com/9.x/notionists/png?seed=b',
          ),
        );
      },
      wait: const Duration(milliseconds: 40),
      verify: (_) =>
          // Only the first switch removed a file of ours.
          expect(media.deleted, ['users/demo-uid/avatar/old.jpg']),
    );

    blocTest<ProfileBloc, ProfileState>(
      'an upload failure is a save failure and the account is untouched',
      build: make,
      setUp: () => media.failOnUpload = 1,
      act: (ProfileBloc b) => b.add(
        const ProfileUpdated(displayName: 'Changed', newAvatar: picked),
      ),
      verify: (ProfileBloc b) {
        expect(b.state.status, ProfileStatus.saveFailure);
        expect(b.state.message, isNotNull);
        expect(auth.calls, isNot(contains('updateProfile')));
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'if the account update fails, the just-uploaded file is removed',
      build: make,
      setUp: () =>
          auth.nextFailure = const AuthFailure(AuthFailureType.network),
      act: (ProfileBloc b) => b.add(const ProfileUpdated(newAvatar: picked)),
      verify: (ProfileBloc b) {
        expect(b.state.status, ProfileStatus.saveFailure);
        expect(media.deleted, media.uploaded);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'without storage keys, uploading explains and saves nothing',
      build: () => ProfileBloc(
        auth: auth,
        analytics: _analytics,
        profiles: const NoopUserProfileRepository(),
        media: FakeMediaRepository(configured: false),
      ),
      act: (ProfileBloc b) => b.add(const ProfileUpdated(newAvatar: picked)),
      verify: (ProfileBloc b) {
        expect(b.state.status, ProfileStatus.saveFailure);
        expect(b.state.message, contains('not configured'));
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'ErrorDismissed clears the failure',
      build: make,
      seed: () =>
          const ProfileState(status: ProfileStatus.saveFailure, message: 'x'),
      act: (ProfileBloc b) => b.add(const ProfileErrorDismissed()),
      verify: (ProfileBloc b) {
        expect(b.state.status, ProfileStatus.idle);
        expect(b.state.message, isNull);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'link Google: linking → idle, Google is now linked',
      build: make,
      act: (ProfileBloc b) {
        b.add(const ProfileStarted());
        b.add(const ProfileGoogleLinkRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (ProfileBloc b) {
        expect(b.state.status, ProfileStatus.idle);
        expect(b.state.user?.hasGoogle, isTrue);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'a failed link is reported as linkFailure, not saveFailure',
      build: make,
      setUp: () => auth.nextFailure = const AuthFailure(
        AuthFailureType.credentialAlreadyInUse,
      ),
      act: (ProfileBloc b) => b.add(const ProfileGoogleLinkRequested()),
      verify: (ProfileBloc b) =>
          expect(b.state.status, ProfileStatus.linkFailure),
    );
  });

  group('ChangePasswordCubit', () {
    late FakeAuthRepository auth;
    setUp(() => auth = FakeAuthRepository.signedIn());
    ChangePasswordCubit make() =>
        ChangePasswordCubit(auth: auth, analytics: _analytics);

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'success',
      build: make,
      act: (ChangePasswordCubit c) =>
          c.submit(currentPassword: 'old12345', newPassword: 'new12345'),
      expect: () => [
        const ChangePasswordState(status: ChangePasswordStatus.submitting),
        const ChangePasswordState(status: ChangePasswordStatus.success),
      ],
    );

    for (final AuthFailureType type in [
      AuthFailureType.invalidCredentials,
      AuthFailureType.requiresRecentLogin,
    ]) {
      blocTest<ChangePasswordCubit, ChangePasswordState>(
        'failure keeps its type: $type',
        build: make,
        setUp: () => auth.nextFailure = AuthFailure(type),
        act: (ChangePasswordCubit c) =>
            c.submit(currentPassword: 'old12345', newPassword: 'new12345'),
        verify: (ChangePasswordCubit c) {
          expect(c.state.status, ChangePasswordStatus.failure);
          expect(c.state.failureType, type);
        },
      );
    }

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'clearError resets a failure',
      build: make,
      seed: () => const ChangePasswordState(
        status: ChangePasswordStatus.failure,
        failureType: AuthFailureType.invalidCredentials,
        message: 'x',
      ),
      act: (ChangePasswordCubit c) => c.clearError(),
      expect: () => [const ChangePasswordState()],
    );
  });

  group('ForgotPasswordCubit', () {
    late FakeAuthRepository auth;
    setUp(() => auth = FakeAuthRepository());
    ForgotPasswordCubit make() =>
        ForgotPasswordCubit(auth: auth, analytics: _analytics);

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'sent, then reset back to the form',
      build: make,
      act: (ForgotPasswordCubit c) async {
        await c.sendLink('a@b.co');
        c.reset();
      },
      expect: () => [
        const ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        const ForgotPasswordState(status: ForgotPasswordStatus.sent),
        const ForgotPasswordState(),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'failure carries the message',
      build: make,
      setUp: () =>
          auth.nextFailure = const AuthFailure(AuthFailureType.network),
      act: (ForgotPasswordCubit c) => c.sendLink('a@b.co'),
      verify: (ForgotPasswordCubit c) {
        expect(c.state.status, ForgotPasswordStatus.failure);
        expect(c.state.message, isNotNull);
      },
    );
  });

  group('AuthBloc', () {
    test('a restored session starts as Authenticated', () {
      final AuthBloc bloc = AuthBloc(FakeAuthRepository.signedIn());
      expect(bloc.state, isA<Authenticated>());
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'no session: splash, then Unauthenticated',
      build: () => AuthBloc(FakeAuthRepository()),
      act: (AuthBloc b) => b.add(const AuthStarted()),
      expect: () => [isA<Unauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'logout leads to Unauthenticated',
      build: () => AuthBloc(FakeAuthRepository.signedIn()),
      act: (AuthBloc b) {
        b.add(const AuthStarted());
        b.add(const AuthLogoutRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (AuthBloc b) => expect(b.state, isA<Unauthenticated>()),
    );

    blocTest<AuthBloc, AuthState>(
      'a failed logout stays signed in and reports the error',
      build: () {
        final FakeAuthRepository auth = FakeAuthRepository.signedIn();
        auth.nextFailure = const AuthFailure(AuthFailureType.network);
        return AuthBloc(auth);
      },
      act: (AuthBloc b) => b.add(const AuthLogoutRequested()),
      verify: (AuthBloc b) {
        expect(b.state, isA<Authenticated>());
        expect((b.state as Authenticated).logoutError, isNotNull);
      },
    );
  });
}
