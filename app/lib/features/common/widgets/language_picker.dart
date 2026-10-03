import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_locale_provider.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/widgets/qa_id.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

/// The shipped language the app is shown in: the chosen one, or the device
/// language resolved the way `MaterialApp` resolves it (exact, then language
/// only, then English).
AppLanguage currentAppLanguage(BuildContext context, Locale? chosen) {
  final shown = chosen ?? Localizations.localeOf(context);
  for (final language in appLanguages) {
    if (language.locale == shown) {
      return language;
    }
  }
  final englishTag = shown.countryCode == 'GB' ? 'en-GB' : 'en-US';
  for (final language in appLanguages) {
    if (shown.languageCode == 'en'
        ? language.tag == englishTag
        : language.locale.languageCode == shown.languageCode) {
      return language;
    }
  }
  return appLanguages.first;
}

/// Applies [locale] (null = follow the device). Signed out it only changes
/// this device (and is carried into the next account that signs in); signed
/// in it is saved to the account, and a failed save is reported: through
/// [onFailed] when given (e.g. inside a sheet, where a snack bar would sit
/// behind it), otherwise as a snack bar.
Future<bool> chooseAppLanguage(
  BuildContext context,
  WidgetRef ref,
  Locale? locale, {
  ValueChanged<String>? onFailed,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  // Read before the await: the strings switch language with the choice.
  final failure = AppLocalizations.of(context).languageSaveFailed;
  try {
    await ref.read(appLocaleProvider.notifier).select(locale);
    return true;
  } on Object {
    if (onFailed != null) {
      onFailed(failure);
    } else {
      messenger?.showSnackBar(SnackBar(content: Text(failure)));
    }
    return false;
  }
}

/// "Use device language" plus the ten languages by their own names. Shared by
/// the Settings language screen and the signed-out language sheet.
///
/// [qaPrefix] keeps each surface's automation ids stable:
/// `<qaPrefix>device` and `<qaPrefix><tag>`.
class LanguageOptionList extends ConsumerWidget {
  const LanguageOptionList({
    required this.qaPrefix,
    this.onChosen,
    this.onFailed,
    super.key,
  });

  final String qaPrefix;

  /// Called after a choice was applied (e.g. to close a sheet).
  final VoidCallback? onChosen;

  /// Called with the message when a choice could not be saved; without it
  /// the failure is shown as a snack bar.
  final ValueChanged<String>? onFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(appLocaleProvider);

    Future<void> choose(Locale? locale) async {
      final applied = await chooseAppLanguage(
        context,
        ref,
        locale,
        onFailed: onFailed,
      );
      if (applied) {
        onChosen?.call();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LanguageRow(
          qaId: '${qaPrefix}device',
          title: l10n.languageUseDevice,
          subtitle: l10n.languageUseDeviceSubtitle,
          icon: Icons.phone_android_rounded,
          selected: selected == null,
          onTap: () => choose(null),
        ),
        const Divider(height: 1),
        for (final language in appLanguages)
          LanguageRow(
            qaId: '$qaPrefix${language.tag}',
            title: language.nativeName,
            locale: language.locale,
            selected: selected == language.locale,
            onTap: () => choose(language.locale),
          ),
      ],
    );
  }
}

/// One language option. The automation id is a semantics identifier (Android
/// resource-id, iOS accessibilityIdentifier); screen readers hear the
/// language name, spoken in that language.
class LanguageRow extends StatelessWidget {
  const LanguageRow({
    required this.qaId,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.locale,
    super.key,
  });

  final String qaId;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  /// The language [title] is written in, so a screen reader pronounces a
  /// native name ("Deutsch") correctly whatever the current language.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      identifier: qaId,
      button: true,
      selected: selected,
      child: ListTile(
        key: ValueKey<String>(qaId),
        minTileHeight: AppLayout.minTapTarget,
        leading: icon == null
            ? null
            : Icon(icon, color: selected ? scheme.primary : scheme.onSurface),
        title: Text(
          title,
          locale: locale,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: scheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}

/// Opens the language list as a bottom sheet. Works signed out: the choice
/// applies at once and is saved to the account at the next sign-in.
Future<void> showLanguagePickerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) =>
          _LanguageSheet(onChosen: () => Navigator.of(sheetContext).maybePop()),
    );

/// The sheet's content. Its own route, so it watches the session itself
/// rather than rebuilding with the screen that opened it. A failed save is
/// explained inside the sheet: a snack bar would be hidden behind it.
class _LanguageSheet extends ConsumerStatefulWidget {
  const _LanguageSheet({required this.onChosen});

  final VoidCallback onChosen;

  @override
  ConsumerState<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends ConsumerState<_LanguageSheet> {
  String? _failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final signedIn = ref.watch(
      authNotifierProvider.select((s) => s.isAuthenticated),
    );
    final failure = _failure;
    return Semantics(
      container: true,
      identifier: 'qa.language.sheet',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Text(
                l10n.languageTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(
                signedIn ? l10n.languageIntro : l10n.languageIntroSignedOut,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (failure != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    key: const ValueKey('qa.language.sheet.error'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded, color: scheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          failure,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            LanguageOptionList(
              qaPrefix: 'qa.language.option.',
              onChosen: widget.onChosen,
              onFailed: (message) {
                if (mounted) {
                  setState(() => _failure = message);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact language button (globe + the current language's own name) for
/// signed-out screens and screens without Settings.
class LanguagePickerButton extends ConsumerWidget {
  const LanguagePickerButton({
    this.foregroundColor,
    this.iconOnly = false,
    super.key,
  });

  /// Defaults to the theme's `onSurface`.
  final Color? foregroundColor;

  /// Just the globe (the language's name is in the tooltip and the spoken
  /// label), for app bars that already carry a title and other actions.
  final bool iconOnly;

  static const qaId = 'qa.language.picker_button';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = currentAppLanguage(context, ref.watch(appLocaleProvider));
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    final spoken = l10n.languagePickerButtonSemantics(language.nativeName);
    if (iconOnly) {
      return QaId(
        qaId,
        child: IconButton(
          key: const ValueKey(qaId),
          tooltip: spoken,
          color: color,
          onPressed: () => showLanguagePickerSheet(context),
          icon: const Icon(Icons.language_rounded),
        ),
      );
    }
    return Semantics(
      container: true,
      identifier: qaId,
      button: true,
      label: spoken,
      excludeSemantics: true,
      onTap: () => showLanguagePickerSheet(context),
      child: TextButton.icon(
        key: const ValueKey(qaId),
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(
            AppLayout.minTapTarget,
            AppLayout.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          // A full 48pt target even inside an app bar.
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        onPressed: () => showLanguagePickerSheet(context),
        icon: const Icon(Icons.language_rounded, size: 20),
        label: Text(
          language.nativeName,
          locale: language.locale,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
