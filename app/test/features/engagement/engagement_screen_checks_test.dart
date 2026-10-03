// Case tags stay whole on one line for the static coverage scanner.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/circle_challenges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/conversation_rooms_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/daily_prompt_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/engagement_hub_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/group_coffee_polls_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/level_progression_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/match_nudges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_badges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_filter_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'rooms_qa_fixture.dart';

// Engagement screens with their data loaded from the recording fake BFF: no
// overflow at any shipped device size in either theme, Flutter's tap-target
// / label / contrast guidelines, and (for pushed screens) a Back control
// that really closes the screen. The Engage hub is a root tab, so it has no
// Back case.

Map<String, dynamic> _circle(String id, String topic, {bool joined = false}) =>
    {
      'circle_challenge': {
        'circle_id': id,
        'challenge': {
          'id': '$id-2026-W40',
          'city': 'Bengaluru',
          'topic': topic,
          'prompt_text': '$topic prompt of the week',
        },
        'participation_count': 12,
        'is_joined': joined,
        if (joined) 'user_entry': {'entry_text': '5k run'},
      },
    };

QaApi _circlesApi() => QaApi()
  ..json(
    'GET /engagement/circles/circle-blr-books/challenge',
    _circle('circle-blr-books', 'Books'),
  )
  ..json(
    'GET /engagement/circles/circle-blr-fitness/challenge',
    _circle('circle-blr-fitness', 'Fitness', joined: true),
  )
  ..json(
    'GET /engagement/circles/circle-blr-music/challenge',
    _circle('circle-blr-music', 'Music'),
  );

const _dailyPrompt = {
  'daily_prompt': {
    'prompt': {
      'id': 'dp-2026-10-02',
      'prompt_date': '2026-10-02',
      'domain': 'values',
      'prompt_text': 'What makes you feel respected?',
      'min_chars': 1,
      'max_chars': 240,
      'response_mode': 'text',
    },
    'streak': {
      'current_days': 2,
      'longest_days': 5,
      'last_answered_date': '2026-10-01',
      'next_milestone': 3,
      'milestone_reached': 0,
    },
    'spark': {
      'participants_today': 4,
      'similar_answer_count': 0,
      'similar_user_ids': <String>[],
    },
  },
};

QaApi _dailyPromptApi() => QaApi()
  ..json('GET /engagement/daily-prompt/me', _dailyPrompt)
  ..json('GET /engagement/daily-prompt/me/responders', {
    'responders': <Object>[],
    'pagination': {'has_more': false, 'next_offset': 0},
  });

QaApi _hubApi() => _dailyPromptApi()
  ..json('GET /billing/coexistence-matrix', {
    'core_progression_non_blocking': true,
    'features': <Object>[],
  });

QaApi _coffeeApi() => QaApi()
  ..json('GET /engagement/group-coffee-polls', {
    'polls': [
      {
        'id': 'poll-1',
        'creator_user_id': 'me',
        'participant_user_ids': ['me', 'ana'],
        'options': [
          {
            'id': 'opt-1',
            'day': 'Saturday',
            'time_window': '10:00-12:00',
            'neighborhood': 'Indiranagar',
            'votes_count': 1,
          },
          {
            'id': 'opt-2',
            'day': 'Sunday',
            'time_window': '11:00-13:00',
            'neighborhood': 'Koramangala',
            'votes_count': 0,
          },
        ],
        'status': 'open',
        'deadline_at': '2026-10-03T10:00:00Z',
        'finalized_option_id': '',
      },
    ],
  });

QaApi _levelApi() => QaApi()
  ..json('GET /progression/me', {
    'progression': {
      'total_xp': 320,
      'current_level': 3,
      'level_name': 'Reliable Participant',
      'current_level_xp': 70,
      'next_level_xp': 500,
      'progress_percent': 28,
      'trust_gate_satisfied': true,
      'progression_frozen': false,
      'projection_lag_seconds': 0,
      'levels': [
        {
          'level': 3,
          'name': 'Reliable Participant',
          'threshold_xp': 250,
          'trust_gate': false,
          'reward_summary': 'Weekly visibility micro-boost',
        },
      ],
      'rewards': [
        {
          'reward_key': 'starter_accent',
          'level': 2,
          'name': 'Starter accent',
          'description': 'A profile accent earned through activity.',
          'reward_type': 'cosmetic',
          'trust_required': false,
          'claimed': false,
        },
        {
          'reward_key': 'prompt_priority',
          'level': 5,
          'name': 'Prompt priority',
          'description': 'Compatible prompts first.',
          'reward_type': 'feature',
          'trust_required': true,
          'claimed': false,
        },
      ],
    },
  })
  ..json('GET /progression/me/ledger', {
    'entries': [
      {
        'sequence': 1,
        'source': 'daily_prompt_submitted',
        'awarded_xp': 20,
        'multiplier': 1,
        'occurred_at': '2026-10-01T10:00:00Z',
      },
    ],
  });

QaApi _nudgesApi() => QaApi()
  ..json('GET /matches/me', {
    'matches': [
      {'id': 'match-1', 'user_id': 'maya', 'user_name': 'Maya'},
      {'id': 'match-2', 'user_id': 'theo', 'user_name': 'Theo'},
    ],
  });

QaApi _badgesApi() => QaApi()
  ..json('GET /users/me/trust-badges', {
    'milestones': {'communication_score': 81},
    'badges': [
      {
        'badge_code': 'respectful_communicator',
        'badge_label': 'Respectful Communicator',
        'status': 'active',
        'awarded_at': '2026-09-30T10:00:00Z',
      },
    ],
    'history': [
      {
        'badge_code': 'respectful_communicator',
        'action': 'awarded',
        'reason': 'Kind replies for two weeks.',
        'happened_at': '2026-09-30T10:00:00Z',
      },
    ],
  });

