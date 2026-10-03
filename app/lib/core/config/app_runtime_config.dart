import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/app_constants.dart';

/// Centralized runtime configuration for Flutter app behavior.
///
/// Priority order for each value:
/// 1) `.env.local` / `.env`
/// 2) `--dart-define`
/// 3) safe default
class AppRuntimeConfig {
  AppRuntimeConfig._();

  static String _fromEnv(String key) {
    if (!dotenv.isInitialized) {
      return '';
    }
    return (dotenv.env[key] ?? '').trim();
  }

  static String _pick(List<String> values, String fallback) {
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static int _toInt(String value, int fallback) {
    final parsed = int.tryParse(value.trim());
    return parsed == null || parsed <= 0 ? fallback : parsed;
  }

  static String get appName => _pick(<String>[
    _fromEnv('APP_NAME'),
    const String.fromEnvironment('APP_NAME'),
  ], AppBrand.name);

  static ThemeMode get themeMode {
    final raw = _pick(<String>[
      _fromEnv('APP_THEME_MODE'),
      const String.fromEnvironment('APP_THEME_MODE'),
    ], 'light').toLowerCase();
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static String get apiEnvironment => _pick(<String>[
    _fromEnv('API_ENV'),
    const String.fromEnvironment('API_ENV'),
  ], 'local').toLowerCase();

  static String get apiLocalBaseUrl => _pick(<String>[
    _fromEnv('API_LOCAL_BASE_URL'),
    const String.fromEnvironment('API_LOCAL_BASE_URL'),
  ], 'http://10.0.2.2:18080/v1');

  static String get apiProdBaseUrl => _pick(<String>[
    _fromEnv('API_PROD_BASE_URL'),
    const String.fromEnvironment('API_PROD_BASE_URL'),
  ], 'http://72.61.242.87/v1');

  static String get apiBaseUrl {
    // Browser requests use the website's same-origin API proxy. Never inherit
    // the Android emulator address from the bundled development environment.
    if (kIsWeb) {
      const override = String.fromEnvironment('WEB_API_BASE_URL');
      return override.isNotEmpty ? override : '${Uri.base.origin}/v1';
    }
    final explicitApiBaseUrl = _pick(<String>[
      _fromEnv('API_BASE_URL'),
      const String.fromEnvironment('API_BASE_URL'),
    ], '');

    if (explicitApiBaseUrl.isNotEmpty) {
      return explicitApiBaseUrl;
    }

    switch (apiEnvironment) {
      case 'prod':
      case 'production':
        return apiProdBaseUrl;
      case 'local':
      default:
        return apiLocalBaseUrl;
    }
  }

  static int get apiTimeoutMs {
    final raw = _pick(<String>[
      _fromEnv('API_TIMEOUT_MS'),
      _fromEnv('API_TIMEOUT'),
      const String.fromEnvironment('API_TIMEOUT_MS'),
    ], '30000');
    return _toInt(raw, 30000);
  }

  static String get pushTokenProvider => _pick(<String>[
    _fromEnv('PUSH_TOKEN_PROVIDER'),
    const String.fromEnvironment('PUSH_TOKEN_PROVIDER'),
  ], 'fcm').toLowerCase();

  static String get firebaseApiKey => _pick(<String>[
    _fromEnv('FIREBASE_API_KEY'),
    const String.fromEnvironment('FIREBASE_API_KEY'),
  ], '');

  static String get firebaseAppId => _pick(<String>[
    _fromEnv('FIREBASE_APP_ID'),
    const String.fromEnvironment('FIREBASE_APP_ID'),
  ], '');

  static String get firebaseProjectId => _pick(<String>[
    _fromEnv('FIREBASE_PROJECT_ID'),
    const String.fromEnvironment('FIREBASE_PROJECT_ID'),
  ], '');

  static String get firebaseMessagingSenderId => _pick(<String>[
    _fromEnv('FIREBASE_MESSAGING_SENDER_ID'),
    const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  ], '');

  static String get firebaseIosBundleId => _pick(<String>[
    _fromEnv('FIREBASE_IOS_BUNDLE_ID'),
    const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
  ], 'com.verified_dating.verifiedDatingApp');

  static bool get pushNotificationsConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty;

  static FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
    iosBundleId: firebaseIosBundleId,
  );

  static String get mockUserPrefix => _pick(<String>[
    _fromEnv('MOCK_USER_PREFIX'),
    const String.fromEnvironment('MOCK_USER_PREFIX'),
  ], 'mock-user');

  static String get mockFallbackUserId => _pick(<String>[
    _fromEnv('MOCK_USER_ID'),
    const String.fromEnvironment('MOCK_USER_ID'),
  ], '00000000-0000-4000-8000-000000000001');

  static String get qaForcedUserId => _pick(<String>[
    _fromEnv('QA_FORCED_USER_ID'),
    const String.fromEnvironment('QA_FORCED_USER_ID'),
  ], '');

  static String get placeholderProfileImageUrl => _pick(
    <String>[
      _fromEnv('PLACEHOLDER_PROFILE_IMAGE_URL'),
      const String.fromEnvironment('PLACEHOLDER_PROFILE_IMAGE_URL'),
    ],
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
  );

  static String get placeholderAvatarImageUrl => _pick(
    <String>[
      _fromEnv('PLACEHOLDER_AVATAR_IMAGE_URL'),
      const String.fromEnvironment('PLACEHOLDER_AVATAR_IMAGE_URL'),
    ],
    'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=500&q=80',
  );

  static String get matchedProfileIdsCsv => _pick(<String>[
    _fromEnv('MOCK_MATCHED_PROFILE_IDS'),
    const String.fromEnvironment('MOCK_MATCHED_PROFILE_IDS'),
  ], '');

  static Set<String> get matchedProfileIds => matchedProfileIdsCsv
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();

  static int get mockFemaleUsersCount {
    final raw = _pick(<String>[
      _fromEnv('MOCK_FEMALE_USERS_COUNT'),
      const String.fromEnvironment('MOCK_FEMALE_USERS_COUNT'),
    ], '100');
    return _toInt(raw, 100);
  }

  static int get mockMaleUsersCount {
    final raw = _pick(<String>[
      _fromEnv('MOCK_MALE_USERS_COUNT'),
      const String.fromEnvironment('MOCK_MALE_USERS_COUNT'),
    ], '100');
    return _toInt(raw, 100);
  }

  static int get mockMinAgeYears {
    final raw = _pick(<String>[
      _fromEnv('MOCK_MIN_AGE_YEARS'),
      const String.fromEnvironment('MOCK_MIN_AGE_YEARS'),
    ], '18');
    return _toInt(raw, 18);
  }

  static int get mockMaxAgeYears {
    final raw = _pick(<String>[
      _fromEnv('MOCK_MAX_AGE_YEARS'),
      const String.fromEnvironment('MOCK_MAX_AGE_YEARS'),
    ], '45');
    return _toInt(raw, 45);
  }

  static String mockUserIdForIdentifier(String? identifier) {
    final raw = (identifier ?? '').trim().toLowerCase();
    if (raw.isEmpty) {
      return mockFallbackUserId;
    }
    final alnum = raw.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (alnum.isEmpty) {
      return mockFallbackUserId;
    }
    return _stableUuidFromSeed(alnum);
  }

  static String _stableUuidFromSeed(String seed) {
    final first = _fnv1a64(seed);
    final second = _fnv1a64('$seed#v2');

    final bytes = <int>[];
    for (var shift = 56; shift >= 0; shift -= 8) {
      bytes.add(((first >> shift) & BigInt.from(255)).toInt());
    }
    for (var shift = 56; shift >= 0; shift -= 8) {
      bytes.add(((second >> shift) & BigInt.from(255)).toInt());
    }

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final b = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${b.substring(0, 8)}-${b.substring(8, 12)}-'
        '${b.substring(12, 16)}-${b.substring(16, 20)}-'
        '${b.substring(20, 32)}';
  }

  static BigInt _fnv1a64(String input) {
    final fnvOffsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
    final fnvPrime = BigInt.parse('100000001b3', radix: 16);
    final mask64 = BigInt.parse('ffffffffffffffff', radix: 16);

    var hash = fnvOffsetBasis;
    for (final codeUnit in input.codeUnits) {
      hash ^= BigInt.from(codeUnit);
      hash = (hash * fnvPrime) & mask64;
    }
    return hash;
  }
}
