import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_photos_screen.dart';

/// Basic Info setup step — name, date of birth, gender.
///
/// Layout contract (no LayoutBuilder anywhere):
///   Scaffold → body: bgGradient → SafeArea → SingleChildScrollView → Column
class SetupBasicInfoScreen extends ConsumerStatefulWidget {
  const SetupBasicInfoScreen({super.key});

  @override
  ConsumerState<SetupBasicInfoScreen> createState() =>
      _SetupBasicInfoScreenState();
}

class _SetupBasicInfoScreenState extends ConsumerState<SetupBasicInfoScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  // DOB stored as three separate fields so no calendar picker is needed
  int? _dobDay;
  int? _dobMonth;
  int? _dobYear;
  String _gender = 'M';
  bool _didInitialize = false;
  bool _isSaving = false;

  // Derived composed date (null if any part is missing / invalid)
  DateTime? get _dob {
    final d = _dobDay;
    final m = _dobMonth;
    final y = _dobYear;
    if (d == null || m == null || y == null) return null;
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  // Max valid days for a month+year combo (null year → assume leap for safety)
  int _daysInMonth(int month, int? year) {
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2) {
      final y = year ?? 2000;
      final isLeap = (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
      return isLeap ? 29 : 28;
    }
    return days[month];
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.length < ValidationConstants.minNameLength) {
      _snack(
        'Name must be at least ${ValidationConstants.minNameLength} characters.',
      );
      return;
    }
    if (_dob == null) {
      _snack('Please select your date of birth.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(profileSetupNotifierProvider.notifier);
      await notifier.saveBasicInfo(
        name: name,
        dateOfBirth: _dob!,
        gender: _gender,
      );
      final bio = _bioController.text.trim();
      if (bio.isNotEmpty) {
        await notifier.saveAbout(
          bio: bio,
          heightCm: null,
          education: null,
          profession: null,
          incomeRange: null,
        );
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SetupPhotosScreen()),
      );
    } on Exception catch (_) {
      if (!mounted) return;
      _snack('Failed to save — please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ─── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomPad = keyboardInset > 0
        ? keyboardInset + 32.0
        : safeBottomInset + 36.0;

    // One-time init from loaded draft (pre-fill if user comes back)
    draftAsync.whenData((draft) {
      if (_didInitialize) return;
      _didInitialize = true;
      _nameController.text = draft.name;
      _bioController.text = draft.bio;
      if (draft.dateOfBirth != null) {
        _dobDay = draft.dateOfBirth!.day;
        _dobMonth = draft.dateOfBirth!.month;
        _dobYear = draft.dateOfBirth!.year;
      }
      _gender = draft.gender.isNotEmpty ? draft.gender : 'M';
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── inline header ───────────────────────────────────────────
              _SetupHeader(
                currentStep: 1,
                totalSteps: 4,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              // ── scrollable form area ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTheme.contentMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Tell us about you',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This helps us find your best matches.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.60),
                                ),
                          ),
                          const SizedBox(height: 24),
                          _FormCard(
                            child: draftAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (e, _) => _ErrorState(
                                message: e.toString(),
                                onRetry: () => ref.invalidate(
                                  profileSetupNotifierProvider,
                                ),
                              ),
                              data: (_) => _BasicInfoForm(
                                nameController: _nameController,
                                bioController: _bioController,
                                dobDay: _dobDay,
                                dobMonth: _dobMonth,
                                dobYear: _dobYear,
                                gender: _gender,
                                isSaving: _isSaving,
                                daysInMonth: _daysInMonth,
                                onDobDayChanged: (v) =>
                                    setState(() => _dobDay = v),
                                onDobMonthChanged: (v) => setState(() {
                                  _dobMonth = v;
                                  // clamp day to valid range after month change
                                  if (_dobDay != null && v != null) {
                                    final max = _daysInMonth(v, _dobYear);
                                    if (_dobDay! > max) _dobDay = max;
                                  }
                                }),
                                onDobYearChanged: (v) => setState(() {
                                  _dobYear = v;
                                  // clamp day if Feb leap-year edge case
                                  if (_dobDay != null &&
                                      _dobMonth != null &&
                                      v != null) {
                                    final max = _daysInMonth(_dobMonth!, v);
                                    if (_dobDay! > max) _dobDay = max;
                                  }
                                }),
                                onGenderChanged: (g) =>
                                    setState(() => _gender = g),
                                onSave: _save,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

// ── inline header with progress bar ────────────────────────────────────

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
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
        // back + step label row
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
        // segmented progress bar
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

// ── frosted form card ────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
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

class _BasicInfoForm extends StatelessWidget {
  const _BasicInfoForm({
    required this.nameController,
    required this.bioController,
    required this.dobDay,
    required this.dobMonth,
    required this.dobYear,
    required this.gender,
    required this.isSaving,
    required this.daysInMonth,
    required this.onDobDayChanged,
    required this.onDobMonthChanged,
    required this.onDobYearChanged,
    required this.onGenderChanged,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController bioController;
  final int? dobDay;
  final int? dobMonth;
  final int? dobYear;
  final String gender;
  final bool isSaving;
  final int Function(int month, int? year) daysInMonth;
  final ValueChanged<int?> onDobDayChanged;
  final ValueChanged<int?> onDobMonthChanged;
  final ValueChanged<int?> onDobYearChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ── name ──────────────────────────────────────────────────────────
      _formLabel(context, 'Your name', Icons.person_outline_rounded),
      const SizedBox(height: 8),
      TextField(
        controller: nameController,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        enabled: !isSaving,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: _glassInputDecoration(hint: 'Enter your first name'),
      ),

      const SizedBox(height: 24),
      _sectionDivider(),
      const SizedBox(height: 20),

      // ── dob ───────────────────────────────────────────────────────────
      _formLabel(context, 'Date of birth', Icons.cake_rounded),
      const SizedBox(height: 10),
      Row(
        children: [
          // Day
          Expanded(
            flex: 2,
            child: _DobDropdown(
              hint: 'Day',
              value: dobDay,
              enabled: !isSaving,
              items: List.generate(
                dobMonth != null ? daysInMonth(dobMonth!, dobYear) : 31,
                (i) => i + 1,
              ),
              labelBuilder: (v) => v.toString(),
              onChanged: onDobDayChanged,
            ),
          ),
          const SizedBox(width: 8),
          // Month
          Expanded(
            flex: 3,
            child: _DobDropdown(
              hint: 'Month',
              value: dobMonth,
              enabled: !isSaving,
              items: List.generate(12, (i) => i + 1),
              labelBuilder: (v) => _monthName(v),
              onChanged: onDobMonthChanged,
            ),
          ),
          const SizedBox(width: 8),
          // Year
          Expanded(
            flex: 3,
            child: _DobDropdown(
              hint: 'Year',
              value: dobYear,
              enabled: !isSaving,
              items: () {
                final now = DateTime.now();
                return List.generate(
                  63, // 18-80 year range
                  (i) => now.year - 18 - i,
                );
              }(),
              labelBuilder: (v) => v.toString(),
              onChanged: onDobYearChanged,
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),
      _sectionDivider(),
      const SizedBox(height: 20),

      // ── gender ────────────────────────────────────────────────────────
      _formLabel(context, 'I identify as', Icons.waving_hand_rounded),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _GenderCard(
              emoji: '\u2642\uFE0F',
              label: 'Man',
              value: 'M',
              selected: gender == 'M',
              onTap: () => onGenderChanged('M'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _GenderCard(
              emoji: '\u2640\uFE0F',
              label: 'Woman',
              value: 'F',
              selected: gender == 'F',
              onTap: () => onGenderChanged('F'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _GenderCard(
              emoji: '\u2728',
              label: 'Other',
              value: 'Other',
              selected: gender == 'Other',
              onTap: () => onGenderChanged('Other'),
            ),
          ),
        ],
      ),

      const SizedBox(height: 32),

      // ── bio / description ────────────────────────────────────────────────
      _sectionDivider(),
      const SizedBox(height: 20),
      _formLabel(context, 'About you (optional)', Icons.auto_stories_rounded),
      const SizedBox(height: 8),
      TextField(
        controller: bioController,
        maxLength: 300,
        maxLines: 4,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        enabled: !isSaving,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
        decoration:
            _glassInputDecoration(
              hint: 'Tell people a little about yourself…',
            ).copyWith(
              counterStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
      ),

      const SizedBox(height: 32),

      // ── next button ───────────────────────────────────────────────────
      SizedBox(
        width: double.infinity,
        height: 54,
        child: GlassButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          shinyEffect: true,
          isLoading: isSaving,
          onPressed: isSaving ? null : onSave,
        ),
      ),
    ],
  );
}

// ── gender card ──────────────────────────────────────────────────────────────

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String value;
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
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
          color: AppTheme.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(
          Icons.refresh_rounded,
          color: AppTheme.crystalGoldDeep,
        ),
        label: Text(
          'Retry',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.crystalGoldDeep,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

// ── shared helpers ────────────────────────────────────────────────────────────

Widget _formLabel(BuildContext context, String text, IconData icon) => Row(
  children: [
    Icon(icon, size: 16, color: AppTheme.crystalGoldSoft),
    const SizedBox(width: 7),
    Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.90),
        letterSpacing: 0.3,
      ),
    ),
  ],
);

Widget _sectionDivider() => Container(
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

InputDecoration _glassInputDecoration({required String hint}) =>
    InputDecoration(
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
        borderSide: const BorderSide(
          color: AppTheme.crystalGoldSoft,
          width: 1.6,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
    );

// ── month name helper ──────────────────────────────────────────────────

const _kMonthNames = [
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

String _monthName(int month) =>
    month >= 1 && month <= 12 ? _kMonthNames[month] : '?';

// ── DOB dropdown (glass-styled) ──────────────────────────────────────────

class _DobDropdown<T> extends StatelessWidget {
  const _DobDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.enabled = true,
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
          // crystal specular top-edge
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
