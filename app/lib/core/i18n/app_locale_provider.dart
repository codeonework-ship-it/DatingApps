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

/// `MaterialApp.localeListResolutionCallback`: the first preferred language
/// the app ships (exact, then by language; any English other than en-GB is
/// the `en` template), else English.
///
/// Flutter's default falls back to the first supported locale, which is
/// German in the generated list, so an unsupported device language (say
/// Japanese) would open the app in German.
Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final wanted in preferred ?? const <Locale>[]) {
    for (final candidate in supported) {
      if (candidate.languageCode == wanted.languageCode &&
          (candidate.countryCode ?? '') == (wanted.countryCode ?? '')) {
        return candidate;
      }
    }
    final english = wanted.languageCode == 'en';
    for (final candidate in supported) {
      if (candidate.languageCode == wanted.languageCode &&
          (!english || (candidate.countryCode ?? '').isEmpty)) {
        return candidate;
      }
    }
  }
  return supported.firstWhere(
    (l) => l.languageCode == 'en' && (l.countryCode ?? '').isEmpty,
    orElse: () => const Locale('en'),
  );
}

const _cacheKey = 'connect.locale';

/// Set when the language was chosen on a signed-out screen (welcome, sign-in,
/// sign-up). The next member to sign in on this device gets that choice saved
/// to their account instead of having it replaced by the stored one.
const _pickedBeforeSignInKey = 'connect.locale.picked_before_sign_in';

/// Parses a loosely written tag (`de`, `en_gb`, `EN-GB`, `en`) from outside
/// the app (a website link) into a shipped language. Bare `en` is en-US.
Locale? appLocaleFromLooseTag(String? raw) {
  final trimmed = raw?.trim().replaceAll('_', '-') ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  final parts = trimmed.split('-');
  final language = parts.first.toLowerCase();
  final region = parts.length > 1 ? parts[1].toUpperCase() : '';
  if (language == 'en' && region.isEmpty) {
    return appLocaleFromTag('en-US');
  }
  return appLocaleFromTag(region.isEmpty ? language : '$language-$region') ??
      appLocaleFromTag(language);
}

/// The `lang` query parameter of the page the web app was opened from, e.g.
/// `/app/?lang=de#/signin` from a German website page. Also read from the
/// hash route (`#/signin?lang=de`). Null when absent or unsupported.
Locale? appLocaleFromLaunchUri(Uri uri) {
  final direct = uri.queryParameters['lang'];
  if (direct != null) {
    return appLocaleFromLooseTag(direct);
  }
  final fragment = uri.fragment;
  final query = fragment.indexOf('?');
  if (query < 0) {
    return null;
  }
  try {
    return appLocaleFromLooseTag(
      Uri.splitQueryString(fragment.substring(query + 1))['lang'],
    );
  } on FormatException {
    return null;
  }
}

/// Reads the locally cached choice. Called once before `runApp` so the very
/// first frame is already in the member's language, before any sign-in.
///
/// On the web, when nothing is cached yet, a supported `lang` query parameter
/// of [launchUri] (the website passes its page language) seeds the cache. It
/// is not an explicit pick: an account's stored language still wins.
Future<Locale?> readCachedAppLocale({Uri? launchUri}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cached = appLocaleFromTag(prefs.getString(_cacheKey));
    if (cached != null || launchUri == null) {
      return cached;
    }
    final seeded = appLocaleFromLaunchUri(launchUri);
    if (seeded != null) {
      await prefs.setString(_cacheKey, appLocaleToTag(seeded));
    }
    return seeded;
  } on Object {
    // No cache (first launch, or the plugin is unavailable in a test): the
    // device language applies until the member picks one.
    return launchUri == null ? null : appLocaleFromLaunchUri(launchUri);
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
  /// knows the member is signed in.
  ///
  /// Which side wins:
  ///  * a language picked on a signed-out screen (welcome, sign-in, sign-up)
  ///    is the member's latest explicit choice: it is saved to the account,
  ///    even over an older stored value;
  ///  * an account with no stored language (a new account) gets the language
  ///    the app is shown in saved, so the choice follows them to other
  ///    devices;
  ///  * otherwise the account's stored language wins over the local cache.
  Future<void> ensureLoaded() async {
    final userId = _userId;
    if (userId == null || userId == _loadedFor) {
      return;
    }
    _loadedFor = userId;
    try {
      final pickedBeforeSignIn = await _readPickedBeforeSignIn();
      final settings = await _ref.read(userSettingsProvider.future);
      // Someone else signed in while this member's settings were loading.
      if (_userId != userId) {
        return;
      }
      final serverTag = settings.locale.trim();
      final localTag = appLocaleToTag(state);
      final carryLocal =
          pickedBeforeSignIn || (serverTag.isEmpty && localTag.isNotEmpty);
      if (carryLocal) {
        if (serverTag != localTag) {
          await _ref
              .read(userSettingsProvider.notifier)
              .patchSettings(locale: localTag);
          final result = _ref.read(userSettingsProvider);
          if (result.hasError) {
            // Keep the flag: the next sign-in tries again. The language on
            // screen stays the member's pick either way.
            _log.error(
              'Failed to save the pre-sign-in language',
              result.error,
              result.stackTrace,
            );
            _ref.invalidate(userSettingsProvider);
            return;
          }
        }
        await _clearPickedBeforeSignIn();
        return;
      }
      final stored = appLocaleFromTag(serverTag);
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
      // Signed out: remember that this was an explicit pick so it is saved
      // to the account that signs in next (see [ensureLoaded]).
      await _setPickedBeforeSignIn();
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

  Future<bool> _readPickedBeforeSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pickedBeforeSignInKey) ?? false;
    } on Object {
      return false;
    }
  }

  Future<void> _setPickedBeforeSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pickedBeforeSignInKey, true);
    } on Object catch (e, stackTrace) {
      _log.error('Failed to remember the pre-sign-in language', e, stackTrace);
    }
  }

  Future<void> _clearPickedBeforeSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pickedBeforeSignInKey);
    } on Object catch (e, stackTrace) {
      _log.error('Failed to clear the pre-sign-in flag', e, stackTrace);
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
