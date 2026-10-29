import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/core/constants/app_strings.dart';
import 'package:places_catalog/core/errors/auth_failure.dart';
import 'package:places_catalog/core/validation/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), AppStrings.validationRequired);
      expect(Validators.email('nazarii'), AppStrings.validationEmail);
      expect(Validators.email('a@b'), AppStrings.validationEmail);
      expect(Validators.email(' nazarii.fito@gmail.com '), isNull);
    });

    test('full name: required, 2–50 characters', () {
      expect(Validators.fullName('  '), AppStrings.validationRequired);
      expect(Validators.fullName('N'), AppStrings.validationNameLength);
      expect(Validators.fullName('N' * 51), AppStrings.validationNameLength);
      expect(Validators.fullName('Nazarii Fito'), isNull);
    });

    test('new password: at least 8 characters with a digit', () {
      expect(Validators.newPassword(''), AppStrings.validationRequired);
      expect(Validators.newPassword('short1'), AppStrings.validationPassword);
      expect(
        Validators.newPassword('longpassword'),
        AppStrings.validationPassword,
      );
      expect(Validators.newPassword('places2026'), isNull);
    });

    test('confirm must match, new must differ from current', () {
      final validateConfirm = Validators.matches(() => 'places2026');
      expect(validateConfirm('places2025'), AppStrings.validationConfirm);
      expect(validateConfirm('places2026'), isNull);

      final validateNew = Validators.newPasswordDifferentFrom(
        () => 'places2026',
      );
      expect(validateNew('places2026'), AppStrings.validationSameAsCurrent);
      expect(validateNew('catalog2027'), isNull);
    });

    test('photo link must be https', () {
      expect(Validators.httpsUrl(''), AppStrings.validationRequired);
      expect(
        Validators.httpsUrl('http://x.com/a.png'),
        AppStrings.validationHttpsUrl,
      );
      expect(Validators.httpsUrl('ftp://x.com'), AppStrings.validationHttpsUrl);
      expect(
        Validators.httpsUrl('https://localhost'),
        AppStrings.validationHttpsUrl,
      );
      expect(Validators.httpsUrl('https://i.pravatar.cc/256?img=3'), isNull);
    });
  });

  group('AuthFailure.fromCode', () {
    test('maps Firebase codes to failure types', () {
      final Map<String, AuthFailureType> cases = {
        'invalid-email': AuthFailureType.invalidEmail,
        'invalid-credential': AuthFailureType.invalidCredentials,
        'wrong-password': AuthFailureType.invalidCredentials,
        'user-not-found': AuthFailureType.invalidCredentials,
        'user-disabled': AuthFailureType.userDisabled,
        'email-already-in-use': AuthFailureType.emailAlreadyInUse,
        'weak-password': AuthFailureType.weakPassword,
        'too-many-requests': AuthFailureType.tooManyRequests,
        'network-request-failed': AuthFailureType.network,
        'requires-recent-login': AuthFailureType.requiresRecentLogin,
        'operation-not-allowed': AuthFailureType.operationNotAllowed,
        'account-exists-with-different-credential':
            AuthFailureType.accountExistsWithDifferentCredential,
        'credential-already-in-use': AuthFailureType.credentialAlreadyInUse,
        'provider-already-linked': AuthFailureType.providerAlreadyLinked,
        'something-new': AuthFailureType.unknown,
      };
      cases.forEach((String code, AuthFailureType type) {
        expect(AuthFailure.fromCode(code).type, type, reason: code);
      });
    });

    test('never shows the raw code to the user', () {
      final AuthFailure failure = AuthFailure.fromCode('internal-error');
      expect(failure.isUnknown, isTrue);
      expect(failure.message, AppStrings.errorUnknown);
      expect(failure.message.contains('internal-error'), isFalse);
    });

    test('keeps the e-mail for account linking', () {
      final AuthFailure failure = AuthFailure.fromCode(
        'account-exists-with-different-credential',
        email: 'me@gmail.com',
      );
      expect(failure.email, 'me@gmail.com');
    });
  });
}
