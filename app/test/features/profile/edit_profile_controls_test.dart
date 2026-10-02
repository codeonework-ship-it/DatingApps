// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/profile/screens/edit_profile_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preferences_screen.dart';

import '../../support/qa_api.dart';
import 'support/profile_bff.dart';

// Control-level tests for Edit Profile (EditProfileScreen): refresh and
// retry reload the draft from the BFF, and every section's edit action opens
// its editor; what is saved there shows on Edit Profile on return.

const _refresh = ValueKey('qa.edit_profile.refresh');
ValueKey<String> _section(String id) => ValueKey('qa.edit_profile.$id');

final _en = qaL10n(const Locale('en'));

Future<List<Object?>> _open(WidgetTester tester, QaApi api, {Locale? locale}) =>
    pumpQa(
      tester,
      api,
      const EditProfileScreen(),
      launcher: true,
      locale: locale,
      size: const Size(430, 1400),
      extra: qaMasterDataOverrides(),
    );

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await qaSettle(tester, frames: 2);
  await tester.ensureVisible(finder);
  await qaSettle(tester, frames: 2);
  await tester.tap(finder);
  await qaSettle(tester);
}

/// The value shown next to [label] on Edit Profile.
String _row(WidgetTester tester, String label) {
  final row = find
      .ancestor(of: find.text(label), matching: find.byType(Row))
      .first;
  final texts = tester
      .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
      .map((t) => t.data)
      .where((t) => t != label)
      .toList();
  return texts.single!;
}

Future<void> _save(WidgetTester tester, Key key) async {
  await qaSettle(tester, frames: 3);
  await tester.ensureVisible(find.byKey(key));
  await qaSettle(tester, frames: 3);
  await tester.tap(find.byKey(key));
  await qaSettle(tester);
}

