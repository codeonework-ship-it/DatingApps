import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Localized strings for the rich text editor and reader. Falls back to
/// English where a host has no app localizations (embedded previews, tests).
AppLocalizations richL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));
