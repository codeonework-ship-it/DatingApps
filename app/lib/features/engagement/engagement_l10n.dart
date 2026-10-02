import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_locale_provider.dart';
import '../../l10n/app_localizations.dart';

/// The engagement strings for [context], falling back to English when the
/// widget tree has no [AppLocalizations] (screens pumped by tests without the
/// app's delegates).
AppLocalizations engagementL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));

/// The engagement strings for providers that set user-facing fallback
/// messages without a [BuildContext]: the member's chosen language, else the
/// device's, resolved against the shipped locales the way `MaterialApp` does.
AppLocalizations engagementL10nFor(Ref ref) {
  final chosen = ref.read(appLocaleProvider);
  final locale = basicLocaleListResolution(<Locale>[
    ?chosen,
    ...PlatformDispatcher.instance.locales,
  ], AppLocalizations.supportedLocales);
  return lookupAppLocalizations(locale);
}
