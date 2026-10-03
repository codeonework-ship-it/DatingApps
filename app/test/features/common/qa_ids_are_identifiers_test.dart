// Automation ids (qa.*) are semantics identifiers, never spoken labels.
//
// A screen reader used to announce "qa dot discovery dot filter button"
// because the ids were Semantics labels. These tests pump the real screens in
// German and check, through the semantics tree, that each id still locates
// its control (find.bySemanticsIdentifier, which is what Android exposes as
// resource-id to Appium), that the node it lands on says German words, that
// it covers exactly the control, and that no label anywhere starts with "qa.".
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/engagement/providers/billing_coexistence_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/matching/providers/match_provider.dart';
import 'package:verified_dating_app/features/matching/providers/trust_filter_provider.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/features/profile/data/india_master_data.dart';
import 'package:verified_dating_app/features/profile/providers/preference_master_data_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/swipe/widgets/swipe_buttons.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Swipe extends SwipeNotifier {
  @override
  SwipeState build() => const SwipeState();
  @override
  void setManualFilters(Map<String, String> value) {}
  @override
  Future<void> refreshProfiles() async {}
}

class _Matches extends MatchNotifier {
  @override
  MatchState build() => const MatchState();
  @override
  Future<void> refresh() async {}
}

class _Draft extends ProfileSetupNotifier {
  @override
  Future<ProfileDraft> build() async => ProfileDraft(
    userId: 'user-1',
    phoneNumber: '+919999999999',
    name: 'Ananya',
    dateOfBirth: DateTime(1998, 6, 20),
    gender: 'F',
    photos: const <ProfilePhotoItem>[],
    bio: 'This is a sufficiently long bio for tests.',
    heightCm: null,
    education: null,
    profession: null,
    incomeRange: null,
    seekingGenders: const <String>['M'],
    minAgeYears: 21,
    maxAgeYears: 40,
    maxDistanceKm: 50,
    educationFilter: const <String>[],
    seriousOnly: true,
    verifiedOnly: false,
    country: 'India',
    regionState: 'Karnataka',
    city: 'Bengaluru',
    instagramHandle: null,
    hobbies: const <String>[],
    favoriteBooks: const <String>[],
    favoriteNovels: const <String>[],
    favoriteSongs: const <String>[],
    extraCurriculars: const <String>[],
    additionalInfo: null,
    intentTags: const <String>[],
    languageTags: const <String>[],
    petPreference: null,
    dietPreference: null,
    workoutFrequency: null,
    dietType: null,
    sleepSchedule: null,
    travelStyle: null,
    politicalComfortRange: null,
    dealBreakerTags: const <String>[],
    drinking: 'Never',
    smoking: 'Never',
    religion: null,
    motherTongue: null,
    hookupOnly: false,
  );
}

class _Prompt extends DailyPromptNotifier {
  _Prompt(super.ref);
  @override
  Future<void> load() async {}
}

class _Notifications extends NotificationNotifier {
  _Notifications(super.ref);
  @override
  Future<void> bootstrap() async {}
}

class _Trust extends TrustFilterNotifier {
  _Trust(super.ref);
  @override
  Future<void> load() async {}
}

final _master = PreferenceMasterData.fromJson({
  'countries': ['India', 'Canada'],
  'states_by_country': {
    'India': ['Karnataka'],
  },
  'cities_by_state': {
    'Karnataka': ['Bengaluru'],
  },
  'religions': ['Hindu'],
  'mother_tongues': ['Kannada'],
});

const _de = Locale('de');

