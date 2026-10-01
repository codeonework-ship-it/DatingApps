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
/// Uses the same [ConsumerStatefulWidget] + single-Scaffold pattern as
/// the first setup step to keep the widget-tree identity stable across
/// provider rebuilds.
class SetupAboutScreen extends ConsumerStatefulWidget {
  const SetupAboutScreen({super.key, this.isSetupFlow = true});

  final bool isSetupFlow;

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

  /// Initialise local state from the draft exactly once.
  void _initFromDraft(ProfileDraft draft) {
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
  }

  Future<void> _save() async {
    final bio = _bioController.text.trim();
    if (bio.length < ValidationConstants.minBioLength) {
      _snack(
        'Bio must be at least ${ValidationConstants.minBioLength} characters.',
      );
      return;
    }
    setState(() => _isSaving = true);
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
        setState(() => _isSaving = false);
        if (widget.isSetupFlow) {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const SetupPreviewScreen()),
          );
        } else {
          Navigator.of(context).pop();
        }
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('Failed to save \u2014 please try again.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Auto-saves the current form values to the provider when the user presses
  /// the system/hardware back button without explicitly pressing "Save &
  /// Continue". This ensures that if the user navigates forward again (which
  /// creates a brand-new widget instance), the draft already contains their
  /// latest edits and the controllers are pre-populated correctly.
  void _autoSaveOnBack() {
    if (!_didInitialize) return;
    final notifier = ref.read(profileSetupNotifierProvider.notifier);
    final bio = _bioController.text.trim();
    if (bio.isNotEmpty) {
      // Fire-and-forget: persist latest form values to BFF draft.
      // ignore: discarded_futures
      notifier
          .saveAbout(
            bio: bio,
            heightCm: _height,
            education: _education,
            profession: _professionController.text.trim().isEmpty
                ? null
                : _professionController.text.trim(),
            incomeRange: _income,
          )
          .catchError((Object error) {
            _snack('Could not save your changes. Please try again.');
          });
      // ignore: discarded_futures
      notifier
          .saveLifestyle(
            drinking: _drinking,
            smoking: _smoking,
            religion: _religion,
          )
          .catchError((Object error) {
            _snack('Could not save your changes. Please try again.');
          });
    }
  }

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

    // Initialise local fields once from provider data.
    final draft = draftAsync.valueOrNull;
    if (draft != null) _initFromDraft(draft);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _autoSaveOnBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'These details help find better matches.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            FormCard(
                              child: draftAsync.when(
                                loading: () => Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
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
                                  isSetupFlow: widget.isSetupFlow,
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
    required this.isSetupFlow,
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
  final bool isSetupFlow;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // -- Bio
      setupFormLabel(context, 'Bio', Icons.auto_stories_rounded),
      const SizedBox(height: 8),
      Semantics(
        label: 'qa.setup.about.bio_field',
        textField: true,
        child: TextField(
          key: const ValueKey('qa.setup.about.bio_field'),
          controller: bioController,
          maxLength: ValidationConstants.maxBioLength,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          enabled: !isSaving,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
          decoration:
              glassInputDecoration(
                context,
                hint:
                    'Tell people about you (min ${ValidationConstants.minBioLength} chars)',
              ).copyWith(
                counterStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
        ),
      ),

      const SizedBox(height: 20),
      setupSectionDivider(context),
      const SizedBox(height: 20),

      // -- Height
      setupFormLabel(context, 'Height (cm)', Icons.height_rounded),
      const SizedBox(height: 8),
      Semantics(
        label: 'qa.setup.about.height_dropdown',
        button: true,
        child: GlassDropdown<int>(
          key: const ValueKey('qa.setup.about.height_dropdown'),
          hint: 'Select height',
          value: height,
          enabled: !isSaving,
          items: List.generate(
            ValidationConstants.maxHeightCm -
                ValidationConstants.minHeightCm +
                1,
            (i) => ValidationConstants.minHeightCm + i,
          ),
          labelBuilder: (v) => '$v cm',
          onChanged: onHeightChanged,
        ),
      ),

      const SizedBox(height: 20),

      // -- Education
      setupFormLabel(context, 'Education', Icons.school_rounded),
      const SizedBox(height: 8),
      Semantics(
        label: 'qa.setup.about.education_dropdown',
        button: true,
        child: GlassDropdown<String>(
          key: const ValueKey('qa.setup.about.education_dropdown'),
          hint: 'Select education',
          value: education,
          enabled: !isSaving,
          items: ProfileOptionsConstants.educationLevels,
          labelBuilder: (v) => v,
          onChanged: onEducationChanged,
        ),
      ),

      const SizedBox(height: 20),

      // -- Profession
      setupFormLabel(context, 'Profession', Icons.work_outline_rounded),
      const SizedBox(height: 8),
      Semantics(
        label: 'qa.setup.about.profession_field',
        textField: true,
        child: TextField(
          key: const ValueKey('qa.setup.about.profession_field'),
          controller: professionController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          enabled: !isSaving,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: glassInputDecoration(
            context,
            hint: 'e.g. Software Engineer',
          ),
        ),
      ),

      const SizedBox(height: 20),

      // -- Income
      setupFormLabel(context, 'Income (optional)', Icons.attach_money_rounded),
      const SizedBox(height: 8),
      GlassDropdown<String>(
        hint: 'Prefer not to say',
        value: income,
        enabled: !isSaving,
        items: ProfileOptionsConstants.incomeRanges,
        labelBuilder: (v) => v,
        onChanged: onIncomeChanged,
      ),

      const SizedBox(height: 24),
      setupSectionDivider(context),
      const SizedBox(height: 20),

      // -- Lifestyle section
      Text(
        'Lifestyle',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 16),

      // -- Drinking
      setupFormLabel(context, 'Drinking', Icons.local_bar_rounded),
      const SizedBox(height: 8),
      Semantics(
        label: 'qa.setup.about.drinking_dropdown',
        button: true,
        child: GlassDropdown<String>(
          key: const ValueKey('qa.setup.about.drinking_dropdown'),
          hint: 'Select',
          value: drinking,
          enabled: !isSaving,
          items: ProfileOptionsConstants.drinkingOptions,
          labelBuilder: (v) => v,
          onChanged: onDrinkingChanged,
        ),
      ),

      const SizedBox(height: 20),

      // -- Smoking
      setupFormLabel(context, 'Smoking', Icons.smoking_rooms_rounded),
      const SizedBox(height: 8),
      Semantics(
        label: 'qa.setup.about.smoking_dropdown',
        button: true,
        child: GlassDropdown<String>(
          key: const ValueKey('qa.setup.about.smoking_dropdown'),
          hint: 'Select',
          value: smoking,
          enabled: !isSaving,
          items: ProfileOptionsConstants.smokingOptions,
          labelBuilder: (v) => v,
          onChanged: onSmokingChanged,
        ),
      ),

      const SizedBox(height: 20),

      // -- Religion
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

      // -- Next
      SizedBox(
        width: double.infinity,
        height: 54,
        child: Semantics(
          label: isSetupFlow
              ? 'qa.setup.about.continue_button'
              : 'qa.setup.about.save_button',
          button: true,
          child: GlassButton(
            key: ValueKey<String>(
              isSetupFlow
                  ? 'qa.setup.about.continue_button'
                  : 'qa.setup.about.save_button',
            ),
            label: isSetupFlow ? 'Continue' : 'Save About',
            icon: isSetupFlow
                ? Icons.arrow_forward_rounded
                : Icons.save_outlined,
            shinyEffect: isSetupFlow,
            isLoading: isSaving,
            onPressed: isSaving ? null : onSave,
          ),
        ),
      ),
    ],
  );
}
