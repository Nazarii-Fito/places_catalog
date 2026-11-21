import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The URL and public key of the developer's own Supabase project.
/// Nothing is hardcoded in the repository (see `env/supabase.example.json`).
@immutable
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;

  /// The project's public key ("publishable" key, or the legacy "anon"
  /// key). It is public by design — access is limited by bucket policies —
  /// but it is still kept out of git.
  final String anonKey;

  /// The bucket that holds place photos.
  static const String bucket = 'place-photos';

  /// Asset the local key file is bundled as (`env/` is declared in
  /// `pubspec.yaml`; `env/supabase.json` itself is git-ignored).
  static const String assetPath = 'env/supabase.json';

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Where the settings come from, in this order:
  /// 1. `--dart-define` / `--dart-define-from-file` at build time;
  /// 2. the git-ignored `env/supabase.json`, bundled into local builds.
  ///
  /// The second source means *any* local build — run from the IDE, from
  /// Xcode, or installed from the home-screen icon — has working cloud
  /// storage, not only the ones started with the right command-line flag.
  static Future<SupabaseConfig> load({
    AssetBundle? bundle,
    String defineUrl = const String.fromEnvironment('SUPABASE_URL'),
    String defineKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
  }) async {
    if (defineUrl.isNotEmpty && defineKey.isNotEmpty) {
      return SupabaseConfig(url: defineUrl, anonKey: defineKey);
    }
    try {
      final String text = await (bundle ?? rootBundle).loadString(assetPath);
      return fromJson(text);
    } catch (_) {
      // No file in this build: storage stays "not configured".
      return const SupabaseConfig(url: '', anonKey: '');
    }
  }

  /// Reads `{"SUPABASE_URL": "...", "SUPABASE_ANON_KEY": "..."}`. Placeholder
  /// values from the example file count as "not configured".
  static SupabaseConfig fromJson(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      return const SupabaseConfig(url: '', anonKey: '');
    }
    final String url = (decoded['SUPABASE_URL'] as String? ?? '').trim();
    final String key = (decoded['SUPABASE_ANON_KEY'] as String? ?? '').trim();
    final bool placeholder = url.contains('YOUR-') || key.contains('YOUR-');
    return placeholder
        ? const SupabaseConfig(url: '', anonKey: '')
        : SupabaseConfig(url: url, anonKey: key);
  }
}
