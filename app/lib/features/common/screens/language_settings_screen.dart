import 'package:flutter/material.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/language_picker.dart';

/// Language picker: the ten shipped languages by their own names, plus
/// "use device language". The choice is stored on the account
/// (`settings.locale`) and cached locally so it applies before sign-in.
///
/// The same list is offered signed out as a sheet ([showLanguagePickerSheet]).
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                child: const LanguageOptionList(
                  qaPrefix: 'qa.settings.language.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
