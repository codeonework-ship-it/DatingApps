import 'package:flutter/material.dart' hide Title;
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/clubs/club_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/clubs_screen.dart';
import 'package:verified_dating_app/features/clubs/my_lists_screen.dart';
import 'package:verified_dating_app/features/clubs/title_detail_screen.dart';

import '../../support/qa_screen_checks.dart';
import 'clubs_qa_fixtures.dart';

// Clubs screens with their data loaded: no overflow at any shipped device
// size in either theme, Flutter's tap-target / label / contrast guidelines,
// and a Back control that really closes the pushed screen.

typedef _Screen = ({
  String slug,
  Type type,
  Widget Function() build,
  Finder loaded,
});

final _screens = <_Screen>[
  (
    slug: 'clubs',
    type: ClubsScreen,
    build: ClubsScreen.new,
    loaded: find.text('Sunday Slow Reads'),
  ),
  (
    slug: 'club_detail',
    type: ClubDetailScreen,
    build: () => const ClubDetailScreen(clubId: 'club-1'),
    loaded: find.text('Sunday Slow Reads'),
  ),
  (
    slug: 'my_lists',
    type: MyListsScreen,
    build: MyListsScreen.new,
    loaded: find.text('Read next'),
  ),
  (
    slug: 'title_detail',
    type: TitleDetailScreen,
    build: () => const TitleDetailScreen(titleId: 'title-1'),
    loaded: find.text('Piranesi'),
  ),
];

void main() {
  for (final s in _screens) {
    final slug = s.slug;
    testWidgets('${s.type} lays out on every device size in both themes '
        '[case:clubs.$slug.layout_matrix]', (t) async {
      final w = ClubsWorld(role: 'owner');
      await qaExpectLaysOutEverywhere(t, w.api, s.build, loaded: s.loaded);
    });

    testWidgets('${s.type} meets the tap-target, label and contrast '
        'guidelines [case:clubs.$slug.a11y_guidelines]', (t) async {
      final w = ClubsWorld(role: 'owner');
      await qaExpectMeetsA11yGuidelines(t, w.api, s.build, loaded: s.loaded);
    });

    testWidgets('${s.type} pushed from another screen shows Back, which '
        'closes it [case:clubs.$slug.back_affordance]', (t) async {
      final w = ClubsWorld(role: 'owner');
      await qaExpectBackReturns(t, w.api, s.build, screen: s.type);
    });
  }
}
