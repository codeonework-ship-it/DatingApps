import '../../../swipe/providers/curated_daily_set_provider.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/platform/browser_context.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/preference_limits.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/glass_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../common/screens/main_navigation_screen.dart';
import '../../providers/preference_master_data_provider.dart';
import '../../providers/profile_completion_provider.dart';
import '../../providers/profile_setup_provider.dart';
import '../../../swipe/providers/swipe_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SetupPreferencesScreen — two-tab Crystal Gold glass UI (Basic | Advanced)
//
// Dual-mode screen:
//   • isSetupFlow == true  → completes profile, navigates to Discover
//   • isSetupFlow == false → saves & pops (standalone edit from settings)
// ─────────────────────────────────────────────────────────────────────────────

class SetupPreferencesScreen extends ConsumerStatefulWidget {
  const SetupPreferencesScreen({super.key, this.isSetupFlow});

  final bool? isSetupFlow;

  @override
  ConsumerState<SetupPreferencesScreen> createState() =>
      _SetupPreferencesScreenState();
}

class _SetupPreferencesScreenState extends ConsumerState<SetupPreferencesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Basic tab state ────────────────────────────────────────────────────────
  RangeValues _age = const RangeValues(18, 60);
  double _distance = 50;
  bool _seriousOnly = true;
  bool _verifiedOnly = false;
  bool _hookupOnly = false;
  final _seeking = <String>{'M', 'F'};

  // ── Advanced tab state ─────────────────────────────────────────────────────
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  String? _selectedReligion;
  String? _selectedMotherTongue;
  String? _selectedLanguage;
  String? _selectedDietPreference;
  String? _selectedWorkoutFrequency;
  String? _selectedDietType;
  String? _selectedSleepSchedule;
  String? _selectedTravelStyle;
  String? _selectedPoliticalComfortRange;
  final _instagramController = TextEditingController();
  final _booksController = TextEditingController();
  final _novelsController = TextEditingController();
  final _songsController = TextEditingController();
  final _hobbiesController = TextEditingController();
  final _extraCurricularController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _intentTagsController = TextEditingController();
  final _petPreferenceController = TextEditingController();
  final _dealBreakerTagsController = TextEditingController();

  var _didInitialize = false;
  var _isSaving = false;

  bool get _isSetupFlow => widget.isSetupFlow ?? false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _instagramController.dispose();
    _booksController.dispose();
    _novelsController.dispose();
    _songsController.dispose();
    _hobbiesController.dispose();
    _extraCurricularController.dispose();
    _additionalInfoController.dispose();
    _intentTagsController.dispose();
    _petPreferenceController.dispose();
    _dealBreakerTagsController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final offlineFlag = ref.watch(preferenceMasterDataOfflineProvider);
    final isOffline = offlineFlag == true;
    final draftAsync = ref.watch(profileSetupNotifierProvider);
    final masterDataAsync = ref.watch(preferenceMasterDataProvider);
    final masterData = masterDataAsync.maybeWhen(
      data: (data) => data,
      orElse: PreferenceMasterData.localFallback,
    );

    return draftAsync.when(
      loading: () => Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      error: (_, _) => Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(
                    context,
                  ).profileSetupPreferencesLoadFailed,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                GlassButton(
                  label: AppLocalizations.of(context).profileSetupRetry,
                  onPressed: () => ref.invalidate(profileSetupNotifierProvider),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (draft) {
        _initializeState(draft, masterData);
        return _buildBody(draft, masterData, isOffline);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initialize state from draft (once)
  // ─────────────────────────────────────────────────────────────────────────

  void _initializeState(ProfileDraft draft, PreferenceMasterData masterData) {
    if (_didInitialize) {
      return;
    }
    final lowerAge = draft.minAgeYears
        .clamp(PreferenceLimits.minAge, PreferenceLimits.maxAge)
        .toDouble();
    final upperAge = draft.maxAgeYears
        .clamp(PreferenceLimits.minAge, PreferenceLimits.maxAge)
        .toDouble();
    _age = RangeValues(
      lowerAge <= upperAge ? lowerAge : upperAge,
      upperAge >= lowerAge ? upperAge : lowerAge,
    );
    _distance = draft.maxDistanceKm
        .clamp(PreferenceLimits.minDistanceKm, PreferenceLimits.maxDistanceKm)
        .toDouble();
    _seriousOnly = draft.seriousOnly;
    _verifiedOnly = draft.verifiedOnly;
    _hookupOnly = draft.hookupOnly;
    _seeking
      ..clear()
      ..addAll(draft.seekingGenders);

    final defaultCountry = masterData.countries.isNotEmpty
        ? masterData.countries.first
        : null;
    _selectedCountry = draft.country ?? defaultCountry;
    final states =
        masterData.statesByCountry[_selectedCountry] ?? const <String>[];
    _selectedState = states.contains(draft.regionState)
        ? draft.regionState
        : null;
    final seededCities =
        masterData.citiesByState[_selectedState] ?? const <String>[];
    _selectedCity = seededCities.contains(draft.city) ? draft.city : null;
    _selectedReligion = masterData.religions.contains(draft.religion)
        ? draft.religion
        : null;
    _selectedMotherTongue =
        masterData.motherTongues.contains(draft.motherTongue)
        ? draft.motherTongue
        : null;
    _selectedLanguage = draft.languageTags.isNotEmpty
        ? draft.languageTags.first
        : null;
    _selectedDietPreference = draft.dietPreference;
    _selectedWorkoutFrequency = draft.workoutFrequency;
    _selectedDietType = draft.dietType;
    _selectedSleepSchedule = draft.sleepSchedule;
    _selectedTravelStyle = draft.travelStyle;
    _selectedPoliticalComfortRange = draft.politicalComfortRange;
    _instagramController.text = draft.instagramHandle ?? '';
    _booksController.text = draft.favoriteBooks.join(', ');
    _novelsController.text = draft.favoriteNovels.join(', ');
    _songsController.text = draft.favoriteSongs.join(', ');
    _hobbiesController.text = draft.hobbies.join(', ');
    _extraCurricularController.text = draft.extraCurriculars.join(', ');
    _additionalInfoController.text = draft.additionalInfo ?? '';
    _intentTagsController.text = draft.intentTags.join(', ');
    _petPreferenceController.text = draft.petPreference ?? '';
    _dealBreakerTagsController.text = draft.dealBreakerTags.join(', ');
    _didInitialize = true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main body scaffold
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBody(
    ProfileDraft draft,
    PreferenceMasterData masterData,
    bool isOffline,
  ) => Scaffold(
    body: Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── offline banner ─────────────────────────────────────────
            if (isOffline)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  AppLocalizations.of(context).profileSetupOfflineBanner,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // ── header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: _isSaving
                        ? null
                        : () => _handleBackFromPreferences(draft),
                  ),
                  Expanded(
                    child: Text(
                      _isSetupFlow
                          ? AppLocalizations.of(
                              context,
                            ).profileSetupYourPreferences
                          : AppLocalizations.of(
                              context,
                            ).profileSetupEditPreferencesTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── glass tab bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _GlassTabBar(controller: _tabController),
            ),

            const SizedBox(height: 12),

            // ── tab content ────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BasicTab(
                    age: _age,
                    distance: _distance,
                    seeking: _seeking,
                    seriousOnly: _seriousOnly,
                    verifiedOnly: _verifiedOnly,
                    hookupOnly: _hookupOnly,
                    onAgeChanged: (v) => setState(() => _age = v),
                    onDistanceChanged: (v) => setState(() => _distance = v),
                    onSeekingToggled: (code, {required selected}) =>
                        setState(() {
                          if (selected) {
                            _seeking.add(code);
                          } else {
                            _seeking.remove(code);
                          }
                        }),
                    onSeriousChanged: (v) => setState(() => _seriousOnly = v),
                    onVerifiedChanged: (v) => setState(() => _verifiedOnly = v),
                    onHookupChanged: (v) => setState(() => _hookupOnly = v),
                  ),
                  _AdvancedTab(
                    masterData: masterData,
                    selectedCountry: _selectedCountry,
                    selectedState: _selectedState,
                    selectedCity: _selectedCity,
                    selectedReligion: _selectedReligion,
                    selectedMotherTongue: _selectedMotherTongue,
                    selectedLanguage: _selectedLanguage,
                    selectedDietPreference: _selectedDietPreference,
                    selectedWorkoutFrequency: _selectedWorkoutFrequency,
                    selectedDietType: _selectedDietType,
                    selectedSleepSchedule: _selectedSleepSchedule,
                    selectedTravelStyle: _selectedTravelStyle,
                    selectedPoliticalComfortRange:
                        _selectedPoliticalComfortRange,
                    instagramController: _instagramController,
                    booksController: _booksController,
                    novelsController: _novelsController,
                    songsController: _songsController,
                    hobbiesController: _hobbiesController,
                    extraCurricularController: _extraCurricularController,
                    additionalInfoController: _additionalInfoController,
                    intentTagsController: _intentTagsController,
                    petPreferenceController: _petPreferenceController,
                    dealBreakerTagsController: _dealBreakerTagsController,
                    onCountryChanged: (v) => setState(() {
                      _selectedCountry = v;
                      _selectedState = null;
                      _selectedCity = null;
                    }),
                    onStateChanged: (v) => setState(() {
                      _selectedState = v;
                      _selectedCity = null;
                    }),
                    onCityChanged: (v) => setState(() => _selectedCity = v),
                    onReligionChanged: (v) =>
                        setState(() => _selectedReligion = v),
                    onMotherTongueChanged: (v) =>
                        setState(() => _selectedMotherTongue = v),
                    onLanguageChanged: (v) =>
                        setState(() => _selectedLanguage = v),
                    onDietPreferenceChanged: (v) =>
                        setState(() => _selectedDietPreference = v),
                    onWorkoutFrequencyChanged: (v) =>
                        setState(() => _selectedWorkoutFrequency = v),
                    onDietTypeChanged: (v) =>
                        setState(() => _selectedDietType = v),
                    onSleepScheduleChanged: (v) =>
                        setState(() => _selectedSleepSchedule = v),
                    onTravelStyleChanged: (v) =>
                        setState(() => _selectedTravelStyle = v),
                    onPoliticalComfortRangeChanged: (v) =>
                        setState(() => _selectedPoliticalComfortRange = v),
                  ),
                ],
              ),
            ),

            // ── save button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Semantics(
                label: _isSetupFlow
                    ? 'qa.setup.preferences.finish_button'
                    : 'qa.setup.preferences.save_button',
                button: true,
                child: GlassButton(
                  key: ValueKey<String>(
                    _isSetupFlow
                        ? 'qa.setup.preferences.finish_button'
                        : 'qa.setup.preferences.save_button',
                  ),
                  label: _isSetupFlow
                      ? AppLocalizations.of(
                          context,
                        ).profileSetupFinishAndFindMatches
                      : AppLocalizations.of(
                          context,
                        ).profileSetupSavePreferences,
                  shinyEffect: _isSetupFlow,
                  isLoading: _isSaving,
                  onPressed: _isSaving
                      ? null
                      : () => _handlePrimaryAction(draft),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Save + navigate
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handlePrimaryAction(ProfileDraft draft) async {
    if (_seeking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).profileSetupSelectGenderPreference,
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _savePreferencesAndLifestyle(draft);

      if (_isSetupFlow) {
        await ref.read(profileSetupNotifierProvider.notifier).completeProfile();
        ref.invalidate(profileCompletionProvider);
      }

      _navigateAfterSave();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSetupFlow
                  ? AppLocalizations.of(context).profileSetupFinishFailed
                  : AppLocalizations.of(
                      context,
                    ).profileSetupPreferencesSaveFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleBackFromPreferences(ProfileDraft draft) async {
    if (_isSetupFlow) {
      setState(() => _isSaving = true);
      try {
        await _savePreferencesAndLifestyle(draft);
      } on Exception {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).profileSetupCouldNotSaveChanges,
              ),
            ),
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
    if (mounted) {
      if (kIsWeb && !Navigator.of(context).canPop()) {
        setWebRoute('/discover');
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _savePreferencesAndLifestyle(ProfileDraft draft) async {
    await ref
        .read(profileSetupNotifierProvider.notifier)
        .savePreferences(
          seekingGenders: _seeking.toList(),
          minAgeYears: _age.start.round(),
          maxAgeYears: _age.end.round(),
          maxDistanceKm: _distance.round(),
          educationFilter: draft.educationFilter,
          seriousOnly: _seriousOnly,
          verifiedOnly: _verifiedOnly,
          country: _selectedCountry,
          regionState: _selectedState,
          city: _selectedCity,
          instagramHandle: _nullableTrim(_instagramController.text),
          hobbies: _parseTags(_hobbiesController.text),
          favoriteBooks: _parseTags(_booksController.text),
          favoriteNovels: _parseTags(_novelsController.text),
          favoriteSongs: _parseTags(_songsController.text),
          extraCurriculars: _parseTags(_extraCurricularController.text),
          additionalInfo: _nullableTrim(_additionalInfoController.text),
          intentTags: _parseTags(_intentTagsController.text),
          languageTags: _selectedLanguage == null
              ? const <String>[]
              : draft.languageTags.isNotEmpty &&
                    _selectedLanguage == draft.languageTags.first
              ? draft.languageTags
              : <String>[_selectedLanguage!],
          petPreference: _nullableTrim(_petPreferenceController.text),
          workoutFrequency: _selectedWorkoutFrequency,
          dietType: _selectedDietType,
          sleepSchedule: _selectedSleepSchedule,
          travelStyle: _selectedTravelStyle,
          politicalComfortRange: _selectedPoliticalComfortRange,
          dealBreakerTags: _parseTags(_dealBreakerTagsController.text),
          motherTongue: _selectedMotherTongue,
          hookupOnly: _hookupOnly,
          dietPreference: _selectedDietPreference,
        );

    await ref
        .read(profileSetupNotifierProvider.notifier)
        .saveLifestyle(
          drinking: draft.drinking,
          smoking: draft.smoking,
          religion: _selectedReligion,
        );
  }

  void _navigateAfterSave() {
    ref.invalidate(swipeNotifierProvider);
    ref.invalidate(curatedDailySetProvider);
    if (!mounted) {
      return;
    }
    if (kIsWeb && !_isSetupFlow && !Navigator.of(context).canPop()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).profileSetupPreferencesSaved,
          ),
        ),
      );
      return;
    }
    if (_isSetupFlow) {
      ref.read(mainNavigationIndexProvider.notifier).state = 0;
      if (kIsWeb) {
        setWebRoute('/discover');
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ref.read(mainNavigationIndexProvider.notifier).state = 0;
      Navigator.of(context).pop();
    }
  }

  String? _nullableTrim(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  List<String> _parseTags(String raw) => raw
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

// ─────────────────────────────────────────────────────────────────────────────
// _GlassTabBar
// ─────────────────────────────────────────────────────────────────────────────

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary),
        ),
        labelColor: scheme.onPrimaryContainer,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
        tabs: [
          Tab(text: AppLocalizations.of(context).profileSetupTabBasic),
          Tab(text: AppLocalizations.of(context).profileSetupTabAdvanced),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BasicTab
// ─────────────────────────────────────────────────────────────────────────────

class _BasicTab extends StatelessWidget {
  const _BasicTab({
    required this.age,
    required this.distance,
    required this.seeking,
    required this.seriousOnly,
    required this.verifiedOnly,
    required this.hookupOnly,
    required this.onAgeChanged,
    required this.onDistanceChanged,
    required this.onSeekingToggled,
    required this.onSeriousChanged,
    required this.onVerifiedChanged,
    required this.onHookupChanged,
  });

  final RangeValues age;
  final double distance;
  final Set<String> seeking;
  final bool seriousOnly;
  final bool verifiedOnly;
  final bool hookupOnly;
  final ValueChanged<RangeValues> onAgeChanged;
  final ValueChanged<double> onDistanceChanged;
  final void Function(String code, {required bool selected}) onSeekingToggled;
  final ValueChanged<bool> onSeriousChanged;
  final ValueChanged<bool> onVerifiedChanged;
  final ValueChanged<bool> onHookupChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── I'm looking for ───────────────────────────────────────────
          _PrefCard(
            icon: Icons.favorite_outline,
            title: l10n.profileSetupLookingFor,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GenderChip(
                  label: l10n.profileSetupSeekingMen,
                  code: 'M',
                  icon: Icons.male,
                  selected: seeking.contains('M'),
                  onToggled: onSeekingToggled,
                ),
                _GenderChip(
                  label: l10n.profileSetupSeekingWomen,
                  code: 'F',
                  icon: Icons.female,
                  selected: seeking.contains('F'),
                  onToggled: onSeekingToggled,
                ),
                _GenderChip(
                  label: l10n.profileSetupSeekingOther,
                  code: 'Other',
                  icon: Icons.transgender,
                  selected: seeking.contains('Other'),
                  onToggled: onSeekingToggled,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Age range ─────────────────────────────────────────────────
          _PrefCard(
            icon: Icons.cake_outlined,
            title: l10n.profileSetupAgeRangeTitle(
              age.start.round(),
              age.end.round(),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Theme.of(context).colorScheme.primary,
                thumbColor: Theme.of(context).colorScheme.primary,
                overlayColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                inactiveTrackColor: Theme.of(
                  context,
                ).colorScheme.outlineVariant,
              ),
              child: RangeSlider(
                values: age,
                min: PreferenceLimits.minAge,
                max: PreferenceLimits.maxAge,
                divisions: PreferenceLimits.ageDivisions,
                labels: RangeLabels(
                  age.start.round().toString(),
                  age.end.round().toString(),
                ),
                onChanged: onAgeChanged,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Max distance ──────────────────────────────────────────────
          _PrefCard(
            icon: Icons.location_on_outlined,
            title: l10n.profileSetupMaxDistanceTitle(distance.round()),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Theme.of(context).colorScheme.primary,
                thumbColor: Theme.of(context).colorScheme.primary,
                overlayColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                inactiveTrackColor: Theme.of(
                  context,
                ).colorScheme.outlineVariant,
              ),
              child: Slider(
                value: distance,
                min: PreferenceLimits.minDistanceKm,
                max: PreferenceLimits.maxDistanceKm,
                divisions: PreferenceLimits.distanceDivisions,
                label: l10n.profileSetupDistanceValue(distance.round()),
                onChanged: onDistanceChanged,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Intent toggles ────────────────────────────────────────────
          _PrefCard(
            icon: Icons.tune_outlined,
            title: l10n.profileSetupRelationshipIntent,
            child: Column(
              children: [
                _ToggleTile(
                  label: l10n.profileSetupSeriousOnly,
                  semanticLabel: 'qa.setup.preferences.serious_only_toggle',
                  subtitle: l10n.profileSetupSeriousOnlySubtitle,
                  value: seriousOnly,
                  onChanged: onSeriousChanged,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                  indent: 4,
                  endIndent: 4,
                ),
                _ToggleTile(
                  label: l10n.profileSetupVerifiedOnly,
                  semanticLabel: 'qa.setup.preferences.verified_only_toggle',
                  subtitle: l10n.profileSetupVerifiedOnlySubtitle,
                  value: verifiedOnly,
                  onChanged: onVerifiedChanged,
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                  indent: 4,
                  endIndent: 4,
                ),
                _ToggleTile(
                  label: l10n.profileSetupHookupsOnly,
                  semanticLabel: 'qa.setup.preferences.hookup_only_toggle',
                  subtitle: l10n.profileSetupHookupsOnlySubtitle,
                  value: hookupOnly,
                  onChanged: onHookupChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdvancedTab
// ─────────────────────────────────────────────────────────────────────────────

class _AdvancedTab extends StatelessWidget {
  const _AdvancedTab({
    required this.masterData,
    required this.selectedCountry,
    required this.selectedState,
    required this.selectedCity,
    required this.selectedReligion,
    required this.selectedMotherTongue,
    required this.selectedLanguage,
    required this.selectedDietPreference,
    required this.selectedWorkoutFrequency,
    required this.selectedDietType,
    required this.selectedSleepSchedule,
    required this.selectedTravelStyle,
    required this.selectedPoliticalComfortRange,
    required this.instagramController,
    required this.booksController,
    required this.novelsController,
    required this.songsController,
    required this.hobbiesController,
    required this.extraCurricularController,
    required this.additionalInfoController,
    required this.intentTagsController,
    required this.petPreferenceController,
    required this.dealBreakerTagsController,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onCityChanged,
    required this.onReligionChanged,
    required this.onMotherTongueChanged,
    required this.onLanguageChanged,
    required this.onDietPreferenceChanged,
    required this.onWorkoutFrequencyChanged,
    required this.onDietTypeChanged,
    required this.onSleepScheduleChanged,
    required this.onTravelStyleChanged,
    required this.onPoliticalComfortRangeChanged,
  });

  final PreferenceMasterData masterData;
  final String? selectedCountry;
  final String? selectedState;
  final String? selectedCity;
  final String? selectedReligion;
  final String? selectedMotherTongue;
  final String? selectedLanguage;
  final String? selectedDietPreference;
  final String? selectedWorkoutFrequency;
  final String? selectedDietType;
  final String? selectedSleepSchedule;
  final String? selectedTravelStyle;
  final String? selectedPoliticalComfortRange;
  final TextEditingController instagramController;
  final TextEditingController booksController;
  final TextEditingController novelsController;
  final TextEditingController songsController;
  final TextEditingController hobbiesController;
  final TextEditingController extraCurricularController;
  final TextEditingController additionalInfoController;
  final TextEditingController intentTagsController;
  final TextEditingController petPreferenceController;
  final TextEditingController dealBreakerTagsController;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onReligionChanged;
  final ValueChanged<String?> onMotherTongueChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onDietPreferenceChanged;
  final ValueChanged<String?> onWorkoutFrequencyChanged;
  final ValueChanged<String?> onDietTypeChanged;
  final ValueChanged<String?> onSleepScheduleChanged;
  final ValueChanged<String?> onTravelStyleChanged;
  final ValueChanged<String?> onPoliticalComfortRangeChanged;

  static InputDecoration _fieldDecor(ColorScheme scheme, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        filled: true,
        fillColor: scheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      );

  Widget _dropdown({
    required ColorScheme scheme,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final resolvedValue = options.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: resolvedValue,
      isExpanded: true,
      dropdownColor: scheme.surface,
      iconEnabledColor: scheme.primary,
      decoration: _fieldDecor(scheme, label),
      style: TextStyle(color: scheme.onSurface, fontSize: 14),
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final states =
        masterData.statesByCountry[selectedCountry] ?? const <String>[];
    final cities = masterData.citiesByState[selectedState] ?? const <String>[];
    final resolvedCity = cities.contains(selectedCity) ? selectedCity : null;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Location ──────────────────────────────────────────────────
          _PrefCard(
            icon: Icons.public_outlined,
            title: l10n.profileSetupLocation,
            child: Column(
              children: [
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupCountry,
                  value: selectedCountry,
                  options: masterData.countries,
                  onChanged: onCountryChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupStateRegion,
                  value: states.contains(selectedState) ? selectedState : null,
                  options: states,
                  onChanged: onStateChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupCity,
                  value: resolvedCity,
                  options: cities,
                  onChanged: onCityChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Background & culture ──────────────────────────────────────
          _PrefCard(
            icon: Icons.diversity_3_outlined,
            title: l10n.profileSetupBackgroundCulture,
            child: Column(
              children: [
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupReligionPreference,
                  value: selectedReligion,
                  options: masterData.religions,
                  onChanged: onReligionChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupMotherTongue,
                  value: selectedMotherTongue,
                  options: masterData.motherTongues,
                  onChanged: onMotherTongueChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupLanguage,
                  value: selectedLanguage,
                  options: masterData.languages,
                  onChanged: onLanguageChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Lifestyle ─────────────────────────────────────────────────
          _PrefCard(
            icon: Icons.self_improvement_outlined,
            title: l10n.profileSetupLifestyleTitle,
            child: Column(
              children: [
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupDietPreference,
                  value: selectedDietPreference,
                  options: masterData.dietPreferences,
                  onChanged: onDietPreferenceChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupWorkoutFrequency,
                  value: selectedWorkoutFrequency,
                  options: masterData.workoutFrequencies,
                  onChanged: onWorkoutFrequencyChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupDietType,
                  value: selectedDietType,
                  options: masterData.dietTypes,
                  onChanged: onDietTypeChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupSleepSchedule,
                  value: selectedSleepSchedule,
                  options: masterData.sleepSchedules,
                  onChanged: onSleepScheduleChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupTravelStyle,
                  value: selectedTravelStyle,
                  options: masterData.travelStyles,
                  onChanged: onTravelStyleChanged,
                ),
                const SizedBox(height: 10),
                _dropdown(
                  scheme: scheme,
                  label: l10n.profileSetupPoliticalComfortRange,
                  value: selectedPoliticalComfortRange,
                  options: masterData.politicalComfortRanges,
                  onChanged: onPoliticalComfortRangeChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Interests & personality ───────────────────────────────────
          _PrefCard(
            icon: Icons.interests_outlined,
            title: l10n.profileSetupInterestsPersonality,
            child: Column(
              children: [
                TextField(
                  controller: instagramController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: _fieldDecor(
                    scheme,
                    l10n.profileSetupInstagramHandle,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: intentTagsController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: _fieldDecor(scheme, l10n.profileSetupIntentTags),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hobbiesController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: _fieldDecor(
                    scheme,
                    l10n.profileSetupHobbiesField,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: booksController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: _fieldDecor(
                    scheme,
                    l10n.profileSetupFavouriteBooksField,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: novelsController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: _fieldDecor(
                    scheme,
                    l10n.profileSetupFavouriteNovelsField,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: songsController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: _fieldDecor(
                    scheme,
                    l10n.profileSetupFavouriteSongsField,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: extraCurricularController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: _fieldDecor(
                    scheme,
                    l10n.profileSetupExtraCurricularField,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: additionalInfoController,
                  style: TextStyle(color: scheme.onSurface),
                  minLines: 2,
                  maxLines: 4,
                  decoration: _fieldDecor(
                    scheme,
                    l10n.profileSetupAdditionalInformation,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: petPreferenceController,
                  style: TextStyle(color: scheme.onSurface),
                  decoration: _fieldDecor(
                    scheme,
                    l10n.profileSetupPetPreference,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Deal-breakers ────────────────────────────────────────────
          _PrefCard(
            icon: Icons.block_outlined,
            title: l10n.profileSetupDealBreakers,
            child: TextField(
              controller: dealBreakerTagsController,
              style: TextStyle(color: scheme.onSurface),
              minLines: 2,
              maxLines: 4,
              decoration: _fieldDecor(scheme, l10n.profileSetupTagsField),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PrefCard — frosted glass section container
// ─────────────────────────────────────────────────────────────────────────────

class _PrefCard extends StatelessWidget {
  const _PrefCard({
    required this.icon,
    required this.title,
    required this.child,
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
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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

// ─────────────────────────────────────────────────────────────────────────────
// _GenderChip — animated gold-border selection chip
// ─────────────────────────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.code,
    required this.icon,
    required this.selected,
    required this.onToggled,
  });

  final String label;
  final String code;
  final IconData icon;
  final bool selected;
  final void Function(String code, {required bool selected}) onToggled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return GestureDetector(
      onTap: () => onToggled(code, selected: !selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 14, color: foreground),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ToggleTile — switch row matching AppTheme gold style
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: semanticLabel ?? label,
            toggled: value,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: scheme.onPrimary,
              activeTrackColor: scheme.primary,
              inactiveThumbColor: scheme.outline,
              inactiveTrackColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
