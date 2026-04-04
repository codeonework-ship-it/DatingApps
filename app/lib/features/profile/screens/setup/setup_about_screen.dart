import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/preference_master_data_provider.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_preview_screen.dart';
import 'setup_shared_widgets.dart';

/// Step 3 of 4 — bio, height, education, profession, lifestyle (drinking,
/// smoking, religion).
///
/// Merges the old About + Lifestyle screens into a single Crystal Gold glass
/// form. Saves via [ProfileSetupNotifier.saveAbout] + [saveLifestyle].
class SetupAboutScreen extends ConsumerStatefulWidget {
  const SetupAboutScreen({super.key});

  @override
  ConsumerState<SetupAboutScreen> createState() => _SetupAboutScreenState();
}

class _SetupAboutScreenState extends ConsumerState<SetupAboutScreen> {
  final _bioController = TextEditingController();
  final _professionController = TextEditingController();
  int? _height;
  String? _education;
  String? _income;

  // Lifestyle
  String _drinking = 'Never';
  String _smoking = 'Never';
  String? _religion;

  bool _didInitialize = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _bioController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bio = _bioController.text.trim();
    if (bio.length < ValidationConstants.minBioLength) {
      _snack(
        'Bio must be at least ${ValidationConstants.minBioLength} characters.',
      );
      return;
    }
    _isSaving = true;
    setState(() {});
    try {
      final notifier = ref.read(profileSetupNotifierProvider.notifier);
      await notifier.saveAbout(
        bio: bio,
        heightCm: _height,
        education: _education,
        profession: _professionController.text.trim().isEmpty
            ? null
            : _professionController.text.trim(),
        incomeRange: _income,
      );
      await notifier.saveLifestyle(
        drinking: _drinking,
        smoking: _smoking,
        religion: _religion,
      );
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _isSaving = false;
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const SetupPreviewScreen()),
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
    final masterData = ref
        .watch(preferenceMasterDataProvider)
        .maybeWhen(data: (data) => data, orElse: PreferenceMasterData.empty);
    final religionOptions = masterData.religions;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomPad = keyboardInset > 0
        ? keyboardInset + 32.0
        : safeBottomInset + 36.0;