Future<void> _mountNavigation(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runtimeFeatureFlagsProvider.overrideWith(
          (ref) => Stream.value(
            RuntimeFeatureFlags(<String, bool>{
              ...RuntimeFeatureFlags.defaults.values,
              'intentional_dating_enabled': false,
            }),
          ),
        ),
        billingCoexistenceMatrixProvider.overrideWith(
          (ref) async => const BillingCoexistenceMatrix(
            matrixVersion: 'qa',
            coreProgressionNonBlocking: true,
            coreProgressionFeatures: [],
            monetizedFeatures: [],
          ),
        ),
        swipeNotifierProvider.overrideWith(_Swipe.new),
        matchNotifierProvider.overrideWith(_Matches.new),
        profileSetupNotifierProvider.overrideWith(_Draft.new),
        dailyPromptProvider.overrideWith(_Prompt.new),
        notificationProvider.overrideWith(_Notifications.new),
        trustFilterNotifierProvider.overrideWith(_Trust.new),
        preferenceMasterDataProvider.overrideWith((ref) async => _master),
        preferenceMasterDataOfflineProvider.overrideWith((ref) => false),
      ],
      child: const MaterialApp(
        locale: _de,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainNavigationScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every label in the live semantics tree, merged nodes included.
List<String> _allLabels(WidgetTester tester) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    labels.add(node.label);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  var root = tester.getSemantics(find.byType(Scaffold).first);
  while (root.parent != null) {
    root = root.parent!;
  }
  visit(root);
  return labels;
}

void _expectNoQaLabels(WidgetTester tester) {
  final spoken = _allLabels(tester)
      .expand((label) => label.split('\n'))
      .where((line) => line.trim().startsWith('qa.'))
      .toList();
  expect(spoken, isEmpty, reason: 'qa ids must never be spoken');
}

/// The id's node covers the control the key names, not a larger ancestor.
void _expectSameRect(WidgetTester tester, String id) {
  final nodeRect = tester.getRect(find.bySemanticsIdentifier(id));
  final widgetRect = tester.getRect(find.byKey(ValueKey(id)));
  expect(nodeRect.left, closeTo(widgetRect.left, 1), reason: id);
  expect(nodeRect.top, closeTo(widgetRect.top, 1), reason: id);
  expect(nodeRect.width, closeTo(widgetRect.width, 1), reason: id);
  expect(nodeRect.height, closeTo(widgetRect.height, 1), reason: id);
}

