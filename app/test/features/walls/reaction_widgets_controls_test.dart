import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_data.dart';
import 'package:verified_dating_app/features/walls/reaction_widgets.dart';

import '../../support/qa_api.dart';

// Reaction picker controls: the sheet a member opens from a photo's (or a
// chapter's) heart to say how it made them feel. The picker itself hands
// the chosen reaction back to its opener; these tests assert both what it
// returns and what the photo's like button then sends and shows.

/// A 1x1 transparent PNG, standing in for a member's photo bytes.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

Map<String, dynamic> _entry({
  int likes = 3,
  bool liked = false,
  String reaction = '',
  Map<String, int> reactions = const {},
}) => {
  'id': 'e1',
  'theme_id': 't1',
  'author_id': 'priya',
  'author_name': 'Priya Sharma',
  'caption': 'Pancakes, then nowhere to be.',
  'alt_text': 'A stack of pancakes on a balcony table',
  'created_at': '2026-09-28T10:15:00Z',
  'mine': false,
  'theme_title': 'My perfect Sunday',
  'like_count': likes,
  'liked_by_me': liked,
  'my_reaction': reaction,
  'reactions': reactions,
  'comment_count': 0,
  'pending_comment_count': 0,
};

Finder _key(String key) => find.byKey(ValueKey(key));

/// Opens the picker from a plain button and records what it hands back.
class _PickerHost extends StatelessWidget {
  const _PickerHost({required this.current, required this.results});
  final String current;
  final List<String?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const ValueKey('qa.test.react'),
        onPressed: () async => results.add(
          await showReactionPicker(context, current: current, noun: 'photo'),
        ),
        child: const Text('react'),
      ),
    ),
  );
}

Future<List<String?>> _openPicker(
  WidgetTester tester, {
  String current = '',
  Size size = const Size(430, 932),
  Locale? locale,
}) async {
  final results = <String?>[];
  await pumpQa(
    tester,
    QaApi(),
    _PickerHost(current: current, results: results),
    size: size,
    locale: locale,
  );
  await tester.tap(_key('qa.test.react'));
  await tester.pumpAndSettle();
  return results;
}

/// A photo's sheet, as the gallery and Today open it, on a fake BFF that
/// answers likes like the server does.
QaApi _photoApi({Map<String, dynamic>? saved}) {
  final api = QaApi()
    ..on('GET /themes/t1/entries/e1/photo', (_) => qaOk(_png))
    ..json('GET /themes/t1/entries/e1/comments', {'comments': <dynamic>[]})
    ..on('PUT /themes/t1/entries/e1/like', (c) {
      final reaction = c.body['reaction'] as String? ?? 'love';
      return qaOk({
        'entry': _entry(
          likes: 4,
          liked: true,
          reaction: reaction,
          reactions: {reaction: 1},
        ),
      });
    })
    ..on(
      'DELETE /themes/t1/entries/e1/like',
      (_) => qaOk({'entry': _entry(likes: 4)}),
    );
  return api;
}

Future<void> _openSheet(
  WidgetTester tester,
  QaApi api,
  Map<String, dynamic> entry,
) => pumpQa(
  tester,
  api,
  Scaffold(body: ThemeEntrySheet(entry: ThemeEntry.fromJson(entry))),
  size: const Size(430, 1400),
);

Finder _likeLabel(String count) =>
    find.descendant(of: _key('photo.like.e1'), matching: find.text(count));

