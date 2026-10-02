import '../../l10n/app_localizations.dart';

/// Display label for a profile or filter option whose stored (API) value is
/// the English word, e.g. 'Never', 'Single', 'Introvert', 'Hindu'.
///
/// The stored value never changes; only what the member reads does. Unknown
/// values (server master data, free text) are returned unchanged.
String localizedProfileOption(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Never':
      return l10n.optionNever;
    case 'Occasionally':
      return l10n.optionOccasionally;
    case 'Socially':
      return l10n.optionSocially;
    case 'Regularly':
      return l10n.optionRegularly;
    case 'Single':
      return l10n.optionSingle;
    case 'Divorced':
      return l10n.optionDivorced;
    case 'Widowed':
      return l10n.optionWidowed;
    case 'Separated':
      return l10n.optionSeparated;
    case 'Complicated':
      return l10n.optionComplicated;
    case 'Introvert':
      return l10n.optionIntrovert;
    case 'Ambivert':
      return l10n.optionAmbivert;
    case 'Extrovert':
      return l10n.optionExtrovert;
    case 'High School':
      return l10n.optionHighSchool;
    case "Bachelor's":
      return l10n.optionBachelors;
    case "Master's":
      return l10n.optionMasters;
    case 'PhD':
      return l10n.optionPhd;
    case 'Other':
      return l10n.optionOther;
    case 'Prefer not to say':
      return l10n.optionPreferNotToSay;
    case 'Hindu':
      return l10n.optionHindu;
    case 'Muslim':
      return l10n.optionMuslim;
    case 'Christian':
      return l10n.optionChristian;
    case 'Sikh':
      return l10n.optionSikh;
    case 'Buddhist':
      return l10n.optionBuddhist;
    case 'Jain':
      return l10n.optionJain;
    case 'Jewish':
      return l10n.optionJewish;
    case 'Spiritual':
      return l10n.optionSpiritual;
    case 'Agnostic':
      return l10n.optionAgnostic;
    case 'Atheist':
      return l10n.optionAtheist;
  }
  return value;
}
