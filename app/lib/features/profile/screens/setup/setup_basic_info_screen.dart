import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_photos_screen.dart';
import 'setup_shared_widgets.dart';

/// Step 1 of 4 — name, date of birth, gender, optional bio.
///
/// Layout: Scaffold → bgGradient → SafeArea → Column(header, scrollable form).
/// All data is persisted to the Go BFF via [ProfileSetupNotifier.saveBasicInfo].
class SetupBasicInfoScreen extends ConsumerStatefulWidget {
  const SetupBasicInfoScreen({super.key});

  @override
  ConsumerState<SetupBasicInfoScreen> createState() =>
      _SetupBasicInfoScreenState();
}

class _SetupBasicInfoScreenState extends ConsumerState<SetupBasicInfoScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  int? _dobDay;
  int? _dobMonth;
  int? _dobYear;
  String _gender = 'M';
  bool _didInitialize = false;
  bool _isSaving = false;

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
    _isSaving = true;
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
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _isSaving = false;
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const SetupPhotosScreen()),
        );
      });
    } on Exception catch (_) {
      if (!mounted) return;
      _isSaving = false;
      setState(() {});
      _snack('Failed to save — please try again.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomPad = keyboardInset > 0
        ? keyboardInset + 32.0
        : safeBottomInset + 36.0;

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
              SetupHeader(
                currentStep: 1,
                totalSteps: 4,
                onBack: () => Navigator.of(context).maybePop(),
              ),
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
                          FormCard(
                            child: draftAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (e, _) => SetupErrorState(
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
                                  if (_dobDay != null && v != null) {
                                    final max = _daysInMonth(v, _dobYear);
                                    if (_dobDay! > max) _dobDay = max;
                                  }
                                }),
                                onDobYearChanged: (v) => setState(() {
                                  _dobYear = v;
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
      setupFormLabel(context, 'Your name', Icons.person_outline_rounded),
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
        decoration: glassInputDecoration(hint: 'Enter your first name'),
      ),

      const SizedBox(height: 24),
      setupSectionDivider(),
      const SizedBox(height: 20),

      setupFormLabel(context, 'Date of birth', Icons.cake_rounded),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: GlassDropdown<int>(
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
          Expanded(
            flex: 3,
            child: GlassDropdown<int>(
              hint: 'Month',
              value: dobMonth,
              enabled: !isSaving,
              items: List.generate(12, (i) => i + 1),
              labelBuilder: monthName,
              onChanged: onDobMonthChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: GlassDropdown<int>(
              hint: 'Year',
              value: dobYear,
              enabled: !isSaving,
              items: () {
                final now = DateTime.now();
                return List.generate(63, (i) => now.year - 18 - i);
              }(),
              labelBuilder: (v) => v.toString(),
              onChanged: onDobYearChanged,
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),
      setupSectionDivider(),
      const SizedBox(height: 20),

      setupFormLabel(context, 'I identify as', Icons.waving_hand_rounded),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: GenderCard(
              emoji: '\u2642\uFE0F',
              label: 'Man',
              selected: gender == 'M',
              onTap: () => onGenderChanged('M'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GenderCard(
              emoji: '\u2640\uFE0F',
              label: 'Woman',
              selected: gender == 'F',
              onTap: () => onGenderChanged('F'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GenderCard(
              emoji: '\u2728',
              label: 'Other',
              selected: gender == 'Other',
              onTap: () => onGenderChanged('Other'),
            ),
          ),
        ],
      ),

      const SizedBox(height: 32),
      setupSectionDivider(),
      const SizedBox(height: 20),
      setupFormLabel(
        context,
        'About you (optional)',
        Icons.auto_stories_rounded,
      ),
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
            glassInputDecoration(
              hint: 'Tell people a little about yourself…',
            ).copyWith(
              counterStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
      ),

      const SizedBox(height: 32),
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
