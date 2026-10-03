import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/groups/group_widgets.dart';
import 'package:verified_dating_app/features/groups/groups_data.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'groups_world.dart';

// The shared group widgets: the group sheet (showGroupSheet) every group
// picker and menu opens, and the cover / card widgets' own wording.

/// Opens a group sheet the way the screens do and records what it returns.
class _SheetHost extends StatelessWidget {
  const _SheetHost({required this.results});
  final List<String?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: IconButton(
        key: const ValueKey('qa.test.sheet'),
        icon: const Icon(Icons.open_in_new_rounded),
        onPressed: () async => results.add(
          await showGroupSheet<String>(
            context,
            Builder(
              builder: (sheet) => GroupSheetFrame(
                title: 'Pick one',
                subtitle: 'Any will do',
                footer: FilledButton(
                  key: const ValueKey('qa.test.pick'),
                  onPressed: () => Navigator.of(sheet).pop('picked'),
                  child: const Text('Pick'),
                ),
                children: const [Text('First choice')],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The group widgets with their own wording: a removed private group's card,
/// a community card, an emoji cover and the cover colour chips.
class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: ListView(
        children: [
          GroupCard(
            group: Group.fromJson(
              qaGroup(
                id: 'p1',
                kind: 'private',
                name: 'Trek planners',
                memberCount: 4,
                removed: true,
              ),
            ),
            onTap: () {},
          ),
          GroupCard(
            group: Group.fromJson(qaGroup(city: 'Bengaluru')),
            onTap: () {},
            trailing: const GroupUnreadBadge(count: 3),
          ),
          const GroupCover(emoji: '📚', color: 'secondary'),
          Wrap(
            children: [
              for (final label in groupCoverColors(l10n).values)
                Chip(label: Text(label)),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets(
    'showGroupSheet opens a full-height sheet with a handle, a Close button '
    'and the content; Close dismisses it with nothing and a choice inside '
    'hands back its value '
    '[case:groups.group_widgets.showmodalbottomsheet_open.action]',
    (tester) async {
      final results = <String?>[];
      await pumpQa(tester, GroupsWorld().api, _SheetHost(results: results));
      await qaTap(tester, qaKey('qa.test.sheet'));

      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      expect(tester.widget<BottomSheet>(sheet).showDragHandle, isTrue);
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.text('Any will do'), findsOneWidget);
      expect(find.text('First choice'), findsOneWidget);
      final close = qaKey('qa.sheet.close');
      expect(close, findsOneWidget);
      expect(
        tester.widget<IconButton>(close).tooltip,
        MaterialLocalizations.of(tester.element(close)).closeButtonTooltip,
      );

      await qaTap(tester, close);
      expect(sheet, findsNothing);
      expect(results, [null]);

      await qaTap(tester, qaKey('qa.test.sheet'));
      await qaTap(tester, qaKey('qa.test.pick'));
      expect(sheet, findsNothing);
      expect(results, [null, 'picked']);
    },
  );

  testWidgets(
    'the group cover, card and cover colour wording renders translated in '
    'every locale with nothing left in English '
    '[case:groups.group_widgets.l10n]',
    (tester) async {
      await qaExpectRendersInAllLocales(
        tester,
        GroupsWorld().api,
        () => const _Gallery(),
        expected: [
          (l) => l.groupsCardRemoved,
          (l) => l.groupsKindPrivate,
          (l) => l.chatMemberCount(4),
          (l) => l.chatMemberCount(3),
          (l) => l.groupsCoverColorTheme,
          (l) => l.groupsCoverColorAccent,
          (l) => l.groupsCoverColorWarm,
        ],
        // Fixture data: group names, the server's lifestyle title and city.
        // "Accent" and "Warm" are the French / Dutch and German / Dutch words
        // too (the arb files carry them as the translations).
        allow: {'Trek planners', 'Koramangala readers', 'Accent', 'Warm'},
      );
    },
  );
}
