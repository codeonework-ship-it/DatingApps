import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_locale_provider.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';

/// Language picker: the ten shipped languages by their own names, plus
/// "use device language". The choice is stored on the account
/// (`settings.locale`) and cached locally so it applies before sign-in.
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(appLocaleProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  l10n.languageIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 8),
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.9,
                ),
                blur: 12,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: Column(
                  children: [
                    _LanguageRow(
                      qaId: 'qa.settings.language.device',
                      title: l10n.languageUseDevice,
                      subtitle: l10n.languageUseDeviceSubtitle,
                      icon: Icons.phone_android_rounded,
                      selected: selected == null,
                      onTap: () => _choose(context, ref, null),
                    ),
                    const Divider(height: 1),
                    for (final language in appLanguages)
                      _LanguageRow(
                        qaId: 'qa.settings.language.${language.tag}',
                        title: language.nativeName,
                        selected: selected == language.locale,
                        onTap: () => _choose(context, ref, language.locale),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    Locale? locale,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    // Read before the await: the strings switch language with the choice.
    final failure = AppLocalizations.of(context).languageSaveFailed;
    try {
      await ref.read(appLocaleProvider.notifier).select(locale);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.qaId,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String qaId;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: qaId,
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
