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
        profession: 'Designer',
        education: null,
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
}