void main() {
  testWidgets('Refresh reloads the draft and shows what changed elsewhere '
      '[case:profile.edit_profile.refresh_profile.action]', (tester) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    await _open(tester, api);
    expect(find.text('Ananya'), findsWidgets);
    expect(api.sent('GET', '/profile/me/draft'), hasLength(1));

    bff.draft = {...bff.draft, 'name': 'Ananya Rao'};
    await _tap(tester, find.byKey(_refresh));
    expect(api.sent('GET', '/profile/me/draft'), hasLength(2));
    expect(find.text('Ananya Rao'), findsWidgets);
    expect(_row(tester, _en.profileEditName), 'Ananya Rao');
  });

  testWidgets('a failed refresh shows the error with Retry '
      '[case:profile.edit_profile.refresh_profile.action]', (tester) async {
    final api = QaApi();
    ProfileBff(api);
    await _open(tester, api);
    api.fail('GET /profile/*/draft');
    await _tap(tester, find.byKey(_refresh));
    expect(find.text(_en.profileSetupLoadErrorTitle), findsOneWidget);
    expect(find.text(_en.profileSetupRetry), findsOneWidget);
  });

  testWidgets('Retry reloads a profile that failed to load '
      '[case:profile.edit_profile.retry_onretry.action]', (tester) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    api.fail('GET /profile/*/draft');
    await _open(tester, api);
    expect(find.text(_en.profileSetupLoadErrorTitle), findsOneWidget);
    expect(find.byKey(_section('about_you')), findsNothing);

    bff.install();
    await _tap(tester, find.text(_en.profileSetupRetry));
    expect(api.sent('GET', '/profile/me/draft'), hasLength(2));
    expect(find.byKey(_section('about_you')), findsOneWidget);
    expect(_row(tester, _en.profileEditName), 'Ananya');
  });

  testWidgets('Edit About opens About you; the saved bio shows on return '
      '[case:profile.edit_profile.about_you_onaction.action]', (tester) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    await _open(tester, api);
    await _tap(tester, find.byKey(_section('about_you')));
    expect(find.byType(SetupAboutScreen), findsOneWidget);
    expect(find.text(_en.profileSetupSaveAbout), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('qa.setup.about.bio_field')),
      'Weekend potter, weekday analyst.',
    );
    await _save(tester, const ValueKey('qa.setup.about.save_button'));
    expect(find.byType(SetupAboutScreen), findsNothing);
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(bff.draft['bio'], 'Weekend potter, weekday analyst.');
    expect(
      _row(tester, _en.profileSetupBioLabel),
      'Weekend potter, weekday analyst.',
    );
  });

  testWidgets('Location & social opens preferences; the saved country shows '
      'on return [case:profile.edit_profile.location_social_onaction.action]', (
    tester,
  ) async {
    final api = QaApi();
    ProfileBff(api);
    await _open(tester, api);
    expect(_row(tester, _en.profileSetupCountry), _en.profileEditNotSet);
    await _tap(tester, find.byKey(_section('location_social')));
    expect(find.byType(SetupPreferencesScreen), findsOneWidget);

    await tester.tap(find.text(_en.profileSetupTabAdvanced));
    await qaSettle(tester, frames: 5);
    const country = ValueKey('qa.setup.preferences.country');
    await tester.tap(find.byKey(country));
    await qaSettle(tester, frames: 5);
    await tester.tap(find.text('Canada').last);
    await qaSettle(tester, frames: 5);
    await _save(tester, const ValueKey('qa.setup.preferences.save_button'));

    expect(find.byType(SetupPreferencesScreen), findsNothing);
    expect(_row(tester, _en.profileSetupCountry), 'Canada');
  });

  testWidgets('Dating preferences opens preferences; a saved switch shows on '
      'return [case:profile.edit_profile.dating_preferences_onaction.action]', (
    tester,
  ) async {
    final api = QaApi();
    ProfileBff(api);
    await _open(tester, api);
    expect(_row(tester, _en.profileEditVerifiedOnly), _en.profileEditNo);
    await _tap(tester, find.byKey(_section('dating_preferences')));
    expect(find.byType(SetupPreferencesScreen), findsOneWidget);

    await _save(
      tester,
      const ValueKey('qa.setup.preferences.verified_only_toggle'),
    );
    await _save(tester, const ValueKey('qa.setup.preferences.save_button'));
    expect(find.byType(SetupPreferencesScreen), findsNothing);
    expect(_row(tester, _en.profileEditVerifiedOnly), _en.profileEditYes);
  });

  testWidgets('Lifestyle opens preferences; a saved diet shows on return '
      '[case:profile.edit_profile.lifestyle_onaction.action]', (tester) async {
    final api = QaApi();
    ProfileBff(api);
    await _open(tester, api);
    await _tap(tester, find.byKey(_section('lifestyle')));
    expect(find.byType(SetupPreferencesScreen), findsOneWidget);

    await tester.tap(find.text(_en.profileSetupTabAdvanced));
    await qaSettle(tester, frames: 5);
    const diet = ValueKey('qa.setup.preferences.diet_preference');
    await tester.ensureVisible(find.byKey(diet));
    await qaSettle(tester, frames: 2);
    await tester.tap(find.byKey(diet));
    await qaSettle(tester, frames: 5);
    await tester.tap(find.text('Veg').last);
    await qaSettle(tester, frames: 5);
    await _save(tester, const ValueKey('qa.setup.preferences.save_button'));
    expect(_row(tester, _en.profileSetupDietPreference), 'Veg');
  });

  testWidgets('Interests & details opens preferences; saved hobbies show on '
      'return [case:profile.edit_profile.interests_details_onaction.action]', (
    tester,
  ) async {
    final api = QaApi();
    ProfileBff(api);
    await _open(tester, api);
    await _tap(tester, find.byKey(_section('interests_details')));
    expect(find.byType(SetupPreferencesScreen), findsOneWidget);

    await tester.tap(find.text(_en.profileSetupTabAdvanced));
    await qaSettle(tester, frames: 5);
    const hobbies = ValueKey('qa.setup.preferences.hobbies_field');
    await tester.ensureVisible(find.byKey(hobbies));
    await tester.enterText(find.byKey(hobbies), 'chess, jazz');
    await _save(tester, const ValueKey('qa.setup.preferences.save_button'));
    expect(_row(tester, _en.profileEditHobbies), 'chess, jazz');
  });

  testWidgets('Manage photos opens the photo editor; a removed photo is gone '
      'on return [case:profile.edit_profile.photo_gallery_onaction.action]', (
    tester,
  ) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    await _open(tester, api);
    int gridCount() =>
        (tester.widget<GridView>(find.byType(GridView)).childrenDelegate
                as SliverChildBuilderDelegate)
            .childCount!;
    expect(gridCount(), 2);
    await _tap(tester, find.byKey(_section('photo_gallery')));
    expect(find.byType(SetupPhotosScreen), findsOneWidget);
    expect(find.text(_en.profileSetupSavePhotos), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('qa.setup.photos.delete_p2')));
    await _tap(
      tester,
      find.byKey(const ValueKey('qa.setup.photos.confirm_delete')),
    );
    expect(bff.photoIds, ['p1']);
    await tester.tap(find.byTooltip(_en.profileSetupBackTooltip));
    await qaSettle(tester);
    expect(find.byType(SetupPhotosScreen), findsNothing);
    expect(gridCount(), 1);
  });

  testWidgets('renders translated in every locale '
      '[case:profile.edit_profile.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final api = QaApi();
      ProfileBff(api);
      await _open(tester, api, locale: locale);
      final l10n = qaL10n(locale);
      expect(find.text(l10n.profileEditTitle), findsOneWidget);
      expect(find.text(l10n.profileEditAboutYou), findsOneWidget);
      expect(find.text(l10n.profileEditPhotoGallery), findsOneWidget);
      expect(find.text(l10n.profileEditManagePhotos), findsOneWidget);
      expect(find.byTooltip(l10n.profileEditRefreshTooltip), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
