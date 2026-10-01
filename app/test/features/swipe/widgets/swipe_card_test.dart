import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/widgets/swipe_card.dart';

void main() {
  DiscoveryProfile buildProfile({required List<String> photoUrls}) =>
      DiscoveryProfile(
        id: 'p1',
        name: 'Ananya',
        dateOfBirth: DateTime(1999, 4, 18),
        bio: 'Loves books and coffee',
        additionalInfo: 'Weekend hiker',
        profession: 'Designer',
        education: null,
        instagramHandle: '@ananya',
        hobbies: const <String>['Reading'],
        favoriteSongs: const <String>['Song A'],
        extraCurriculars: const <String>['Cycling'],
        intentTags: const <String>['Long-term'],
        languageTags: const <String>['English'],
        isVerified: true,
        photoUrls: photoUrls,
      );

  testWidgets('uses responsive card height based on screen size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SwipeCard(
              profile: buildProfile(
                photoUrls: <String>['https://example.com/photo.jpg'],
              ),
            ),
          ),
        ),
      ),
    );

    final glassContainer = tester.widget<GlassContainer>(
      find.byType(GlassContainer).first,
    );
    expect(glassContainer.height, isNotNull);
    expect(glassContainer.height, inInclusiveRange(360.0, 620.0));
  });

  testWidgets('shows fallback avatar when profile has no photo URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeCard(profile: buildProfile(photoUrls: <String>[])),
        ),
      ),
    );

    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });

  testWidgets('renders spotlight tier badge when profile is spotlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeCard(
            profile: buildProfile(
              photoUrls: <String>['https://example.com/photo.jpg'],
            ).copyWithSpotlight(),
          ),
        ),
      ),
    );

    expect(find.text('Gold'), findsOneWidget);
  });

  testWidgets('shows at most two curated reason chips before the tags', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeCard(
            profile:
                buildProfile(
                  photoUrls: <String>['https://example.com/photo.jpg'],
                ).copyWithReasons(const <String>[
                  'Shares your intent',
                  'Verified & active',
                  'Shows up',
                ]),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('qa.discover.today.deck_reason.0')),
      findsOneWidget,
    );
    expect(find.text('Shares your intent'), findsOneWidget);
    expect(find.text('Verified & active'), findsOneWidget);
    expect(find.text('Shows up'), findsNothing);
    // The profile's own quick-preview tags still follow the reasons.
    expect(find.text('Long-term'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

extension on DiscoveryProfile {
  DiscoveryProfile copyWithReasons(List<String> reasons) => DiscoveryProfile(
    id: id,
    name: name,
    dateOfBirth: dateOfBirth,
    bio: bio,
    additionalInfo: additionalInfo,
    profession: profession,
    education: education,
    instagramHandle: instagramHandle,
    hobbies: hobbies,
    favoriteSongs: favoriteSongs,
    extraCurriculars: extraCurriculars,
    intentTags: intentTags,
    languageTags: languageTags,
    isVerified: isVerified,
    photoUrls: photoUrls,
    reasons: reasons,
    why: 'Picked for you today: ${reasons.join(' · ')}',
  );

  DiscoveryProfile copyWithSpotlight() => DiscoveryProfile(
    id: id,
    name: name,
    dateOfBirth: dateOfBirth,
    bio: bio,
    additionalInfo: additionalInfo,
    profession: profession,
    education: education,
    instagramHandle: instagramHandle,
    hobbies: hobbies,
    favoriteSongs: favoriteSongs,
    extraCurriculars: extraCurriculars,
    intentTags: intentTags,
    languageTags: languageTags,
    isVerified: isVerified,
    photoUrls: photoUrls,
    isSpotlight: true,
    spotlightTier: 'gold',
    spotlightScore: 78,
    spotlightReason: 'paid_plus_activity',
  );
}
