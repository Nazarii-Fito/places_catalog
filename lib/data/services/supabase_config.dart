/// Cloud-storage settings, supplied at build time with `--dart-define`
/// (see `env/supabase.example.json`). Nothing is hardcoded in the repository:
/// the project URL and key come from the developer's own Supabase project.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');

  /// The project's public key ("publishable" key, or the legacy "anon"
  /// key). It is public by design — access is limited by bucket policies —
  /// but it is still kept out of git.
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// The bucket that holds place photos.
  static const String bucket = 'place-photos';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
