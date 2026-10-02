import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/profile/providers/user_settings_provider.dart';
import '../utils/logger.dart';

/// One language the product ships in.
///
/// [tag] is the wire value stored in `settings.locale` on the server and in
/// the local cache: a BCP 47 tag limited to `language[-REGION]`, matching the
/// `user_settings_locale_check` column constraint (093_member_locale.sql).
/// [nativeName] is the language's own name; it is deliberately not
/// translated, so a member who cannot read the current language can still
/// find their own.
class AppLanguage {
  const AppLanguage({
    required this.tag,
    required this.locale,
    required this.nativeName,
  });

  final String tag;
  final Locale locale;
  final String nativeName;
}

/// The ten shipped languages, in picker order. en-US is the product default
/// and the ARB template (`app_en.arb`).
const List<AppLanguage> appLanguages = <AppLanguage>[
  AppLanguage(
    tag: 'en-US',
    locale: Locale('en', 'US'),
    nativeName: 'English (US)',
  ),
  AppLanguage(
    tag: 'en-GB',
    locale: Locale('en', 'GB'),
    nativeName: 'English (UK)',
  ),
  AppLanguage(tag: 'de', locale: Locale('de'), nativeName: 'Deutsch'),
  AppLanguage(tag: 'fr', locale: Locale('fr'), nativeName: 'Français'),
  AppLanguage(tag: 'ru', locale: Locale('ru'), nativeName: 'Русский'),
  AppLanguage(tag: 'es', locale: Locale('es'), nativeName: 'Español'),
  AppLanguage(tag: 'it', locale: Locale('it'), nativeName: 'Italiano'),
  AppLanguage(tag: 'pt', locale: Locale('pt'), nativeName: 'Português'),
  AppLanguage(tag: 'nl', locale: Locale('nl'), nativeName: 'Nederlands'),
  AppLanguage(tag: 'pl', locale: Locale('pl'), nativeName: 'Polski'),
];

final RegExp _localeTagPattern = RegExp(r'^[a-z]{2}(-[A-Z]{2})?$');

/// Parses a stored tag back into a [Locale]; null for empty or unsupported.
Locale? appLocaleFromTag(String? tag) {
  final trimmed = tag?.trim() ?? '';
  if (trimmed.isEmpty || !_localeTagPattern.hasMatch(trimmed)) {
    return null;
  }
  for (final language in appLanguages) {
    if (language.tag == trimmed) {
      return language.locale;
    }
  }
  return null;
}

/// The wire tag for a [Locale]; empty for null (follow the device).
String appLocaleToTag(Locale? locale) {
  if (locale == null) {
    return '';
  }
  for (final language in appLanguages) {
    if (language.locale == locale) {
      return language.tag;
    }
  }
  final country = locale.countryCode;
  return country == null || country.isEmpty
      ? locale.languageCode
      : '${locale.languageCode}-$country';
}

const _cacheKey = 'connect.locale';

/// Reads the locally cached choice. Called once before `runApp` so the very
/// first frame is already in the member's language, before any sign-in.
Future<Locale?> readCachedAppLocale() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return appLocaleFromTag(prefs.getString(_cacheKey));
  } on Object {
    // No cache (first launch, or the plugin is unavailable in a test): the
    // device language applies until the member picks one.
    return null;
  }
}

/// The member's chosen UI language. `null` means "follow the device".
///
/// Two stores, one source of truth:
///  * `settings.locale` on the server is the account's choice and follows the
///    member onto other devices, exactly like `settings.theme`;
///  * a SharedPreferences cache applies that choice before sign-in and offline.
///
/// Selecting a language repaints immediately, writes the cache, and patches
/// the account through [userSettingsProvider] when a session exists.
class AppLocaleNotifier extends StateNotifier<Locale?> {
  AppLocaleNotifier(this._ref, {Locale? initial}) : super(initial);

  final Ref _ref;
  final _log = AppLogger();

  /// The member whose stored language was last adopted. Per member, not a
  /// flag: signing in as someone else on this device loads their language
  /// instead of keeping the previous member's.
  String? _loadedFor;

  String? get _userId {
    final id = _ref.read(authNotifierProvider).userId?.trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  /// Adopt the account's stored language once per signed-in member.
  ///
  /// Not called from the constructor: `MaterialApp` watches this provider on
  /// the first frame, before there is a session to load for, so a constructor
  /// fetch would fire an unauthenticated request. The gate calls this once it
  /// knows the member is signed in. A non-empty server value wins over the
  /// local cache; an empty one leaves the cached choice alone so a member who
  /// picked a language before signing in keeps it.
  Future<void> ensureLoaded() async {
    final userId = _userId;
    if (userId == null || userId == _loadedFor) {
      return;
    }
    _loadedFor = userId;
    try {
      final settings = await _ref.read(userSettingsProvider.future);
      // Someone else signed in while this member's settings were loading.
      if (_userId != userId) {
        return;
      }
      final stored = appLocaleFromTag(settings.locale);
      if (stored != null && stored != state) {
        state = stored;
        await _cache(stored);
      }
    } on Object catch (e, stackTrace) {
      // A language is never worth blocking startup for.
      _log.error('Failed to load locale preference', e, stackTrace);
    }
  }

  /// Choose a language, or `null` to follow the device.
  Future<void> select(Locale? locale) async {
    final previous = state;
    state = locale;
    await _cache(locale);

    if (_userId == null) {
      return;
    }
    final notifier = _ref.read(userSettingsProvider.notifier);
    Object? error;
    StackTrace? stackTrace;
    try {
      await notifier.patchSettings(locale: appLocaleToTag(locale));
      final result = _ref.read(userSettingsProvider);
      if (result.hasError) {
        error = result.error;
        stackTrace = result.stackTrace;
      }
    } on Object catch (e, s) {
      // The account could not even be read (offline).
      error = e;
      stackTrace = s;
    }
    if (error != null) {
      // Roll back rather than show a language the account does not have: it
      // would silently revert on the next device.
      state = previous;
      await _cache(previous);
      // A failed save leaves the settings in error; read them again on the
      // next pick instead of failing it without reaching the server.
      _ref.invalidate(userSettingsProvider);
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
    }
  }

  Future<void> _cache(Locale? locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tag = appLocaleToTag(locale);
      if (tag.isEmpty) {
        await prefs.remove(_cacheKey);
      } else {
        await prefs.setString(_cacheKey, tag);
      }
    } on Object catch (e, stackTrace) {
      _log.error('Failed to cache locale preference', e, stackTrace);
    }
  }
}

/// `main()` overrides this with the cached choice read before `runApp`, so
/// the default here only matters for tests and previews.
final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale?>(
  AppLocaleNotifier.new,
);
