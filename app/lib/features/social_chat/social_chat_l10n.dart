import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The chat and Rooms strings for [context], falling back to English when
/// the widget tree has no [AppLocalizations] (screens pushed from widgets
/// tested without the app's delegates).
AppLocalizations chatL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(const Locale('en'));

/// A moment for "until …" lines: the time today, otherwise the date and time,
/// in the reader's locale.
String chatWhen(BuildContext context, DateTime at) {
  final local = at.toLocal();
  final now = DateTime.now();
  final time = TimeOfDay.fromDateTime(local).format(context);
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return time;
  }
  return '${MaterialLocalizations.of(context).formatMediumDate(local)}, $time';
}