void main() {
  testWidgets(
    '[case:a11y-qa-id-nav-and-filters-de] bottom nav and filter sheet keep '
    'their ids as identifiers and speak German',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final de = lookupAppLocalizations(_de);
      await _mountNavigation(tester);

      // Bottom navigation: the id sits on the tab tile, which is read by
      // its German item label.
      final discover = find.bySemanticsIdentifier('qa.nav.discover');
      expect(discover, findsOneWidget);
      expect(
        tester.getSemantics(discover).getSemanticsData().label,
        contains('Entdecken'),
      );
      final settings = find.bySemanticsIdentifier('qa.nav.settings');
      expect(settings, findsOneWidget);
      expect(
        tester.getSemantics(settings).getSemanticsData().label,
        contains(de.navSettings),
      );
      _expectNoQaLabels(tester);

      // Discover header filter button: German visible text, id kept.
      final filterButton = find.bySemanticsIdentifier(
        'qa.discovery.filter_button',
      );
      expect(filterButton, findsWidgets);
      expect(
        tester.getSemantics(filterButton.first).getSemanticsData().label,
        'Filter',
      );

      await tester.tap(
        find.byKey(const ValueKey('qa.discovery.filter_button')).first,
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('qa.filters.sheet'), findsOneWidget);

      // Switches and sliders have no text of their own: the id node carries
      // the German name of the row.
      final party = find.bySemanticsIdentifier('qa.filters.party_lover_switch');
      expect(
        tester.getSemantics(party).getSemanticsData().label,
        'Nur Partyfans',
      );
      expect(
        tester.getSemantics(party).getSemanticsData().flagsCollection.isToggled,
        isNot(Tristate.none),
      );
      final distance = find.bySemanticsIdentifier('qa.filters.distance_slider');
      // The row's name, then the slider's own value label.
      expect(
        tester.getSemantics(distance).getSemanticsData().label,
        'Entfernung (km)\n${de.commonDistanceKm(50)}',
      );
      final age = find.bySemanticsIdentifier('qa.filters.age_range_slider');
      expect(
        tester.getSemantics(age).getSemanticsData().label,
        de.filterAgeRange,
      );
      expect(de.filterAgeRange, isNot('Age Range'));

      // Buttons are read by their German text; the id is on the button node.
      final reset = find.bySemanticsIdentifier('qa.filters.reset_button');
      expect(
        tester.getSemantics(reset).getSemanticsData().label,
        'Zurücksetzen',
      );
      expect(
        tester.getSemantics(reset).getSemanticsData().flagsCollection.isButton,
        isTrue,
      );
      _expectSameRect(tester, 'qa.filters.reset_button');
      _expectSameRect(tester, 'qa.filters.party_lover_switch');
      // The dropdown's id covers the whole decorated field (its floating
      // name included), so it is read as "Land, Beliebig".
      final field = tester.getRect(
        find.bySemanticsIdentifier('qa.filters.country_dropdown'),
      );
      final menu = tester.getRect(
        find.byKey(const ValueKey('qa.filters.country_dropdown')),
      );
      expect(field.inflate(1).contains(menu.topLeft), isTrue);
      expect(field.inflate(1).contains(menu.bottomRight), isTrue);

      // Dropdown: the field is named in German; the stored value stays the
      // English option while the menu shows its localized label.
      final country = find.bySemanticsIdentifier('qa.filters.country_dropdown');
      expect(
        tester.getSemantics(country).getSemanticsData().label,
        contains(de.filterCountry),
      );
      await tester.tap(
        find.byKey(const ValueKey('qa.filters.country_dropdown')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          profileOptionLabel(de, 'Canada', list: ProfileOptionList.country),
        ),
        findsWidgets,
      );
      await tester.tap(find.text(de.commonAny).last);
      await tester.pumpAndSettle();

      final status = find.byKey(
        const ValueKey('qa.filters.relationship_status_dropdown'),
      );
      await tester.ensureVisible(status);
      await tester.pumpAndSettle();
      await tester.tap(status);
      await tester.pumpAndSettle();
      expect(find.text('Geschieden'), findsWidgets);
      expect(find.text('Divorced'), findsNothing);
      await tester.tap(find.text('Geschieden').last);
      await tester.pumpAndSettle();

      _expectNoQaLabels(tester);
      semantics.dispose();
    },
  );

  testWidgets(
    '[case:a11y-qa-id-swipe-buttons-de] deck action buttons are named in '
    'German and keep their ids',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var likes = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: _de,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SwipeButtons(
                onPass: () async {},
                onLike: () async => likes++,
                onSuperLike: () async {},
                onMessage: () async {},
                onUndo: () {},
                canUndo: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final de = lookupAppLocalizations(_de);
      final expected = <String, String>{
        'qa.discovery.undo_button': de.discoverActionUndo,
        'qa.discovery.pass_button': de.discoverPass,
        'qa.discovery.like_button': 'Gefällt mir',
        'qa.discovery.superlike_button': de.discoverActionSuperLike,
        'qa.discovery.message_button': de.memberProfileMessage,
      };
      for (final entry in expected.entries) {
        final node = tester.getSemantics(find.bySemanticsIdentifier(entry.key));
        expect(node.getSemanticsData().label, entry.value, reason: entry.key);
        expect(
          node.getSemanticsData().flagsCollection.isButton,
          isTrue,
          reason: entry.key,
        );
        _expectSameRect(tester, entry.key);
      }
      _expectNoQaLabels(tester);

      // The node found by id is the control: tapping it likes.
      await tester.tap(find.bySemanticsIdentifier('qa.discovery.like_button'));
      await tester.pumpAndSettle();
      expect(likes, 1);
      semantics.dispose();
    },
  );
}
