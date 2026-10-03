import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/groups/create_group_screen.dart';
import 'package:verified_dating_app/features/groups/group_detail_screen.dart';
import 'package:verified_dating_app/features/groups/groups_screen.dart';

import '../../support/qa_screen_checks.dart';
import 'groups_world.dart';

// Groups screens with their data loaded through the fake BFF: no overflow at
// any shipped device size in either theme, Flutter's tap-target / label /
// contrast guidelines, and a Back control that really closes the pushed
// screen.

/// Your groups: "Sunday hikers" (I run it, with a pending cover photo, so the
/// owner tools, cover actions, members row and chat button all show).
/// Invitation: "Trek planners". Discover: "Koramangala readers" (Books).
GroupsWorld _world() {
  final w = GroupsWorld()
    ..groups.addAll({
      'mine': qaGroup(
        id: 'mine',
        name: 'Sunday hikers',
        role: 'owner',
        channel: 'ch-mine',
        canInvite: true,
        canManage: true,
        city: 'Bengaluru',
        coverId: 'cv1',
        coverStatus: 'pending',
        unread: 2,
      ),
      'p1': qaGroup(
        id: 'p1',
        kind: 'private',
        name: 'Trek planners',
        inviteId: 'inv-1',
        memberCount: 4,
      ),
      'g1': qaGroup(canJoin: true),
    });
  w.channels.add({
    'id': 'ch-mine',
    'kind': 'group',
    'ref_id': 'mine',
    'muted': true,
  });
  return w;
}

typedef _Screen = ({
  String slug,
  Type type,
  Widget Function() build,
  Finder loaded,
});

final _screens = <_Screen>[
  (
    slug: 'groups',
    type: GroupsScreen,
    build: GroupsScreen.new,
    // Listed under "Your groups" once my groups have loaded.
    loaded: find.text('Sunday hikers'),
  ),
  (
    slug: 'group_detail',
    type: GroupDetailScreen,
    build: () => const GroupDetailScreen(groupId: 'mine'),
    // The members row only renders from the loaded group.
    loaded: find.text('Asha'),
  ),
  (
    slug: 'create_group',
    type: CreateGroupScreen,
    build: () => const CreateGroupScreen(
      invitees: [(userId: 'asha', name: 'Asha', photoUrl: '')],
      initialKind: 'community',
    ),
    // Lifestyle chips appear only once the categories have loaded.
    loaded: find.text('📚  Books'),
  ),
];

void main() {
  for (final s in _screens) {
    final slug = s.slug;
    testWidgets('${s.type} lays out on every device size in both themes '
        '[case:groups.$slug.layout_matrix]', (t) async {
      final w = _world();
      await qaExpectLaysOutEverywhere(t, w.api, s.build, loaded: s.loaded);
    });

    testWidgets('${s.type} meets the tap-target, label and contrast '
        'guidelines [case:groups.$slug.a11y_guidelines]', (t) async {
      final w = _world();
      await qaExpectMeetsA11yGuidelines(t, w.api, s.build, loaded: s.loaded);
    });

    testWidgets('${s.type} pushed from another screen shows Back, which '
        'closes it [case:groups.$slug.back_affordance]', (t) async {
      final w = _world();
      await qaExpectBackReturns(t, w.api, s.build, screen: s.type);
    });
  }
}
