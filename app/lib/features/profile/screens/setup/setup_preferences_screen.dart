import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../../common/screens/main_navigation_screen.dart';
import '../../providers/preference_master_data_provider.dart';
import '../../providers/profile_completion_provider.dart';
import '../../providers/profile_setup_provider.dart';

class SetupPreferencesScreen extends ConsumerStatefulWidget {
  const SetupPreferencesScreen({super.key, this.isSetupFlow});

  final bool? isSetupFlow;

  @override
  ConsumerState<SetupPreferencesScreen> createState() =>
      _SetupPreferencesScreenState();
}

class _SetupPreferencesScreenState
    extends ConsumerState<SetupPreferencesScreen> {
  RangeValues _age = const RangeValues(18, 60);
  double _distance = 50;
  bool _seriousOnly = true;
  bool _verifiedOnly = false;
  bool _hookupOnly = false;
  final _seeking = <String>{'M', 'F'};
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

  bool get _isSetupFlow => widget.isSetupFlow ?? false;

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final offlineFlag = ref.watch(preferenceMasterDataOfflineProvider);
    final isOffline = offlineFlag == true;
    final draftAsync = ref.watch(profileSetupNotifierProvider);
    final masterData = ref
        .watch(preferenceMasterDataProvider)
        .maybeWhen(data: (data) => data, orElse: PreferenceMasterData.empty);

    return draftAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileSetupNotifierProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (draft) {
        if (!_didInitialize) {
          _age = RangeValues(
            draft.minAgeYears.toDouble(),
            draft.maxAgeYears.toDouble(),
          );
          _distance = draft.maxDistanceKm.toDouble();
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

        return Scaffold(
          appBar: AppBar(title: const Text('Preferences')),
          body: Column(
            children: [
              if (isOffline)
                Container(
                  width: double.infinity,
                  color: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: const SafeArea(
                    bottom: false,
                    child: Text(
                      'Offline mode: Some data may be outdated.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.bgGradient,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppTheme.contentMaxWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GlassContainer(
                            key: const ValueKey('preferences_glass_container'),
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.95,
                            ),
                            blur: 10,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(24),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) => SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Seeking',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          FilterChip(
                                            label: const Text('Men'),
                                            selected: _seeking.contains('M'),
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  _seeking.add('M');
                                                } else {
                                                  _seeking.remove('M');
                                                }
                                              });
                                            },
                                          ),
                                          FilterChip(
                                            label: const Text('Women'),
                                            selected: _seeking.contains('F'),
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  _seeking.add('F');
                                                } else {
                                                  _seeking.remove('F');
                                                }
                                              });
                                            },
                                          ),
                                          FilterChip(
                                            label: const Text('Other'),
                                            selected: _seeking.contains(
                                              'Other',
                                            ),
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  _seeking.add('Other');
                                                } else {
                                                  _seeking.remove('Other');
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Age range: ${_age.start.round()} - ${_age.end.round()}',
                                      ),
                                      RangeSlider(
                                        values: _age,
                                        min: 18,
                                        max: 60,
                                        divisions: 42,
                                        onChanged: (v) =>
                                            setState(() => _age = v),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Distance: ${_distance.round()} km'),
                                      Slider(
                                        value: _distance,
                                        min: 1,
                                        max: 200,
                                        divisions: 199,
                                        onChanged: (v) =>
                                            setState(() => _distance = v),
                                      ),
                                      const SizedBox(height: 16),
                                      SwitchListTile(
                                        title: const Text(
                                          'Serious relationship only',
                                        ),
                                        value: _seriousOnly,
                                        onChanged: (value) {
                                          setState(() {
                                            _seriousOnly = value;
                                          });
                                        },
                                      ),
                                      SwitchListTile(
                                        title: const Text(
                                          'Verified profiles only',
                                        ),
                                        value: _verifiedOnly,
                                        onChanged: (value) {
                                          setState(() {
                                            _verifiedOnly = value;
                                          });
                                        },
                                      ),
                                      SwitchListTile(
                                        title: const Text('Hookups only'),
                                        value: _hookupOnly,
                                        onChanged: (value) {
                                          setState(() {
                                            _hookupOnly = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Advanced Bio & Tag Filters',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedCountry,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Country',
                                        ),
                                        items: masterData.countries
                                            .map(
                                              (value) =>
                                                  DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(value),
                                                  ),
                                            )
                                            .toList(growable: false),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedCountry = value;
                                            _selectedState = null;
                                            _selectedCity = null;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedState,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'State',
                                        ),
                                        items:
                                            (masterData.statesByCountry[_selectedCountry] ??
                                                    const <String>[])
                                                .map(
                                                  (value) =>
                                                      DropdownMenuItem<String>(
                                                        value: value,
                                                        child: Text(value),
                                                      ),
                                                )
                                                .toList(growable: false),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedState = value;
                                            _selectedCity = null;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(
                                        builder: (context) {
                                          final cityOptions =
                                              masterData
                                                  .citiesByState[_selectedState] ??
                                              const <String>[];
                                          final cityInitial =
                                              cityOptions.contains(
                                                _selectedCity,
                                              )
                                              ? _selectedCity
                                              : null;

                                          return DropdownButtonFormField<
                                            String
                                          >(
                                            initialValue: cityInitial,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'City',
                                            ),
                                            items: cityOptions
                                                .map(
                                                  (value) =>
                                                      DropdownMenuItem<String>(
                                                        value: value,
                                                        child: Text(value),
                                                      ),
                                                )
                                                .toList(growable: false),
                                            onChanged: (value) => setState(
                                              () => _selectedCity = value,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedReligion,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Religion preference',
                                        ),
                                        items: masterData.religions
                                            .map(
                                              (value) =>
                                                  DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(value),
                                                  ),
                                            )
                                            .toList(growable: false),
                                        onChanged: (value) => setState(
                                          () => _selectedReligion = value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedMotherTongue,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Mother tongue preference',
                                        ),
                                        items: masterData.motherTongues
                                            .map(
                                              (value) =>
                                                  DropdownMenuItem<String>(
                                                    value: value,
                                                    child: Text(value),
                                                  ),
                                            )
                                            .toList(growable: false),
                                        onChanged: (value) => setState(
                                          () => _selectedMotherTongue = value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _instagramController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Instagram handle (without @)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _booksController,
                                        decoration: const InputDecoration(
                                          labelText: 'Books (comma-separated)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _novelsController,
                                        decoration: const InputDecoration(
                                          labelText: 'Novels (comma-separated)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _songsController,
                                        decoration: const InputDecoration(
                                          labelText: 'Songs (comma-separated)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _hobbiesController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Hobbies (comma-separated tags)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _extraCurricularController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Extra-curricular activities (comma-separated)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _additionalInfoController,
                                        minLines: 3,
                                        maxLines: 5,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Extra information to share',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _intentTagsController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Intent tags (long-term, marriage, casual, new friends)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDropdown(
                                        label: 'Language',
                                        value: _selectedLanguage,
                                        options: masterData.languages,
                                        onChanged: (value) => setState(
                                          () => _selectedLanguage = value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _petPreferenceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Pet preference',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDropdown(
                                        label: 'Diet preference',
                                        value: _selectedDietPreference,
                                        options: masterData.dietPreferences,
                                        onChanged: (value) => setState(
                                          () => _selectedDietPreference = value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDropdown(
                                        label: 'Workout frequency',
                                        value: _selectedWorkoutFrequency,
                                        options: masterData.workoutFrequencies,
                                        onChanged: (value) => setState(
                                          () =>
                                              _selectedWorkoutFrequency = value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDropdown(
                                        label: 'Diet type',
                                        value: _selectedDietType,
                                        options: masterData.dietTypes,
                                        onChanged: (value) => setState(
                                          () => _selectedDietType = value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDropdown(
                                        label: 'Sleep schedule',
                                        value: _selectedSleepSchedule,
                                        options: masterData.sleepSchedules,
                                        onChanged: (value) => setState(
                                          () => _selectedSleepSchedule = value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDropdown(
                                        label: 'Travel style',
                                        value: _selectedTravelStyle,
                                        options: masterData.travelStyles,
                                        onChanged: (value) => setState(
                                          () => _selectedTravelStyle = value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDropdown(
                                        label: 'Political comfort range',
                                        value: _selectedPoliticalComfortRange,
                                        options:
                                            masterData.politicalComfortRanges,
                                        onChanged: (value) => setState(
                                          () => _selectedPoliticalComfortRange =
                                              value,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _dealBreakerTagsController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Deal-breaker tags (comma-separated)',
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      GlassButton(
                                        label: _isSetupFlow ? 'Finish' : 'Save',
                                        onPressed: () =>
                                            _handlePrimaryAction(draft),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePrimaryAction(ProfileDraft draft) async {
    if (_seeking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one gender preference.')),
      );
      return;
    }

    await _savePreferencesAndLifestyle(draft);

    if (_isSetupFlow) {
      try {
        await ref.read(profileSetupNotifierProvider.notifier).completeProfile();
        ref.invalidate(profileCompletionProvider);
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete all required fields (minimum photos, bio, and basic info).',
            ),
          ),
        );
        return;
      }
    }

    _navigateToDiscover();
  }

  Future<void> _savePreferencesAndLifestyle(ProfileDraft draft) async {
    await ref
        .read(profileSetupNotifierProvider.notifier)
        .savePreferences(
          seekingGenders: _seeking.toList(),
          minAgeYears: _age.start.round(),
          maxAgeYears: _age.end.round(),
          maxDistanceKm: _distance.round(),
          educationFilter: const [],
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

  void _navigateToDiscover() {
    ref.read(mainNavigationIndexProvider.notifier).state = 0;
    if (!mounted) {
      return;
    }
    if (_isSetupFlow) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    Navigator.of(context).pop();
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final resolvedValue = options.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: resolvedValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
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
}
