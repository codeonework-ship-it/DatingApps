import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/telemetry/client_error_reporter.dart';
import 'package:verified_dating_app/core/telemetry/pii_scrubber.dart';
import 'package:verified_dating_app/core/telemetry/sha256.dart';

void main() {
  group('PiiScrubber.scrub', () {
    test('replaces emails', () {
      final out = PiiScrubber.scrub('login failed for jane.doe+qa@example.co');
      expect(out, 'login failed for <email>');
    });

    test('replaces phone numbers with separators and country codes', () {
      expect(PiiScrubber.scrub('call +91 98765 43210 now'), 'call <phone> now');
      expect(PiiScrubber.scrub('us (415) 555-0100'), 'us (<phone>');
      expect(
        PiiScrubber.scrub('otp sent to 9876543210'),
        'otp sent to <phone>',
      );
      // Short numbers and dates are not phone numbers.
      expect(PiiScrubber.scrub('retry 3 of 12345'), 'retry 3 of 12345');
      expect(PiiScrubber.scrub('on 2026-10-01'), 'on 2026-10-01');
    });

    test('replaces bearer tokens, JWTs and long opaque tokens', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.'
          'dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
      expect(
        PiiScrubber.scrub('Authorization: Bearer abc.def-123_456'),
        'Authorization: Bearer <token>',
      );
      expect(PiiScrubber.scrub('token=$jwt'), isNot(contains('eyJ')));
      expect(
        PiiScrubber.scrub('key 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b'),
        'key <token>',
      );
      expect(
        PiiScrubber.scrub('refresh dGhpc2lzYXZlcnlsb25nc2VjcmV0MTIzNDU2'),
        'refresh <token>',
      );
    });

    test('replaces uuids, IPv4 addresses and card-like numbers', () {
      expect(
        PiiScrubber.scrub('user 123e4567-e89b-12d3-a456-426614174000 missing'),
        'user <id> missing',
      );
      expect(PiiScrubber.scrub('from 72.61.242.87'), 'from <ip>');
      expect(PiiScrubber.scrub('card 4111 1111 1111 1111'), 'card <number>');
    });

    test('URLs lose query, fragment and id-like path segments', () {
      final out = PiiScrubber.scrub(
        'GET https://api.example.com/v1/profile/42/photos'
        '?email=jane@example.com&token=abc#frag failed',
      );
      expect(out, 'GET https://api.example.com/v1/profile/<id>/photos failed');
      expect(
        PiiScrubber.scrub('path /v1/search?q=jane&city=Pune failed'),
        'path /v1/search failed',
      );
    });

    test('keeps stack frames readable', () {
      const frame =
          '#3      _PrivacySafetyScreenState.build '
          '(package:verified_dating_app/features/common/screens/'
          'privacy_safety_screen.dart:120:7)';
      expect(PiiScrubber.scrub(frame), frame);
    });

    test('masks home directories in file paths', () {
      expect(
        PiiScrubber.scrub('file:///Users/jane/project/lib/main.dart:1:2'),
        'file:///Users/<user>/project/lib/main.dart:1:2',
      );
    });
  });

  test('message and stack are truncated', () {
    expect(PiiScrubber.message('x' * 5000).length, 1000);
    final stack = List<String>.generate(80, (i) => '#$i frame').join('\n');
    expect(PiiScrubber.stack(stack).split('\n'), hasLength(50));
    expect(PiiScrubber.stack('y' * 20000).length, 8000);
  });

  test('route templates drop query strings and ids', () {
    expect(
      PiiScrubber.routeTemplate('/chat/9b2f6c1e0a7d4e3b8c5d?draft=hi'),
      '/chat/<id>',
    );
    expect(PiiScrubber.routeTemplate('/u/@jane'), '/u/<id>');
    expect(PiiScrubber.routeTemplate('/settings/privacy'), '/settings/privacy');
  });

  test('sha256 matches published test vectors', () {
    expect(
      sha256Hex(''),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
    expect(
      sha256Hex('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    expect(
      sha256Hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
      '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
    );
  });

  test('fingerprint ignores digits and line numbers', () {
    final a = computeFingerprint(
      'StateError',
      'Bad state: item 3 missing',
      '#0 Foo.bar (package:app/foo.dart:10:5)\n#1 main (package:app/m.dart:2:1)',
    );
    final b = computeFingerprint(
      'StateError',
      'Bad state: item 7 missing',
      '#0 Foo.bar (package:app/foo.dart:99:1)\n#1 main (package:app/m.dart:8:3)',
    );
    final c = computeFingerprint('RangeError', 'Bad state: item 3 missing', '');
    expect(a, b);
    expect(a, hasLength(64));
    expect(a, isNot(c));
  });
}
