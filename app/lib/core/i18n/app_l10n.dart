import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'app_locale_provider.dart';

/// Strings for code that has no [BuildContext] (providers, services).
///
/// Prefer `AppLocalizations.of(context)` in widgets. This resolves [locale]
/// (or, when null, the device locale) against the shipped languages the same
/// way `MaterialApp` does: exact match, then language only, then English.
AppLocalizations appL10nFor(Locale? locale) {
  final resolved = locale ?? PlatformDispatcher.instance.locale;
  for (final candidate in <Locale>[
    resolved,
    Locale(resolved.languageCode),
    const Locale('en'),
  ]) {
    try {
      return lookupAppLocalizations(candidate);
    } on Object {
      // Unsupported locale: try the next, broader candidate.
    }
  }
  return lookupAppLocalizations(const Locale('en'));
}

/// The member's current UI strings from a provider: their chosen language,
/// or the device language when they follow the device.
AppLocalizations appL10nOf(Ref ref) => appL10nFor(ref.read(appLocaleProvider));

Locale? _currentAppLocale;

/// Called by the app root with the member's chosen locale (null = device) so
/// code without a [BuildContext] or [Ref] can use [currentAppL10n].
void setCurrentAppLocale(Locale? locale) => _currentAppLocale = locale;

/// The strings for the language the app is currently shown in, for plain
/// helpers that have neither a [BuildContext] nor a [Ref].
AppLocalizations currentAppL10n() => appL10nFor(_currentAppLocale);

/// `AppLocalizations.of(context)` for shared widgets that may be pumped
/// without localization delegates (e.g. in isolated widget tests): falls back
/// to English instead of throwing.
AppLocalizations l10nOrEnglish(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));
