import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onBack,
              tooltip: 'Back',
            ),
            const Spacer(),
            Text(
              'Step $currentStep of $totalSteps',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
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
                  margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: active
                        ? AppTheme.crystalGoldSoft
                        : Colors.white.withValues(alpha: 0.20),
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

// ── FormCard — frosted glassmorphic card with specular highlights ─────────────

class FormCard extends StatelessWidget {
  const FormCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.crystalGoldDeep.withValues(alpha: 0.22),
              blurRadius: 40,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // top-left specular crystal highlight
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 72,
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // golden top-edge shimmer beam
            Positioned(
              top: 0,
              left: 32,
              right: 32,
              height: 1.5,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.crystalGoldSoft.withValues(alpha: 0.70),
                        Colors.white.withValues(alpha: 0.90),
                        AppTheme.crystalGoldSoft.withValues(alpha: 0.70),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // inner content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: child,
            ),
          ],
        ),
      ),
    ),
  );
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasValue
              ? AppTheme.crystalGoldSoft.withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.22),
          width: hasValue ? 1.4 : 1.0,
        ),
        boxShadow: hasValue
            ? [
                BoxShadow(
                  color: AppTheme.crystalGoldSoft.withValues(alpha: 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          if (hasValue)
            Positioned(
              top: 0,
              left: 4,
              right: 4,
              height: 1.0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  hint,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.expand_more_rounded,
                color: hasValue
                    ? AppTheme.crystalGoldSoft
                    : Colors.white.withValues(alpha: 0.38),
                size: 18,
              ),
              dropdownColor: const Color(0xFF3A2800),
              borderRadius: BorderRadius.circular(16),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
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
                            color: AppTheme.crystalGoldSoft,
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
                        style: const TextStyle(
                          color: Colors.white,
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.crystalGoldSoft.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppTheme.crystalGoldSoft.withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.18),
          width: selected ? 1.6 : 1.0,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppTheme.crystalGoldSoft.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
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
                  ? AppTheme.crystalGoldSoft
                  : Colors.white.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    ),
  );
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.crystalGoldSoft, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.crystalGoldSoft,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.12),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.30),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppTheme.crystalGoldSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
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
        ? AppTheme.crystalGoldSoft
        : percent >= 50
        ? Colors.orangeAccent
        : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.18),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$current / $max',
        style: const TextStyle(
          color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.crystalGoldSoft),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.error_outline_rounded,
        color: AppTheme.errorRed,
        size: 40,
      ),
      const SizedBox(height: 12),
      Text(
        'Could not load profile data.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.60),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(
          Icons.refresh_rounded,
          color: AppTheme.crystalGoldSoft,
        ),
        label: Text(
          'Retry',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.crystalGoldSoft,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget setupFormLabel(BuildContext context, String text, IconData icon) => Row(
  children: [
    Icon(icon, size: 16, color: AppTheme.crystalGoldSoft),
    const SizedBox(width: 7),
    Expanded(
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.90),
          letterSpacing: 0.3,
        ),
      ),
    ),
  ],
);

Widget setupSectionDivider() => Container(
  height: 1,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.0),
      ],
    ),
  ),
);

InputDecoration glassInputDecoration({required String hint}) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
  filled: true,
  fillColor: Colors.white.withValues(alpha: 0.09),
  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppTheme.crystalGoldSoft, width: 1.6),
  ),
  disabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
  ),
);

/// Month names for DOB dropdowns.
const kMonthNames = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthName(int month) =>
    month >= 1 && month <= 12 ? kMonthNames[month] : '?';