QaApi _filterApi() => QaApi()
  ..json('GET /discovery/me/filters/trust', {
    'trust_filter': {
      'enabled': true,
      'minimum_active_badges': 1,
      'required_badge_codes': ['verified_active'],
    },
    'available_badges': [
      {'badge_code': 'prompt_completer', 'badge_label': 'Prompt Completer'},
      {
        'badge_code': 'respectful_communicator',
        'badge_label': 'Respectful Communicator',
      },
      {'badge_code': 'consistent_profile', 'badge_label': 'Consistent Profile'},
      {'badge_code': 'verified_active', 'badge_label': 'Verified & Active'},
    ],
  });

typedef _Screen = ({
  String slug,
  Type type,
  Widget Function() build,
  QaApi Function() api,
  Finder loaded,
  bool pushed,
  Size tall,
});

final _screens = <_Screen>[
  (
    slug: 'circle_challenges',
    type: CircleChallengesScreen,
    build: CircleChallengesScreen.new,
    api: _circlesApi,
    loaded: find.text('Books · Bengaluru'),
    pushed: true,
    tall: const Size(360, 1600),
  ),
  (
    slug: 'conversation_rooms',
    type: ConversationRoomsScreen,
    build: ConversationRoomsScreen.new,
    api: () => RoomsServer().api,
    loaded: find.text('Late-night talks'),
    pushed: true,
    tall: const Size(360, 1600),
  ),
  (
    slug: 'daily_prompt',
    type: DailyPromptScreen,
    build: DailyPromptScreen.new,
    api: _dailyPromptApi,
    loaded: find.text('What makes you feel respected?'),
    pushed: true,
    tall: const Size(360, 1600),
  ),
  (
    slug: 'engagement_hub',
    type: EngagementHubScreen,
    build: EngagementHubScreen.new,
    api: _hubApi,
    loaded: find.byKey(const ValueKey('qa.engagement_hub.trust_filters')),
    pushed: false,
    tall: const Size(360, 3400),
  ),
  (
    slug: 'group_coffee_polls',
    type: GroupCoffeePollsScreen,
    build: GroupCoffeePollsScreen.new,
    api: _coffeeApi,
    loaded: find.byKey(const ValueKey('qa.coffee.finalize.poll-1')),
    pushed: true,
    tall: const Size(360, 1800),
  ),
  (
    slug: 'level_progression',
    type: LevelProgressionScreen,
    build: LevelProgressionScreen.new,
    api: _levelApi,
    loaded: find.text('Reliable Participant'),
    pushed: true,
    tall: const Size(360, 1600),
  ),
  (
    slug: 'match_nudges',
    type: MatchNudgesScreen,
    build: MatchNudgesScreen.new,
    api: _nudgesApi,
    loaded: find.byKey(const ValueKey('qa.nudges.send.match-1')),
    pushed: true,
    tall: const Size(360, 1600),
  ),
  (
    slug: 'trust_badges',
    type: TrustBadgesScreen,
    build: TrustBadgesScreen.new,
    api: _badgesApi,
    loaded: find.text('Kind replies for two weeks.'),
    pushed: true,
    tall: const Size(360, 1600),
  ),
  (
    slug: 'trust_filter',
    type: TrustFilterScreen,
    build: TrustFilterScreen.new,
    api: _filterApi,
    loaded: find.byKey(const ValueKey('qa.trust_filter.badge.verified_active')),
    pushed: true,
    tall: const Size(360, 1600),
  ),
];

void main() {
  for (final s in _screens) {
    final slug = s.slug;
    testWidgets('${s.type} lays out with its data on every device size in both themes [case:engagement.$slug.layout_matrix]', (t) async {
      final api = s.api();
      await qaExpectLaysOutEverywhere(t, api, s.build, loaded: s.loaded);
      expect(api.writes, isEmpty, reason: 'rendering sends no commands');
    });

    testWidgets('${s.type} with its data meets the tap-target, label and contrast guidelines [case:engagement.$slug.a11y_guidelines]', (t) async {
      // Phone width; a long list is checked on a tall view so every card
      // (not only the first screenful) is judged.
      await qaExpectMeetsA11yGuidelines(
        t,
        s.api(),
        s.build,
        loaded: s.loaded,
        size: s.tall,
      );
    });

    if (s.pushed) {
      testWidgets('${s.type} pushed from another screen shows Back, which closes it [case:engagement.$slug.back_affordance]', (t) async {
        await qaExpectBackReturns(t, s.api(), s.build, screen: s.type);
      });
    }
  }

  testWidgets('LevelProgressionScreen error card (first load failed, and progress on screen with a failed ledger) meets the contrast guidelines in both themes [case:engagement.level_progression.a11y_guidelines]', (t) async {
    // Regression: the message and Retry used on-surface / primary on the
    // error container and failed text contrast.
    final firstLoad = _levelApi()
      ..fail('GET /progression/me', message: 'Progress is unavailable.');
    await qaExpectMeetsA11yGuidelines(
      t,
      firstLoad,
      LevelProgressionScreen.new,
      loaded: find.text('Progress is unavailable.'),
    );
    final ledger = _levelApi()
      ..fail('GET /progression/me/ledger', message: 'Ledger is rebuilding.');
    await qaExpectMeetsA11yGuidelines(
      t,
      ledger,
      LevelProgressionScreen.new,
      loaded: find.text('Ledger is rebuilding.'),
    );
  });
}
