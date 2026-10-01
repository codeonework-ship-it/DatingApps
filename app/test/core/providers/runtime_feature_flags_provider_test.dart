import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';

void main() {
  group('RuntimeFeatureFlags', () {
    test('maps database flags while retaining safe defaults', () {
      final flags = RuntimeFeatureFlags.fromApi(<String, dynamic>{
        'source': 'db',
        'flags': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'gifts_enabled', 'value_bool': false},
          <String, dynamic>{'key': 'calls_enabled', 'value_bool': false},
        ],
      });

      expect(flags.enabled('gifts_enabled'), isFalse);
      expect(flags.enabled('calls_enabled'), isFalse);
      expect(flags.enabled('rooms_enabled'), isTrue);
    });

    test('ignores malformed rows and supports explicit fallback', () {
      final flags = RuntimeFeatureFlags.fromApi(<String, dynamic>{
        'flags': <dynamic>[
          'not-a-row',
          <String, dynamic>{'key': 'gifts_enabled', 'value_bool': 'false'},
        ],
      });

      expect(flags.enabled('gifts_enabled'), isTrue);
      expect(flags.enabled('unknown'), isFalse);
      expect(flags.enabled('unknown', fallback: true), isTrue);
    });
  });
}
