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
