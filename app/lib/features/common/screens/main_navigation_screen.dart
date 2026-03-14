import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../common/screens/settings_screen.dart';
import '../../engagement/screens/engagement_hub_screen.dart';
import '../../matching/providers/match_provider.dart';
import '../../matching/providers/trust_filter_provider.dart';
import '../../matching/screens/matches_list_screen.dart';
import '../../profile/providers/preference_master_data_provider.dart';
import '../../profile/screens/profile_view_screen.dart';
import '../../profile/screens/setup/setup_preferences_screen.dart';
import '../../swipe/providers/swipe_provider.dart';
import '../../swipe/screens/home_discovery_screen.dart';

final mainNavigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with TickerProviderStateMixin {
  RangeValues _filterAge = const RangeValues(20, 50);
  double _filterDistance = 50;
  bool _filterVerifiedOnly = false;
  String? _filterReligion;
  String? _filterMotherTongue;
  String? _filterCountry;
  String? _filterState;
  String? _filterCity;
  String? _filterRelationshipStatus;
  String? _filterSmoking;
  String? _filterDrinking;
  String? _filterPersonalityType;
  bool _filterPartyLoverOnly = false;
  bool _filterHookupOnly = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(preferenceMasterDataOfflineProvider);
    final selectedIndex = ref.watch(mainNavigationIndexProvider);

    final screens = <Widget>[
      HomeDiscoveryScreen(
        onOpenFilters: () => _openFilterSheet(context),
        onOpenMessages: () => _setSelectedIndex(1),
      ),
      const MatchesListScreen(),
      const EngagementHubScreen(),
      const ProfileViewScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Column(
        children: [
          if (isOffline)
            Container(
              width: double.infinity,
              color: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            child: IndexedStack(
              index: selectedIndex,
              children: screens
                  .map((screen) => SizedBox.expand(child: screen))
                  .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: GlassContainer(
            blur: 12,
            opacity: 0.72,
            padding: EdgeInsets.zero,
            borderRadius: const BorderRadius.all(Radius.circular(22)),
            backgroundColor: Colors.white.withValues(alpha: 0.74),
            child: Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
              child: BottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: _setSelectedIndex,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedItemColor: AppTheme.primaryRed,
                unselectedItemColor: AppTheme.textHint,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Discover',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_rounded),
                    label: 'Matches',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bolt_rounded),
                    label: 'Engagement',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setSelectedIndex(int index) {
    ref.read(mainNavigationIndexProvider.notifier).state = index;
    if (index == 0) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: _buildFilterSheet,
    );
  }

  Widget _buildFilterSheet(BuildContext context) {
    final trustState = ref.watch(trustFilterNotifierProvider);
    final trustNotifier = ref.read(trustFilterNotifierProvider.notifier);
    final masterData = ref
        .watch(preferenceMasterDataProvider)
        .maybeWhen(data: (data) => data, orElse: PreferenceMasterData.empty);
    _filterCountry ??= masterData.countries.isNotEmpty
        ? masterData.countries.first
        : null;
    var trustEnabled = trustState.enabled;
    var minimumActiveBadges = trustState.minimumActiveBadges;
    final requiredBadgeCodes = trustState.requiredBadgeCodes.toSet();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.postLoginGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                blur: AppTheme.glassBlurUltra,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppTheme.trustBlue.withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.trustBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Filter Matches',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StatefulBuilder(
                builder: (context, setSheetState) => ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: Colors.white.withValues(alpha: 0.78),
                      blur: 8,
                      child: _buildFilterSection(
                        context,
                        'Age Range',
                        child: RangeSlider(
                          values: _filterAge,
                          min: 18,
                          max: 70,
                          divisions: 52,
                          labels: RangeLabels(
                            _filterAge.start.round().toString(),
                            _filterAge.end.round().toString(),
                          ),
                          onChanged: (values) =>
                              setState(() => _filterAge = values),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: Colors.white.withValues(alpha: 0.78),
                      blur: 8,
                      child: _buildFilterSection(
                        context,
                        'Profile & Lifestyle Filters',
                        child: Column(
                          children: [
                            _buildDropdownFilterField(
                              label: 'Country',
                              value: _filterCountry,
                              options: masterData.countries,
                              onChanged: (value) => setState(() {
                                _filterCountry = value;
                                _filterState = null;
                                _filterCity = null;
                              }),
                            ),
                            const SizedBox(height: 10),
                            _buildDropdownFilterField(
                              label: 'State',
                              value: _filterState,
                              options:
                                  masterData.statesByCountry[_filterCountry] ??
                                  const <String>[],
                              onChanged: (value) => setState(() {
                                _filterState = value;
                                _filterCity = null;
                              }),
                            ),
                            const SizedBox(height: 10),
                            _buildDropdownFilterField(
                              label: 'City',
                              value: _filterCity,
                              options:
                                  masterData.citiesByState[_filterState] ??
                                  const <String>[],
                              onChanged: (value) =>
                                  setState(() => _filterCity = value),
                            ),
                            const SizedBox(height: 10),
                            _buildDropdownFilterField(
                              label: 'Mother Tongue',
                              value: _filterMotherTongue,
                              options: masterData.motherTongues,
                              onChanged: (value) =>
                                  setState(() => _filterMotherTongue = value),
                            ),
                            const SizedBox(height: 10),
                            _buildDropdownFilterField(
                              label: 'Religion',
                              value: _filterReligion,
                              options: masterData.religions,
                              onChanged: (value) =>
                                  setState(() => _filterReligion = value),
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownFilterField(
                              label: 'Relationship Status',
                              value: _filterRelationshipStatus,
                              options: const [
                                'Single',
                                'Divorced',
                                'Widowed',
                                'Separated',
                                'Complicated',
                              ],
                              onChanged: (value) => setState(
                                () => _filterRelationshipStatus = value,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownFilterField(
                              label: 'Smoking',
                              value: _filterSmoking,
                              options: const [
                                'Never',
                                'Occasionally',
                                'Regularly',
                              ],
                              onChanged: (value) =>
                                  setState(() => _filterSmoking = value),
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownFilterField(
                              label: 'Drinking',
                              value: _filterDrinking,
                              options: const [
                                'Never',
                                'Occasionally',
                                'Socially',
                                'Regularly',
                              ],
                              onChanged: (value) =>
                                  setState(() => _filterDrinking = value),
                            ),
                            const SizedBox(height: 12),
                            _buildDropdownFilterField(
                              label: 'Personality Type',
                              value: _filterPersonalityType,
                              options: const [
                                'Introvert',
                                'Ambivert',
                                'Extrovert',
                              ],
                              onChanged: (value) => setState(
                                () => _filterPersonalityType = value,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Party lover only',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Switch(
                                  value: _filterPartyLoverOnly,
                                  onChanged: (value) => setState(
                                    () => _filterPartyLoverOnly = value,
                                  ),
                                  activeThumbColor: AppTheme.trustBlue,
                                  activeTrackColor: AppTheme.trustBlue
                                      .withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hookups only',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Switch(
                                  value: _filterHookupOnly,
                                  onChanged: (value) =>
                                      setState(() => _filterHookupOnly = value),
                                  activeThumbColor: AppTheme.trustBlue,
                                  activeTrackColor: AppTheme.trustBlue
                                      .withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: Colors.white.withValues(alpha: 0.78),
                      blur: 8,
                      child: _buildFilterSection(
                        context,
                        'Advanced Bio Filters',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Books, novels, songs, hobbies, location and extra-curricular tags can be managed in Settings → Dating Preferences.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const SetupPreferencesScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Open Dating Preferences'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: Colors.white.withValues(alpha: 0.78),
                      blur: 8,
                      child: _buildFilterSection(
                        context,
                        'Distance (km)',
                        child: Slider(
                          value: _filterDistance,
                          min: 1,
                          max: 500,
                          divisions: 499,
                          label: '${_filterDistance.round()} km',
                          onChanged: (value) =>
                              setState(() => _filterDistance = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: Colors.white.withValues(alpha: 0.78),
                      blur: 8,
                      child: _buildFilterSection(
                        context,
                        'Verified Only',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Show only verified profiles',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Switch(
                              value: _filterVerifiedOnly,
                              onChanged: (value) =>
                                  setState(() => _filterVerifiedOnly = value),
                              activeThumbColor: AppTheme.trustBlue,
                              activeTrackColor: AppTheme.trustBlue.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: Colors.white.withValues(alpha: 0.78),
                      blur: 8,
                      child: _buildFilterSection(
                        context,
                        'Trust Filters',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Enable trust-based filtering',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Switch(
                                  value: trustEnabled,
                                  onChanged: (value) {
                                    setSheetState(() {
                                      trustEnabled = value;
                                    });
                                  },
                                  activeThumbColor: AppTheme.trustBlue,
                                  activeTrackColor: AppTheme.trustBlue
                                      .withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Minimum active trust badges: $minimumActiveBadges',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Slider(
                              value: minimumActiveBadges.toDouble(),
                              min: 0,
                              max: 4,
                              divisions: 4,
                              label: minimumActiveBadges.toString(),
                              onChanged: trustEnabled
                                  ? (value) {
                                      setSheetState(() {
                                        minimumActiveBadges = value.round();
                                      });
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: trustState.availableBadges
                                  .map((badge) {
                                    final selected = requiredBadgeCodes
                                        .contains(badge.code);
                                    return FilterChip(
                                      label: Text(badge.label),
                                      selected: selected,
                                      onSelected: trustEnabled
                                          ? (value) {
                                              setSheetState(() {
                                                if (value) {
                                                  requiredBadgeCodes.add(
                                                    badge.code,
                                                  );
                                                } else {
                                                  requiredBadgeCodes.remove(
                                                    badge.code,
                                                  );
                                                }
                                              });
                                            }
                                          : null,
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                            if (trustState.isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(
                                  color: AppTheme.trustBlue,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: trustState.isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _filterAge = const RangeValues(20, 50);
                                      _filterDistance = 50;
                                      _filterVerifiedOnly = false;
                                      _filterReligion = null;
                                      _filterMotherTongue = null;
                                      _filterCountry = null;
                                      _filterState = null;
                                      _filterCity = null;
                                      _filterRelationshipStatus = null;
                                      _filterSmoking = null;
                                      _filterDrinking = null;
                                      _filterPersonalityType = null;
                                      _filterPartyLoverOnly = false;
                                      _filterHookupOnly = false;
                                    });
                                    ref
                                        .read(swipeNotifierProvider.notifier)
                                        .setManualFilters(
                                          const <String, String>{},
                                        );
                                    setSheetState(() {
                                      trustEnabled = false;
                                      minimumActiveBadges = 0;
                                      requiredBadgeCodes.clear();
                                    });
                                  },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: trustState.isSaving
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    await trustNotifier.save(
                                      enabled: trustEnabled,
                                      minimumActiveBadges: minimumActiveBadges,
                                      requiredBadgeCodes: requiredBadgeCodes
                                          .toList(),
                                    );
                                    ref
                                        .read(swipeNotifierProvider.notifier)
                                        .setManualFilters(
                                          _manualFiltersPayload,
                                        );
                                    await ref
                                        .read(swipeNotifierProvider.notifier)
                                        .refreshProfiles();
                                    await ref
                                        .read(matchNotifierProvider.notifier)
                                        .refresh();

                                    if (!mounted) {
                                      return;
                                    }

                                    final latestTrust = ref.read(
                                      trustFilterNotifierProvider,
                                    );
                                    Navigator.of(context).pop();

                                    if (latestTrust.error != null) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(latestTrust.error!),
                                        ),
                                      );
                                      return;
                                    }

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Filters saved: ${_filterAge.start.round()}-${_filterAge.end.round()} yrs, '
                                          '${_filterDistance.round()} km'
                                          '${_filterVerifiedOnly ? ', verified only' : ''}'
                                          '${trustEnabled ? ', trust filter on' : ', trust filter off'}',
                                        ),
                                      ),
                                    );
                                  },
                            child: trustState.isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title, {
    required Widget child,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      child,
    ],
  );

  Map<String, String> get _manualFiltersPayload {
    final payload = <String, String>{
      'min_age': _filterAge.start.round().toString(),
      'max_age': _filterAge.end.round().toString(),
      'max_distance_km': _filterDistance.round().toString(),
      'verified_only': _filterVerifiedOnly.toString(),
    };

    void put(String key, String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        payload[key] = normalized;
      }
    }

    put('religion', _filterReligion);
    put('mother_tongue', _filterMotherTongue);
    put('country', _filterCountry);
    put('state', _filterState);
    put('city', _filterCity);
    put('relationship_status', _filterRelationshipStatus);
    put('smoking', _filterSmoking);
    put('drinking', _filterDrinking);
    put('personality_type', _filterPersonalityType);
    if (_filterPartyLoverOnly) {
      payload['party_lover'] = 'true';
    }
    if (_filterHookupOnly) {
      payload['hookup_only'] = 'true';
    }

    return payload;
  }

  Widget _buildDropdownFilterField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final resolvedValue = options.contains(value) ? value : null;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: resolvedValue,
          isExpanded: true,
          hint: const Text('Any'),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