    draftAsync.whenData((draft) {
      if (_didInitialize) return;
      _didInitialize = true;
      _bioController.text = draft.bio;
      _professionController.text = draft.profession ?? '';
      _height = draft.heightCm;
      _education = draft.education;
      _income = draft.incomeRange;
      _drinking = draft.drinking;
      _smoking = draft.smoking;
      _religion = draft.religion;
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              SetupHeader(
                currentStep: 3,
                totalSteps: 4,
                onBack: () => Navigator.of(context).pop(),
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
                            'Make your profile shine',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'These details help find better matches.',
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
                              data: (_) => _AboutForm(
                                bioController: _bioController,
                                professionController: _professionController,
                                height: _height,
                                education: _education,
                                income: _income,
                                drinking: _drinking,
                                smoking: _smoking,
                                religion: _religion,
                                religionOptions: religionOptions,
                                isSaving: _isSaving,
                                onHeightChanged: (v) =>
                                    setState(() => _height = v),
                                onEducationChanged: (v) =>
                                    setState(() => _education = v),
                                onIncomeChanged: (v) =>
                                    setState(() => _income = v),
                                onDrinkingChanged: (v) =>
                                    setState(() => _drinking = v ?? 'Never'),
                                onSmokingChanged: (v) =>
                                    setState(() => _smoking = v ?? 'Never'),
                                onReligionChanged: (v) =>
                                    setState(() => _religion = v),
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

class _AboutForm extends StatelessWidget {
  const _AboutForm({
    required this.bioController,
    required this.professionController,
    required this.height,
    required this.education,
    required this.income,
    required this.drinking,
    required this.smoking,
    required this.religion,
    required this.religionOptions,
    required this.isSaving,
    required this.onHeightChanged,
    required this.onEducationChanged,
    required this.onIncomeChanged,
    required this.onDrinkingChanged,
    required this.onSmokingChanged,
    required this.onReligionChanged,
    required this.onSave,
  });

  final TextEditingController bioController;
  final TextEditingController professionController;
  final int? height;
  final String? education;
  final String? income;
  final String drinking;
  final String smoking;
  final String? religion;
  final List<String> religionOptions;
  final bool isSaving;
  final ValueChanged<int?> onHeightChanged;
  final ValueChanged<String?> onEducationChanged;
  final ValueChanged<String?> onIncomeChanged;
  final ValueChanged<String?> onDrinkingChanged;
  final ValueChanged<String?> onSmokingChanged;
  final ValueChanged<String?> onReligionChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ── Bio ──────────────────────────────────────────────────────────
      setupFormLabel(context, 'Bio', Icons.auto_stories_rounded),
      const SizedBox(height: 8),
      TextField(
        controller: bioController,
        maxLength: ValidationConstants.maxBioLength,
        maxLines: 5,
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
              hint: 'Tell people about you (min 10 chars)',
            ).copyWith(
              counterStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
              ),
            ),
      ),

      const SizedBox(height: 20),
      setupSectionDivider(),
      const SizedBox(height: 20),

      // ── Height ────────────────────────────────────────────────────────
      setupFormLabel(context, 'Height (cm)', Icons.height_rounded),
      const SizedBox(height: 8),
      GlassDropdown<int>(
        hint: 'Select height',
        value: height,
        enabled: !isSaving,
        items: List.generate(61, (i) => 150 + i),
        labelBuilder: (v) => '$v cm',
        onChanged: onHeightChanged,
      ),

      const SizedBox(height: 20),

      // ── Education ─────────────────────────────────────────────────────
      setupFormLabel(context, 'Education', Icons.school_rounded),
      const SizedBox(height: 8),
      GlassDropdown<String>(
        hint: 'Select education',
        value: education,
        enabled: !isSaving,
        items: const ['High School', "Bachelor's", "Master's", 'PhD', 'Other'],
        labelBuilder: (v) => v,
        onChanged: onEducationChanged,
      ),

      const SizedBox(height: 20),

      // ── Profession ────────────────────────────────────────────────────
      setupFormLabel(context, 'Profession', Icons.work_outline_rounded),
      const SizedBox(height: 8),
      TextField(
        controller: professionController,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        enabled: !isSaving,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: glassInputDecoration(hint: 'e.g. Software Engineer'),
      ),

      const SizedBox(height: 20),

      // ── Income ────────────────────────────────────────────────────────
      setupFormLabel(context, 'Income (optional)', Icons.attach_money_rounded),
      const SizedBox(height: 8),
      GlassDropdown<String>(
        hint: 'Prefer not to say',
        value: income,
        enabled: !isSaving,
        items: const ['0-5L', '5-10L', '10-20L', '20L+'],
        labelBuilder: (v) => v,
        onChanged: onIncomeChanged,
      ),

      const SizedBox(height: 24),
      setupSectionDivider(),
      const SizedBox(height: 20),

      // ── Lifestyle section ─────────────────────────────────────────────
      Text(
        'Lifestyle',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTheme.crystalGoldSoft,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 16),

      // ── Drinking ──────────────────────────────────────────────────────
      setupFormLabel(context, 'Drinking', Icons.local_bar_rounded),
      const SizedBox(height: 8),
      GlassDropdown<String>(
        hint: 'Select',
        value: drinking,
        enabled: !isSaving,
        items: const ['Never', 'Socially', 'Regularly'],
        labelBuilder: (v) => v,
        onChanged: onDrinkingChanged,
      ),

      const SizedBox(height: 20),

      // ── Smoking ───────────────────────────────────────────────────────
      setupFormLabel(context, 'Smoking', Icons.smoking_rooms_rounded),
      const SizedBox(height: 8),
      GlassDropdown<String>(
        hint: 'Select',
        value: smoking,
        enabled: !isSaving,
        items: const ['Never', 'Socially', 'Regularly'],
        labelBuilder: (v) => v,
        onChanged: onSmokingChanged,
      ),

      const SizedBox(height: 20),

      // ── Religion ──────────────────────────────────────────────────────
      setupFormLabel(
        context,
        'Religion (optional)',
        Icons.auto_awesome_rounded,
      ),
      const SizedBox(height: 8),
      GlassDropdown<String>(
        hint: 'Prefer not to say',
        value: religion,
        enabled: !isSaving,
        items: religionOptions,
        labelBuilder: (v) => v,
        onChanged: onReligionChanged,
      ),

      const SizedBox(height: 32),

      // ── Next ──────────────────────────────────────────────────────────
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