void main() {
  testWidgets('the picker opens with all six reactions, marks the current one '
      'and offers to take it back '
      '[case:walls.reaction_widgets.showmodalbottomsheet_open.action]', (
    tester,
  ) async {
    final l10n = qaL10n(const Locale('en'));
    final results = await _openPicker(tester, current: 'hear_you');
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(ReactionPicker), findsOneWidget);
    expect(find.text(l10n.wallsReactEyebrow), findsOneWidget);
    expect(find.text('How does this photo make you feel?'), findsOneWidget);
    expect(find.text(l10n.wallsReactBody), findsOneWidget);
    for (final (id, emoji, label) in [
      ('love', '❤️', 'Love this'),
      ('hear_you', '🫶', 'I hear you'),
      ('me_too', '🙋', 'Me too'),
      ('with_you', '🤝', 'I’m with you'),
      ('hug', '🫂', 'Sending a hug'),
      ('proud', '🌟', 'Proud of you'),
    ]) {
      final option = _key('reaction.option.$id');
      expect(option, findsOneWidget, reason: id);
      expect(
        find.descendant(of: option, matching: find.text(emoji)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: option, matching: find.text(label)),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(option),
        containsSemantics(
          label: label,
          isButton: true,
          isSelected: id == 'hear_you',
        ),
        reason: id,
      );
    }
    expect(_key('reaction.remove'), findsOneWidget);
    expect(find.text('Take my reaction back'), findsOneWidget);
    expect(results, isEmpty, reason: 'still open');
  });

  testWidgets('without a current reaction there is nothing to take back, and '
      'dismissing hands back nothing '
      '[case:walls.reaction_widgets.showmodalbottomsheet_open.dismiss]', (
    tester,
  ) async {
    final results = await _openPicker(tester);
    expect(_key('reaction.remove'), findsNothing);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionPicker), findsNothing);
    expect(results, [null]);
  });

  testWidgets('choosing a reaction closes the sheet and hands back its id; on '
      'a photo it is sent as the like and shown on the heart '
      '[case:walls.reaction_widgets.reaction_option_x.action]', (tester) async {
    final results = await _openPicker(tester);
    await tester.tap(_key('reaction.option.me_too'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionPicker), findsNothing);
    expect(results, ['me_too']);

    final api = _photoApi();
    await _openSheet(tester, api, _entry());
    expect(_likeLabel('3'), findsOneWidget);
    await tester.tap(_key('photo.like.e1.react'));
    await tester.pumpAndSettle();
    expect(find.text('How does this photo make you feel?'), findsOneWidget);
    await tester.tap(_key('reaction.option.hear_you'));
    await tester.pumpAndSettle();

    expect(find.byType(ReactionPicker), findsNothing);
    expect(api.writeLines, ['PUT /themes/t1/entries/e1/like']);
    expect(api.writes.single.body, {'reaction': 'hear_you'});
    // The heart becomes the chosen emoji with the confirmed count, and the
    // summary counts the reaction.
    expect(_likeLabel('4'), findsOneWidget);
    expect(
      find.descendant(of: _key('photo.like.e1'), matching: find.text('🫶')),
      findsOneWidget,
    );
    expect(find.text('🫶 1'), findsOneWidget);
    expect(qaSnackText(tester), isNull);
  });

  testWidgets('Take my reaction back closes the sheet with an empty answer and '
      'removes the like on the server '
      '[case:walls.reaction_widgets.reaction_remove.action]', (tester) async {
    final results = await _openPicker(tester, current: 'hug');
    await tester.tap(_key('reaction.remove'));
    await tester.pumpAndSettle();
    expect(find.byType(ReactionPicker), findsNothing);
    expect(results, ['']);

    final api = _photoApi();
    await _openSheet(
      tester,
      api,
      _entry(likes: 5, liked: true, reaction: 'hug', reactions: {'hug': 2}),
    );
    expect(find.text('🫂 2'), findsOneWidget);
    await tester.tap(_key('photo.like.e1.react'));
    await tester.pumpAndSettle();
    await tester.tap(_key('reaction.remove'));
    await tester.pumpAndSettle();

    expect(api.writeLines, ['DELETE /themes/t1/entries/e1/like']);
    expect(_likeLabel('4'), findsOneWidget);
    expect(find.text('🫂 2'), findsNothing);
    expect(
      find.descendant(
        of: _key('photo.like.e1'),
        matching: find.byIcon(Icons.favorite_border_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('regression: the photo sheet\'s reaction summary follows the '
      'member\'s reaction at once (it watched only the notifier and went '
      'stale) [case:walls.reaction_widgets.reaction_summary.action]', (
    tester,
  ) async {
    final api = _photoApi();
    await _openSheet(tester, api, _entry(likes: 2, reactions: {'hug': 2}));
    expect(find.text('🫂 2'), findsOneWidget);
    expect(find.text('🙋 1'), findsNothing);

    await tester.tap(_key('photo.like.e1.react'));
    await tester.pumpAndSettle();
    await tester.tap(_key('reaction.option.me_too'));
    // The optimistic state shows before the server answers.
    await tester.pump();
    expect(find.text('🙋 1'), findsOneWidget);
    await tester.pumpAndSettle();
    // Then the confirmed tally from the server.
    expect(find.text('🙋 1'), findsOneWidget);
    expect(find.text('🫂 2'), findsNothing);
    expect(api.writes.single.body, {'reaction': 'me_too'});

    // Taking the like back clears it from the summary too.
    await tester.tap(_key('photo.like.e1'));
    await tester.pumpAndSettle();
    expect(api.writeLines.last, 'DELETE /themes/t1/entries/e1/like');
    expect(find.text('🙋 1'), findsNothing);
  });

  testWidgets('a refused reaction rolls the heart back and explains; retry '
      'sends it once more '
      '[case:walls.reaction_widgets.reaction_option_x.api_failure]', (
    tester,
  ) async {
    final api = _photoApi()
      ..fail(
        'PUT /themes/t1/entries/e1/like',
        status: 403,
        message: 'Reactions are paused for this photo.',
      );
    await _openSheet(tester, api, _entry());
    await tester.tap(_key('photo.like.e1.react'));
    await tester.pumpAndSettle();
    await tester.tap(_key('reaction.option.proud'));
    await tester.pumpAndSettle();

    expect(qaSnackText(tester), 'Reactions are paused for this photo.');
    expect(_likeLabel('3'), findsOneWidget);
    expect(find.text('🌟'), findsNothing);
    expect(api.sent('PUT', '/themes/t1/entries/e1/like'), hasLength(1));
    expect(
      tester.widget<IconButton>(_key('photo.like.e1.react')).onPressed,
      isNotNull,
    );

    // Offline: the local-build wording.
    api.offline('PUT /themes/t1/entries/e1/like');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(_key('photo.like.e1.react'));
    await tester.pumpAndSettle();
    await tester.tap(_key('reaction.option.proud'));
    await tester.pumpAndSettle();
    expect(
      qaSnackText(tester),
      qaL10n(const Locale('en')).networkOfflineTryAgain,
    );
    expect(_likeLabel('3'), findsOneWidget);
    expect(api.sent('PUT', '/themes/t1/entries/e1/like'), hasLength(2));
  });

  testWidgets('regression: the picker fits a small phone in every language '
      'with a reaction already chosen, and an option below the fold can be '
      'reached and picked '
      '[case:walls.reaction_widgets.small_screen.layout]', (tester) async {
    for (final locale in qaLocales) {
      for (final size in const [Size(360, 800), Size(390, 844)]) {
        final results = await _openPicker(
          tester,
          current: 'hear_you',
          size: size,
          locale: locale,
        );
        expect(tester.takeException(), isNull, reason: '$locale $size');
        final remove = _key('reaction.remove');
        await tester.ensureVisible(remove);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale $size');
        final proud = _key('reaction.option.proud');
        await tester.ensureVisible(proud);
        await tester.pumpAndSettle();
        await tester.tap(proud);
        await tester.pumpAndSettle();
        expect(results, ['proud'], reason: '$locale $size');
        await tester.pumpWidget(const SizedBox());
      }
    }
  });

  testWidgets('the picker renders translated in every locale '
      '[case:walls.reaction_widgets.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await _openPicker(tester, current: 'love', locale: locale);
      final l10n = qaL10n(locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.wallsReactEyebrow), findsOneWidget);
      expect(find.text(l10n.wallsReactQuestion('photo')), findsOneWidget);
      expect(find.text(l10n.wallsReactionHearYou), findsOneWidget);
      expect(find.text(l10n.wallsReactionProud), findsOneWidget);
      expect(find.text(l10n.wallsReactRemove), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
