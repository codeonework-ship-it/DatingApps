// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/telemetry/client_error_reporter.dart';
import 'package:verified_dating_app/features/common/screens/blocked_users_screen.dart';
import 'package:verified_dating_app/features/common/screens/emergency_contacts_screen.dart';
import 'package:verified_dating_app/features/common/screens/moderation_appeals_screen.dart';
import 'package:verified_dating_app/features/common/screens/privacy_safety_screen.dart';
import 'package:verified_dating_app/features/safety/screens/sos_screen.dart';

import '../../support/qa_api.dart';

// Privacy & Safety: every switch is saved to the account with the request
// the server expects, moves back and explains when saving fails, and stays
// usable afterwards. Navigation rows open their screens (whose internals the
// safety suites cover).

/// The member's account as the fake server holds it.
class _Account {
  _Account() {
    api
      ..on(
        'GET /settings/me',
        (_) => qaOk({
          'settings': {...settings},
        }),
      )
      ..on('PATCH /settings/me', (c) {
        settings.addAll(c.body);
        return qaOk({
          'settings': {...settings},
        });
      })
      ..on(
        'GET /friends/me/search-visibility',
        (_) => qaOk({'visible': friendSearch}),
      )
      ..on('PUT /friends/me/search-visibility', (c) {
        friendSearch = c.body['visible'] == true;
        return qaOk({'visible': friendSearch});
      })
      ..on(
        'GET /profile/me/showcase/consent',
        (_) => qaOk({'visible': showcase}),
      )
      ..on('PUT /profile/me/showcase/consent', (c) {
        showcase = c.body['visible'] == true;
        return qaOk({'visible': showcase});
      })
      ..on('GET /account/me/discovery/pause', (_) => qaOk(_pause()))
      ..on('POST /account/me/discovery/pause', (_) {
        paused = true;
        return qaOk(_pause());
      })
      ..on('POST /account/me/discovery/resume', (_) {
        paused = false;
        return qaOk(_pause());
      });
    // Screens opened from the navigation rows load their own data.
    for (var depth = 1; depth <= 5; depth++) {
      api.json('GET ${List.filled(depth, '/*').join()}', <String, dynamic>{});
    }
  }

  final api = QaApi();
  final settings = <String, dynamic>{
    'show_age': true,
    'show_exact_distance': false,
    'show_online_status': true,
    'notify_new_match': true,
    'notify_new_message': true,
    'notify_likes': true,
    'theme': 'light',
    'locale': '',
  };
  bool friendSearch = true;
  bool showcase = false;
  bool paused = false;

  Map<String, dynamic> _pause() => paused
      ? {
          'paused': true,
          'pause': {'reason': 'manual', 'paused_at': '2026-10-02T09:00:00Z'},
        }
      : {'paused': false};
}

Future<void> _open(
  WidgetTester tester,
  _Account account, {
  Locale? locale,
}) async {
  final reporter = ClientErrorReporter(
    store: MemoryClientErrorStore(),
    transport: (body, {bearerToken}) async =>
        const ClientErrorTransportResponse(statusCode: 202),
    enabled: true,
    observeLifecycle: false,
  );
  addTearDown(reporter.dispose);
  await pumpQa(
    tester,
    account.api,
    const PrivacySafetyScreen(),
    locale: locale,
    extra: [clientErrorReporterProvider.overrideWithValue(reporter)],
  );
}

SwitchListTile _switch(WidgetTester tester, String key) =>
    tester.widget<SwitchListTile>(find.byKey(ValueKey(key)));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey(key)));
  await qaSettle(tester, frames: 6);
}

void main() {
  final en = qaL10n(const Locale('en'));

  // Show age / exact distance / online status: PATCH /settings/{me}.
  for (final (name, key, field) in const [
    ('show_age', 'qa.privacy.show_age', 'show_age'),
    (
      'show_exact_distance',
      'qa.privacy.show_exact_distance',
      'show_exact_distance',
    ),
    (
      'show_online_status',
      'qa.privacy.show_online_status',
      'show_online_status',
    ),
  ]) {
    testWidgets('$key saves both directions and only itself '
        '[case:common.privacy_safety.$name.action]', (tester) async {
      final account = _Account();
      await _open(tester, account);
      final before = _switch(tester, key).value;
      expect(before, account.settings[field]);

      await _tap(tester, key);
      expect(account.api.sent('PATCH', '/settings/me').single.body, {
        field: !before,
      });
      expect(_switch(tester, key).value, !before);
      expect(account.settings[field], !before);

      await _tap(tester, key);
      expect(account.api.sent('PATCH', '/settings/me').last.body, {
        field: before,
      });
      expect(_switch(tester, key).value, before);
      expect(account.api.sent('PATCH', '/settings/me'), hasLength(2));
      expect(qaSnackText(tester), isNull);
    });

    testWidgets('$key refused by the server goes back and explains '
        '[case:common.privacy_safety.$name.api_failure]', (tester) async {
      final account = _Account();
      account.api.fail(
        'PATCH /settings/me',
        status: 500,
        message: 'Privacy settings are read-only right now.',
      );
      await _open(tester, account);
      final before = _switch(tester, key).value;

      await _tap(tester, key);

      expect(account.api.sent('PATCH', '/settings/me'), hasLength(1));
      expect(qaSnackText(tester), 'Privacy settings are read-only right now.');
      // The switch shows what the account really has, and still works.
      expect(_switch(tester, key).value, before);
      expect(_switch(tester, key).onChanged, isNotNull);
      expect(account.settings[field], before);
    });
  }

  testWidgets(
    'offline: a privacy switch goes back and says the service is unreachable '
    '[case:common.privacy_safety.show_age.api_failure]',
    (tester) async {
      final account = _Account();
      account.api.offline('PATCH /settings/me');
      await _open(tester, account);

      await _tap(tester, 'qa.privacy.show_age');

      expect(qaSnackText(tester), en.networkOfflineTryAgain);
      expect(_switch(tester, 'qa.privacy.show_age').value, isTrue);
      expect(_switch(tester, 'qa.privacy.show_age').onChanged, isNotNull);

      // Back online: the same switch saves.
      account.api.on('PATCH /settings/me', (c) {
        account.settings.addAll(c.body);
        return qaOk({
          'settings': {...account.settings},
        });
      });
      await _tap(tester, 'qa.privacy.show_age');
      expect(account.settings['show_age'], isFalse);
      expect(_switch(tester, 'qa.privacy.show_age').value, isFalse);
    },
  );

  // Regression (2026-10-02): the privacy switches PATCHed every setting
  // from the copy loaded when the screen first opened, so a theme picked in
  // Settings or a notification switched off in Notifications since then was
  // silently put back on the account.
  testWidgets(
    'a privacy switch never overwrites the theme, language or notification '
    'choices saved elsewhere [case:common.privacy_safety.show_online_status.action]',
    (tester) async {
      final account = _Account();
      await _open(tester, account);
      // Meanwhile, elsewhere in the app:
      account.settings
        ..['theme'] = 'dark:snow'
        ..['locale'] = 'de'
        ..['notify_new_match'] = false;

      await _tap(tester, 'qa.privacy.show_online_status');

      expect(account.api.sent('PATCH', '/settings/me').single.body, {
        'show_online_status': false,
      });
      expect(account.settings['theme'], 'dark:snow');
      expect(account.settings['locale'], 'de');
      expect(account.settings['notify_new_match'], isFalse);
    },
  );

  testWidgets('Retry reloads the settings after a failed load '
      '[case:common.privacy_safety.retry.action]', (tester) async {
    final account = _Account();
    account.api.fail('GET /settings/me', status: 503);
    await _open(tester, account);
    expect(find.byKey(const ValueKey('qa.privacy.retry')), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.privacy.show_age')), findsNothing);

    account.api.on(
      'GET /settings/me',
      (_) => qaOk({
        'settings': {...account.settings},
      }),
    );
    await tester.tap(find.byKey(const ValueKey('qa.privacy.retry')));
    await qaSettle(tester, frames: 5);

    expect(account.api.sent('GET', '/settings/me'), hasLength(2));
    expect(find.byKey(const ValueKey('qa.privacy.retry')), findsNothing);
    expect(_switch(tester, 'qa.privacy.show_age').value, isTrue);
    expect(_switch(tester, 'qa.privacy.show_exact_distance').value, isFalse);
  });

  testWidgets('Retry while the server is still down keeps Retry available '
      '[case:common.privacy_safety.retry.api_failure]', (tester) async {
    final account = _Account();
    account.api.offline('GET /settings/me');
    await _open(tester, account);

    await tester.tap(find.byKey(const ValueKey('qa.privacy.retry')));
    await qaSettle(tester, frames: 5);

    expect(account.api.sent('GET', '/settings/me'), hasLength(2));
    expect(find.byKey(const ValueKey('qa.privacy.retry')), findsOneWidget);
  });

  for (final (name, key, screen) in const [
    ('safety_sos_journey', 'qa.safety.sos_journey', SosScreen),
    (
      'emergency_contacts',
      'qa.privacy.emergency_contacts',
      EmergencyContactsScreen,
    ),
    ('blocked_users', 'qa.privacy.blocked_users', BlockedUsersScreen),
    (
      'moderation_appeals',
      'qa.privacy.moderation_appeals',
      ModerationAppealsScreen,
    ),
  ]) {
    testWidgets('$key opens $screen '
        '[case:common.privacy_safety.$name.action]', (tester) async {
      await _open(tester, _Account());
      expect(find.byType(screen), findsNothing);
      await _tap(tester, key);
      expect(find.byType(screen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'friend search: PUT /friends/{me}/search-visibility both directions '
    '[case:common.privacy_safety.privacy_friend_search.action]',
    (tester) async {
      final account = _Account();
      await _open(tester, account);
      const key = 'qa.privacy.friend_search';
      expect(_switch(tester, key).value, isTrue);

      await _tap(tester, key);
      expect(_switch(tester, key).value, isFalse);
      await _tap(tester, key);
      expect(_switch(tester, key).value, isTrue);

      final puts = account.api.sent('PUT', '/friends/me/search-visibility');
      expect(puts.map((c) => c.body), [
        {'visible': false},
        {'visible': true},
      ]);
      // Friend search never touches the profile showcase choice.
      expect(account.api.sent('PUT', '/profile/me/showcase/consent'), isEmpty);
      expect(account.friendSearch, isTrue);
    },
  );

  testWidgets(
    'friend search refused: the switch goes back and the server says why '
    '[case:common.privacy_safety.privacy_friend_search.api_failure]',
    (tester) async {
      final account = _Account();
      account.api.fail(
        'PUT /friends/me/search-visibility',
        status: 503,
        message: 'Friends are temporarily unavailable.',
      );
      await _open(tester, account);
      const key = 'qa.privacy.friend_search';

      await _tap(tester, key);

      expect(
        account.api.sent('PUT', '/friends/me/search-visibility'),
        hasLength(1),
      );
      expect(_switch(tester, key).value, isTrue);
      expect(_switch(tester, key).onChanged, isNotNull);
      expect(qaSnackText(tester), 'Friends are temporarily unavailable.');
    },
  );

  testWidgets(
    'friend search offline: the switch goes back with a translated message '
    '[case:common.privacy_safety.privacy_friend_search.api_failure]',
    (tester) async {
      final account = _Account();
      account.api.offline('PUT /friends/me/search-visibility');
      await _open(tester, account);

      await _tap(tester, 'qa.privacy.friend_search');

      expect(_switch(tester, 'qa.privacy.friend_search').value, isTrue);
      expect(qaSnackText(tester), en.networkOfflineTryAgain);
    },
  );

  testWidgets(
    'profile showcase: PUT /profile/{me}/showcase/consent both directions '
    '[case:common.privacy_safety.privacy_profile_showcase.action]',
    (tester) async {
      final account = _Account();
      await _open(tester, account);
      const key = 'qa.privacy.profile_showcase';
      expect(_switch(tester, key).value, isFalse);

      await _tap(tester, key);
      expect(_switch(tester, key).value, isTrue);
      expect(account.showcase, isTrue);
      await _tap(tester, key);
      expect(_switch(tester, key).value, isFalse);

      expect(
        account.api
            .sent('PUT', '/profile/me/showcase/consent')
            .map((c) => c.body),
        [
          {'visible': true},
          {'visible': false},
        ],
      );
      expect(qaSnackText(tester), isNull);
    },
  );

  testWidgets('profile showcase refused: the switch goes back and explains '
      '[case:common.privacy_safety.privacy_profile_showcase.api_failure]', (
    tester,
  ) async {
    final account = _Account();
    account.api.fail('PUT /profile/me/showcase/consent', status: 500);
    await _open(tester, account);
    const key = 'qa.privacy.profile_showcase';

    await _tap(tester, key);

    expect(
      account.api.sent('PUT', '/profile/me/showcase/consent'),
      hasLength(1),
    );
    expect(_switch(tester, key).value, isFalse);
    expect(_switch(tester, key).onChanged, isNotNull);
    expect(qaSnackText(tester), 'Something broke on our side.');
    expect(account.showcase, isFalse);
  });

  testWidgets('Pause hides the member from discovery; Resume brings them back '
      '[case:common.privacy_safety.graduation_discovery_pause.action] '
      '[case:common.privacy_safety.graduation_discovery_resume.action]', (
    tester,
  ) async {
    final account = _Account();
    await _open(tester, account);
    expect(find.text(en.privacyDiscoveryActive), findsOneWidget);
    expect(find.text(en.privacyActiveReason), findsOneWidget);

    await _tap(tester, 'qa.graduation.discovery_pause');
    expect(
      account.api.sent('POST', '/account/me/discovery/pause').single.body,
      {'reason': 'manual'},
    );
    expect(find.text(en.privacyDiscoveryPaused), findsOneWidget);
    expect(find.text(en.privacyPausedReason), findsOneWidget);
    expect(
      find.byKey(const ValueKey('qa.graduation.discovery_pause')),
      findsNothing,
    );

    await _tap(tester, 'qa.graduation.discovery_resume');
    expect(
      account.api.sent('POST', '/account/me/discovery/resume').single.body,
      <String, dynamic>{},
    );
    expect(find.text(en.privacyDiscoveryActive), findsOneWidget);
    expect(
      find.byKey(const ValueKey('qa.graduation.discovery_pause')),
      findsOneWidget,
    );
    expect(account.paused, isFalse);
  });

  testWidgets(
    'Pause refused: discovery stays active, the reason shows, Pause works again '
    '[case:common.privacy_safety.graduation_discovery_pause.api_failure]',
    (tester) async {
      final account = _Account();
      account.api.fail(
        'POST /account/me/discovery/pause',
        status: 409,
        message: 'Discovery cannot be paused during a review.',
      );
      await _open(tester, account);

      await _tap(tester, 'qa.graduation.discovery_pause');

      expect(
        account.api.sent('POST', '/account/me/discovery/pause'),
        hasLength(1),
      );
      expect(
        find.text('Discovery cannot be paused during a review.'),
        findsOneWidget,
      );
      expect(find.text(en.privacyDiscoveryActive), findsOneWidget);
      final pause = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('qa.graduation.discovery_pause')),
      );
      expect(pause.onPressed, isNotNull);
    },
  );

  testWidgets('Resume offline: discovery stays paused with a translated reason '
      '[case:common.privacy_safety.graduation_discovery_resume.api_failure]', (
    tester,
  ) async {
    final account = _Account()..paused = true;
    account.api.offline('POST /account/me/discovery/resume');
    await _open(tester, account);
    expect(find.text(en.privacyDiscoveryPaused), findsOneWidget);

    await _tap(tester, 'qa.graduation.discovery_resume');

    expect(
      account.api.sent('POST', '/account/me/discovery/resume'),
      hasLength(1),
    );
    expect(find.text(en.privacyDiscoveryPaused), findsOneWidget);
    expect(find.text(en.networkOfflineTryAgain), findsOneWidget);
    final resume = tester.widget<FilledButton>(
      find.byKey(const ValueKey('qa.graduation.discovery_resume')),
    );
    expect(resume.onPressed, isNotNull);
  });

  testWidgets('Privacy & Safety renders in every shipped language '
      '[case:common.privacy_safety.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      await _open(tester, _Account(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.privacyTitle), findsOneWidget, reason: '$locale');
      expect(find.text(l10n.privacyShowAge), findsOneWidget, reason: '$locale');
      expect(
        find.text(l10n.privacyFriendSearch),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        find.text(l10n.privacyDiscoveryActive),
        findsOneWidget,
        reason: '$locale',
      );
    }
  });
}
