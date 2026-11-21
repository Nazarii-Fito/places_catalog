import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:places_catalog/data/services/supabase_config.dart';

/// An asset bundle holding only the given files.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final String? text = files[key];
    if (text == null) throw FlutterError('Unable to load asset: $key');
    final Uint8List bytes = Uint8List.fromList(utf8.encode(text));
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  const String file =
      '{"SUPABASE_URL": "https://abc.supabase.co", "SUPABASE_ANON_KEY": "sb_publishable_x"}';

  test('keys from the bundled env file are used when no dart-define', () async {
    final SupabaseConfig c = await SupabaseConfig.load(
      bundle: _Bundle({SupabaseConfig.assetPath: file}),
      defineUrl: '',
      defineKey: '',
    );
    expect(c.isConfigured, isTrue);
    expect(c.url, 'https://abc.supabase.co');
    expect(c.anonKey, 'sb_publishable_x');
  });

  test('dart-define wins over the file', () async {
    final SupabaseConfig c = await SupabaseConfig.load(
      bundle: _Bundle({SupabaseConfig.assetPath: file}),
      defineUrl: 'https://define.supabase.co',
      defineKey: 'key-from-define',
    );
    expect(c.url, 'https://define.supabase.co');
    expect(c.anonKey, 'key-from-define');
  });

  test('no file and no define: not configured, no crash', () async {
    final SupabaseConfig c = await SupabaseConfig.load(
      bundle: _Bundle({}),
      defineUrl: '',
      defineKey: '',
    );
    expect(c.isConfigured, isFalse);
  });

  test('the example file with placeholders counts as not configured', () {
    final SupabaseConfig c = SupabaseConfig.fromJson(
      '{"SUPABASE_URL": "https://YOUR-PROJECT-REF.supabase.co", '
      '"SUPABASE_ANON_KEY": "YOUR-PUBLISHABLE-OR-ANON-KEY"}',
    );
    expect(c.isConfigured, isFalse);
  });

  test('broken or incomplete JSON never throws out of load()', () async {
    for (final String bad in ['not json', '[]', '{"SUPABASE_URL": "x"}']) {
      final SupabaseConfig c = await SupabaseConfig.load(
        bundle: _Bundle({SupabaseConfig.assetPath: bad}),
        defineUrl: '',
        defineKey: '',
      );
      expect(c.isConfigured, isFalse, reason: bad);
    }
  });
}
