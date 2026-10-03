import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Numbers shown to members, in the app's current language.
///
/// Use these instead of `'$count'`, `toStringAsFixed` or `'$x%'` so digit
/// grouping, decimal marks and percent spacing follow the member's locale:
/// "1,234" / "45%" in English, "1.234" / "45 %" in German.
String _localeName(BuildContext context) =>
    Localizations.maybeLocaleOf(context)?.toString() ?? 'en';

/// A whole count with digit grouping: "1,234" (en), "1.234" (de).
String formatCount(BuildContext context, num value) =>
    NumberFormat.decimalPattern(_localeName(context)).format(value);

/// A whole percent from 0–100: "45%" (en), "45\u00A0%" (de, fr: a no-break
/// space keeps the sign with the number).
String formatPercent(BuildContext context, num percent) =>
    NumberFormat.percentPattern(_localeName(context)).format(percent / 100);
