import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

// =============================================================================
// Shared widgets for the Crystal Gold profile setup flow.
//
// Every screen in the 4-step setup flow re-uses these building blocks so the
// visual language stays consistent without duplicating 300+ lines per screen.
// =============================================================================

// ── SetupHeader — inline back + step counter + segmented progress bar ────────

class SetupHeader extends StatelessWidget {
  const SetupHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    super.key,
  });
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: scheme.onSurface,
                  size: 20,
                ),
                onPressed: onBack,
                tooltip: AppLocalizations.of(context).profileSetupBackTooltip,
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(
                  context,
                ).profileSetupStepCounter(currentStep, totalSteps),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(totalSteps, (i) {
                final active = i < currentStep;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.only(right: i < totalSteps - 1 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active ? scheme.primary : scheme.outlineVariant,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FormCard — frosted glassmorphic card with specular highlights ─────────────

class FormCard extends StatelessWidget {
  const FormCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: child,
      ),
    );
  }
}

// ── GlassDropdown — glass-themed dropdown matching DOB dropdowns ─────────────

class GlassDropdown<T> extends StatelessWidget {
  const GlassDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasValue ? scheme.primary : scheme.outlineVariant,
          width: hasValue ? 1.4 : 1.0,
        ),
      ),
      child: Stack(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  hint,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.expand_more_rounded,
                color: hasValue ? scheme.primary : scheme.onSurfaceVariant,
                size: 18,
              ),
              dropdownColor: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              onChanged: enabled ? onChanged : null,
              selectedItemBuilder: (context) => items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          labelBuilder(item),
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        labelBuilder(item),
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── GenderCard — selectable gender pill with crystal gold highlights ──────────

class GenderCard extends StatelessWidget {
  const GenderCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── InfoCard — frosted card with icon + title header ─────────────────────────

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── TipBanner — subtle hint bar with lightbulb icon ──────────────────────────

class TipBanner extends StatelessWidget {
  const TipBanner({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CompletionBadge — percentage badge with colour coding ────────────────────

class CompletionBadge extends StatelessWidget {
  const CompletionBadge({required this.percent, super.key});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? Theme.of(context).colorScheme.primary
        : percent >= 50
        ? Colors.orangeAccent
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── CountBadge — current / max counter pill ──────────────────────────────────

class CountBadge extends StatelessWidget {
  const CountBadge({required this.current, required this.max, super.key});
  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$current / $max',
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── ProfileChip — rounded chip for preview attributes ────────────────────────

class ProfileChip extends StatelessWidget {
  const ProfileChip({required this.icon, required this.label, super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ErrorState — inline error with retry ─────────────────────────────────────

class SetupErrorState extends StatelessWidget {
  const SetupErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, color: scheme.error, size: 40),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).profileSetupLoadErrorTitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 140,
          height: 48,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, color: scheme.primary),
            label: Text(
              AppLocalizations.of(context).profileSetupRetry,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget setupFormLabel(BuildContext context, String text, IconData icon) => Row(
  children: [
    Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
    const SizedBox(width: 7),
    Expanded(
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: 0.3,
        ),
      ),
    ),
  ],
);

Widget setupSectionDivider(BuildContext context) =>
    Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant);

InputDecoration glassInputDecoration(
  BuildContext context, {
  required String hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    filled: true,
    fillColor: scheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.primary, width: 1.6),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
  );
}

/// Localised label for a profile option whose English value is stored on the
/// server (`ProfileOptionsConstants` education, income, drinking and smoking
/// values). The value itself is never translated; unknown values (e.g. from
/// the server's master data) are shown unchanged.
String localizedProfileOption(AppLocalizations l10n, String value) {
  switch (value) {
    case 'High School':
      return l10n.profileSetupEducationHighSchool;
    case "Bachelor's":
      return l10n.profileSetupEducationBachelors;
    case "Master's":
      return l10n.profileSetupEducationMasters;
    case 'PhD':
      return l10n.profileSetupEducationPhd;
    case 'Other':
      return l10n.profileSetupEducationOther;
    case 'Prefer not to say':
      return l10n.profileSetupPreferNotToSay;
    case 'Never':
      return l10n.profileSetupFrequencyNever;
    case 'Socially':
      return l10n.profileSetupFrequencySocially;
    case 'Occasionally':
      return l10n.profileSetupFrequencyOccasionally;
    case 'Regularly':
      return l10n.profileSetupFrequencyRegularly;
  }
  const below = 'Below ';
  if (value.startsWith(below)) {
    return l10n.profileSetupIncomeBelow(value.substring(below.length));
  }
  return value;
}
