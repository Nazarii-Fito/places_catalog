/// The signed-in user as the app sees it — built from Firebase `User`, but
/// free of any Firebase types so `features/` never depends on the SDK.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.providerIds = const {},
  });

  /// Provider ids used by Firebase (`providerData[].providerId`).
  static const String passwordProvider = 'password';
  static const String googleProvider = 'google.com';
  static const String appleProvider = 'apple.com';

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// Sign-in methods linked to this one account, e.g. {password, google.com}.
  final Set<String> providerIds;

  bool get hasPassword => providerIds.contains(passwordProvider);
  bool get hasGoogle => providerIds.contains(googleProvider);

  /// Name to show: display name, else the part of the e-mail before "@".
  String get name {
    final String? display = displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    return email?.split('@').first ?? '';
  }

  /// Avatar placeholder initials, e.g. "NF".
  String get initials => name
      .split(' ')
      .where((String part) => part.isNotEmpty)
      .take(2)
      .map((String part) => part[0].toUpperCase())
      .join();
}
