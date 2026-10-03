import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/notifications/push_notification_service.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/screens/account_data_screen.dart';
import 'package:verified_dating_app/features/friends/screens/introducer_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';

import '../../support/qa_api.dart';

// The introducer workspace (friends who only introduce) and the member's
// "Your introducers" controls. Every command is asserted by its request,
// its visible result and its failure path.

class _Push extends PushNotificationService {
  _Push() : super(Dio());
  final unregistered = <String>[];
  @override
  Future<void> unregister(String userId) async => unregistered.add(userId);
}

Map<String, dynamic> _conn(String id, String user, String name, String s) => {
  'id': id,
  'user_id': user,
  'name': name,
  'status': s,
  'share_photo': false,
  'share_city': false,
};

class _World {
  _World({List<Map<String, dynamic>>? connections}) {
    if (connections != null) this.connections = connections;
    api
      ..on(
        'GET /introducer/connections',
        (_) => qaOk({'connections': this.connections}),
      )
      ..on(
        'GET /friends/*/intros',
        (_) => qaOk({'made': made, 'received': <dynamic>[]}),
      )
      ..on('POST /introducer/connections/*/approve', (c) {
        final id = c.path.split('/')[3];
        for (final row in this.connections) {
          if (row['id'] == id) row['status'] = 'active';
        }
        return qaOk({'success': true});
      })
      ..on('DELETE /introducer/connections/*', (c) {
        this.connections.removeWhere((r) => r['id'] == c.path.split('/')[3]);
        return qaOk({'success': true});
      })
      ..json('POST /introducer/invites', {
        'code': 'kind-otter-42',
        'expires_at': '2026-10-04T00:00:00Z',
      })
      ..json('DELETE /introducer/invites', {'success': true})
      ..json('POST /introducer/redeem', {'success': true})
      ..json('POST /friends/*/intros', {'success': true})
      ..json('POST /auth/logout', {'success': true});
  }

  final api = QaApi();
  List<Map<String, dynamic>> connections = [
    _conn('perm-alice', 'alice', 'Alice', 'pending'),
  ];
  final made = <Map<String, dynamic>>[];
}

Future<void> _show(
  WidgetTester tester,
  _World world, {
  bool member = false,
  Locale? locale,
  List<Override> extra = const [],
}) => pumpQa(
  tester,
  world.api,
  IntroducerScreen(memberControls: member),
  userId: member ? 'me' : 'friend',
  accountKind: member ? 'dating' : 'introducer',
  size: const Size(600, 2600),
  locale: locale,
  extra: extra,
);

/// Settles animations and the provider reloads they trigger (a reload
/// started in the last frame leaves a zero-length Dio timer behind).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pumpAndSettle();
    await tester.pump();
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await _settle(tester);
  await tester.tap(find.text(text).last);
  await _settle(tester);
}

String get _saveFailed =>
    qaL10n(const Locale('en')).friendsIntroducerSaveFailed;

void main() {
  setUp(AuthSessionStore.instance.clear);
  tearDown(AuthSessionStore.instance.clear);

  group('member: Your introducers', () {
    testWidgets('Allow introductions approves the request and says so '
        '[case:friends.introducer.allow_introductions.action]', (tester) async {
      final world = _World();
      await _show(tester, world, member: true);
      expect(
        find.text('Wants your permission to introduce you.'),
        findsOneWidget,
      );
      await _tapText(tester, 'Allow introductions');
      expect(world.api.writeLines, [
        'POST /introducer/connections/perm-alice/approve',
      ]);
      expect(find.text('Alice now has your permission.'), findsOneWidget);
      expect(find.text('Permission to suggest introductions.'), findsOneWidget);
      expect(find.text('Allow introductions'), findsNothing);
    });

    testWidgets('a failed Allow explains, keeps the request and can be retried '
        '[case:friends.introducer.allow_introductions.api_failure]', (
      tester,
    ) async {
      final world = _World()
        ..api.fail(
          'POST /introducer/connections/*/approve',
          status: 410,
          message: 'This request expired.',
        );
      await _show(tester, world, member: true);
      await _tapText(tester, 'Allow introductions');
      expect(find.text('This request expired.'), findsOneWidget);
      expect(find.text('Allow introductions'), findsOneWidget);

      world.api.on(
        'POST /introducer/connections/*/approve',
        (_) => const QaReply(500, null),
      );
      await _tapText(tester, 'Allow introductions');
      expect(find.text(_saveFailed), findsOneWidget);
      expect(
        world.api.sent('POST', '/introducer/connections/perm-alice/approve'),
        hasLength(2),
      );
    });

    testWidgets('Decline request asks, then removes the pending request '
        '[case:friends.introducer.decline_request.action]', (tester) async {
      final world = _World();
      await _show(tester, world, member: true);
      await _tapText(tester, 'Decline request');
      expect(find.text('Remove permission for Alice?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove permission'));
      await _settle(tester);
      expect(world.api.writeLines, [
        'DELETE /introducer/connections/perm-alice',
      ]);
      expect(find.text('Permission removed.'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      expect(
        find.text(
          'No introducers yet. Share an invitation with one trusted friend '
          'to get started.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a failed Decline keeps the request and explains '
        '[case:friends.introducer.decline_request.api_failure]', (
      tester,
    ) async {
      final world = _World()..api.offline('DELETE /introducer/connections/*');
      await _show(tester, world, member: true);
      await _tapText(tester, 'Decline request');
      await tester.tap(find.widgetWithText(FilledButton, 'Remove permission'));
      await _settle(tester);
      expect(
        find.text(qaL10n(const Locale('en')).networkOfflineTryAgain),
        findsOneWidget,
      );
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('the preview switches decide what the invitation shares '
        '[case:friends.introducer.include_my_profile_photo.action] '
        '[case:friends.introducer.include_my_city.action]', (tester) async {
      final world = _World();
      await _show(tester, world, member: true);
      await _tapText(tester, 'Include my profile photo');
      await _tapText(tester, 'Include my city');
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches.map((s) => s.value), [true, true]);
      await _tapText(tester, 'Create invitation code');
      expect(world.api.sent('POST', '/introducer/invites').single.body, {
        'share_photo': true,
        'share_city': true,
      });
    });

    testWidgets(
      'Create invitation code shows the one-time code, locks the preview and '
      'confirms [case:friends.introducer.create_invitation_code.action] '
      '[case:friends.introducer.selectabletext_input_input.action]',
      (tester) async {
        final world = _World();
        await _show(tester, world, member: true);
        await _tapText(tester, 'Create invitation code');
        expect(world.api.sent('POST', '/introducer/invites').single.body, {
          'share_photo': false,
          'share_city': false,
        });
        expect(
          find.text(
            'Invitation ready. Any previous unused code no longer works.',
          ),
          findsOneWidget,
        );
        final code = tester.widget<SelectableText>(find.byType(SelectableText));
        expect(code.data, 'kind-otter-42');
        // The preview can't change under an issued code.
        for (final s in tester.widgetList<SwitchListTile>(
          find.byType(SwitchListTile),
        )) {
          expect(s.onChanged, isNull);
        }
      },
    );

    testWidgets(
      'the code is shown exactly as issued (unicode kept) and cannot be '
      'edited [case:friends.introducer.selectabletext_input_input.validation]',
      (tester) async {
        final world = _World()
          ..api.json('POST /introducer/invites', {'code': 'zoë-Ω-7'});
        await _show(tester, world, member: true);
        await _tapText(tester, 'Create invitation code');
        expect(find.text('zoë-Ω-7'), findsOneWidget);
        expect(find.byType(EditableText), findsOneWidget, reason: 'read-only');
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.readOnly, isTrue);
      },
    );

    testWidgets('a failed Create shows why and no code '
        '[case:friends.introducer.create_invitation_code.api_failure]', (
      tester,
    ) async {
      final world = _World()
        ..api.fail(
          'POST /introducer/invites',
          status: 429,
          message: 'Too many invitations today.',
        );
      await _show(tester, world, member: true);
      await _tapText(tester, 'Create invitation code');
      expect(find.text('Too many invitations today.'), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);
      expect(find.text('Copy code'), findsNothing);
    });

    testWidgets('Copy code puts the code on the clipboard and confirms '
        '[case:friends.introducer.copy_code.action]', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final world = _World();
      await _show(tester, world, member: true);
      await _tapText(tester, 'Create invitation code');
      await _tapText(tester, 'Copy code');
      expect(copied, ['kind-otter-42']);
      expect(find.text('Invitation code copied'), findsOneWidget);
    });

    testWidgets(
      'Cancel unused invitations revokes the code and unlocks the preview '
      '[case:friends.introducer.cancel_unused_invitations.action]',
      (tester) async {
        final world = _World();
        await _show(tester, world, member: true);
        await _tapText(tester, 'Create invitation code');
        await _tapText(tester, 'Cancel unused invitations');
        expect(world.api.writeLines.last, 'DELETE /introducer/invites');
        expect(find.text('Unused invitations cancelled.'), findsOneWidget);
        expect(find.byType(SelectableText), findsNothing);
        for (final s in tester.widgetList<SwitchListTile>(
          find.byType(SwitchListTile),
        )) {
          expect(s.onChanged, isNotNull);
        }
      },
    );

    testWidgets('a failed Cancel keeps the code and explains '
        '[case:friends.introducer.cancel_unused_invitations.api_failure]', (
      tester,
    ) async {
      final world = _World();
      await _show(tester, world, member: true);
      await _tapText(tester, 'Create invitation code');
      world.api.on(
        'DELETE /introducer/invites',
        (_) => const QaReply(500, null),
      );
      await _tapText(tester, 'Cancel unused invitations');
      expect(find.text(_saveFailed), findsOneWidget);
      expect(find.text('kind-otter-42'), findsOneWidget);
    });

    testWidgets(
      'Manage all introduction preferences opens Dating rhythm and reloads '
      'permissions on return '
      '[case:friends.introducer.manage_all_introduction_preferen.action]',
      (tester) async {
        final world = _World();
        await _show(tester, world, member: true);
        final before = world.api.sent('GET', '/introducer/connections').length;
        await _tapText(tester, 'Manage all introduction preferences');
        expect(find.byType(DatingRhythmScreen), findsOneWidget);
        await tester.pageBack();
        await _settle(tester);
        expect(
          world.api.sent('GET', '/introducer/connections'),
          hasLength(before + 1),
        );
      },
    );
  });

  group('introducer workspace', () {
    testWidgets(
      'Refresh permissions reloads permissions and sent introductions '
      '[case:friends.introducer.refresh_permissions.action]',
      (tester) async {
        final world = _World();
        await _show(tester, world);
        world.connections = [_conn('perm-alice', 'alice', 'Alice', 'active')];
        world.made.add({
          'id': 'i-1',
          'first_name': 'Alice',
          'second_name': 'Bob',
          'status': 'open',
          'created_at': '2026-10-01T00:00:00Z',
        });
        await tester.tap(find.byTooltip('Refresh permissions'));
        await _settle(tester);
        expect(world.api.sent('GET', '/introducer/connections'), hasLength(2));
        expect(world.api.sent('GET', '/friends/friend/intros'), hasLength(2));
        expect(
          find.text('Permission to suggest introductions.'),
          findsOneWidget,
        );
        expect(find.text('Alice + Bob'), findsOneWidget);
      },
    );

    testWidgets('when permissions fail to load, Try again reloads them '
        '[case:friends.introducer.try_again.action]', (tester) async {
      final world = _World()..api.offline('GET /introducer/connections');
      await _show(tester, world);
      expect(
        find.text('We couldn’t load permissions. Nothing has been changed.'),
        findsOneWidget,
      );
      expect(find.text('Suggest an introduction'), findsNothing);
      world.api.on(
        'GET /introducer/connections',
        (_) => qaOk({'connections': world.connections}),
      );
      await _tapText(tester, 'Try again');
      expect(find.text('Alice'), findsOneWidget);
      expect(world.api.sent('GET', '/introducer/connections'), hasLength(2));
    });

    testWidgets('when sent introductions fail to load, Reload brings them back '
        '[case:friends.introducer.reload_sent_introductions.action]', (
      tester,
    ) async {
      final world = _World()..api.fail('GET /friends/*/intros');
      world.made.add({
        'id': 'i-1',
        'first_name': 'Alice',
        'second_name': 'Bob',
        'status': 'open',
        'created_at': '2026-10-01T00:00:00Z',
      });
      await _show(tester, world);
      world.api.on(
        'GET /friends/*/intros',
        (_) => qaOk({'made': world.made, 'received': <dynamic>[]}),
      );
      await _tapText(tester, 'Reload sent introductions');
      expect(world.api.sent('GET', '/friends/friend/intros'), hasLength(2));
      expect(find.text('Alice + Bob'), findsOneWidget);
      expect(find.text('Sent · their decision is private'), findsOneWidget);
    });

    testWidgets('typing an invitation code fills the field '
        '[case:friends.introducer.invitation_code_input.action]', (
      tester,
    ) async {
      final world = _World();
      await _show(tester, world);
      final field = find.widgetWithText(TextField, 'Invitation code');
      await tester.enterText(field, 'kind-otter-42');
      expect(find.text('kind-otter-42'), findsOneWidget);
    });

    testWidgets(
      'an empty or blank code is refused without a request; the code is sent '
      'trimmed with unicode intact '
      '[case:friends.introducer.invitation_code_input.validation]',
      (tester) async {
        final world = _World();
        await _show(tester, world);
        final field = find.widgetWithText(TextField, 'Invitation code');
        for (final text in ['', '    ']) {
          await tester.enterText(field, text);
          await _tapText(tester, 'Ask for permission');
          expect(
            find.text('Enter the invitation code your friend shared.'),
            findsOneWidget,
          );
        }
        expect(world.api.writes, isEmpty);
        await tester.enterText(field, '  zoë-Ω-7  ');
        await _tapText(tester, 'Ask for permission');
        expect(world.api.sent('POST', '/introducer/redeem').single.body, {
          'code': 'zoë-Ω-7',
        });
      },
    );

    testWidgets(
      'Ask for permission redeems the code, confirms and clears the field '
      '[case:friends.introducer.ask_for_permission.action]',
      (tester) async {
        final world = _World();
        await _show(tester, world);
        final field = find.widgetWithText(TextField, 'Invitation code');
        await tester.enterText(field, 'kind-otter-42');
        await _tapText(tester, 'Ask for permission');
        expect(world.api.writeLines, ['POST /introducer/redeem']);
        expect(world.api.writes.single.body, {'code': 'kind-otter-42'});
        expect(
          find.text(
            'Request sent. Your friend can now approve you in Your '
            'introducers.',
          ),
          findsOneWidget,
        );
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
        expect(world.api.sent('GET', '/introducer/connections'), hasLength(2));
      },
    );

    testWidgets('a refused code shows the reason and keeps what was typed '
        '[case:friends.introducer.ask_for_permission.api_failure]', (
      tester,
    ) async {
      final world = _World()
        ..api.fail(
          'POST /introducer/redeem',
          status: 404,
          message: 'That code has expired.',
        );
      await _show(tester, world);
      final field = find.widgetWithText(TextField, 'Invitation code');
      await tester.enterText(field, 'old-code');
      await _tapText(tester, 'Ask for permission');
      expect(find.text('That code has expired.'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, 'old-code');
      expect(tester.widget<TextField>(field).enabled, isTrue);
    });

    testWidgets('Keep permission closes the question and changes nothing '
        '[case:friends.introducer.keep_permission.action]', (tester) async {
      final world = _World(
        connections: [_conn('perm-alice', 'alice', 'Alice', 'active')],
      );
      await _show(tester, world);
      await _tapText(tester, 'Remove permission');
      expect(find.text('Remove permission for Alice?'), findsOneWidget);
      await tester.tap(find.text('Keep permission'));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(world.api.writes, isEmpty);
      expect(find.text('Alice'), findsOneWidget);
    });

    group('suggesting an introduction', () {
      _World pair() => _World(
        connections: [
          _conn('perm-alice', 'alice', 'Alice', 'active'),
          _conn('perm-bob', 'bob', 'Bob', 'active'),
          _conn('perm-cy', 'cy', 'Cy', 'pending'),
        ],
      );

      Future<void> choose(
        WidgetTester tester,
        String label,
        String name,
      ) async {
        await _tapText(tester, label);
        await tester.tap(find.text(name).last);
        await _settle(tester);
      }

      testWidgets(
        'only friends who gave permission can be chosen, never the same '
        'twice [case:friends.introducer.first_x.action] '
        '[case:friends.introducer.second_x.action]',
        (tester) async {
          final world = pair();
          await _show(tester, world);
          expect(
            tester
                .widget<FilledButton>(
                  find.ancestor(
                    of: find.text('Suggest an introduction'),
                    matching: find.byWidgetPredicate((w) => w is FilledButton),
                  ),
                )
                .onPressed,
            isNull,
          );
          // Each dropdown lists its choices (in its button and its menu).
          Finder options(int index, String name) => find.descendant(
            of: find.byType(DropdownButtonFormField<String>).at(index),
            matching: find.text(name, skipOffstage: false),
            skipOffstage: false,
          );
          expect(options(0, 'Alice'), findsOneWidget);
          expect(options(0, 'Bob'), findsOneWidget);
          expect(options(0, 'Cy'), findsNothing, reason: 'pending: no consent');
          await _tapText(tester, 'First friend');
          await tester.tap(find.text('Alice').last);
          await _settle(tester);
          expect(options(1, 'Bob'), findsOneWidget);
          expect(options(1, 'Alice'), findsNothing, reason: 'already first');
          await _tapText(tester, 'Second friend');
          await tester.tap(find.text('Bob').last);
          await _settle(tester);
          final dropdowns = tester.widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          );
          expect(dropdowns.map((d) => d.initialValue), ['alice', 'bob']);
        },
      );

      testWidgets(
        'Suggest sends both friends and the trimmed note, confirms and resets '
        '[case:friends.introducer.suggest_an_introduction.action] '
        '[case:friends.introducer.why_you_thought_of_them_optional_input.action]',
        (tester) async {
          final world = pair();
          await _show(tester, world);
          await choose(tester, 'First friend', 'Alice');
          await choose(tester, 'Second friend', 'Bob');
          final note = find.widgetWithText(
            TextField,
            'Why you thought of them (optional)',
          );
          await tester.enterText(note, '  You both love books.  ');
          await _tapText(tester, 'Suggest an introduction');
          expect(world.api.writeLines, ['POST /friends/friend/intros']);
          expect(world.api.writes.single.body, {
            'first_user_id': 'alice',
            'second_user_id': 'bob',
            'message': 'You both love books.',
          });
          expect(
            find.text('Introduction sent. They can each decide in private.'),
            findsOneWidget,
          );
          expect(tester.widget<TextField>(note).controller!.text, isEmpty);
          final dropdowns = tester.widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          );
          expect(dropdowns.map((d) => d.initialValue), [null, null]);
        },
      );

      testWidgets(
        'the note stops at 200 characters and keeps emoji and RTL text '
        '[case:friends.introducer.why_you_thought_of_them_optional_input.validation]',
        (tester) async {
          final world = pair();
          await _show(tester, world);
          final note = find.widgetWithText(
            TextField,
            'Why you thought of them (optional)',
          );
          await tester.enterText(note, 'z' * 240);
          await tester.pump();
          expect(
            tester.widget<TextField>(note).controller!.text,
            hasLength(200),
          );
          await choose(tester, 'First friend', 'Alice');
          await choose(tester, 'Second friend', 'Bob');
          await tester.enterText(note, 'Книги 📚 كتب');
          await _tapText(tester, 'Suggest an introduction');
          expect(
            world.api
                .sent('POST', '/friends/friend/intros')
                .single
                .body['message'],
            'Книги 📚 كتب',
          );
        },
      );

      testWidgets(
        'a refused suggestion explains and keeps the choices and note '
        '[case:friends.introducer.suggest_an_introduction.api_failure]',
        (tester) async {
          final world = pair()
            ..api.fail(
              'POST /friends/*/intros',
              status: 409,
              message: 'Alice paused introductions.',
            );
          await _show(tester, world);
          await choose(tester, 'First friend', 'Alice');
          await choose(tester, 'Second friend', 'Bob');
          final note = find.widgetWithText(
            TextField,
            'Why you thought of them (optional)',
          );
          await tester.enterText(note, 'Books');
          await _tapText(tester, 'Suggest an introduction');
          expect(find.text('Alice paused introductions.'), findsOneWidget);
          expect(tester.widget<TextField>(note).controller!.text, 'Books');
          final dropdowns = tester.widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          );
          expect(dropdowns.map((d) => d.initialValue), ['alice', 'bob']);
        },
      );
    });

    testWidgets(
      'Account: Account & privacy opens account data; Sign out ends the '
      'session on the server and here [case:friends.introducer.account.action]',
      (tester) async {
        final world = _World();
        final push = _Push();
        await _show(
          tester,
          world,
          extra: [pushNotificationServiceProvider.overrideWithValue(push)],
        );
        await tester.tap(find.byTooltip('Account'));
        await _settle(tester);
        await tester.tap(find.text('Account & privacy'));
        await _settle(tester);
        expect(find.byType(AccountDataScreen), findsOneWidget);
        await tester.pageBack();
        await _settle(tester);

        AuthSessionStore.instance.accessToken = 'session-token';
        await tester.tap(find.byTooltip('Account'));
        await _settle(tester);
        await tester.tap(find.text('Sign out'));
        await _settle(tester);
        expect(push.unregistered, ['friend']);
        expect(world.api.sent('POST', '/auth/logout'), hasLength(1));
        final container = ProviderScope.containerOf(
          tester.element(find.byType(IntroducerScreen)),
        );
        expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
        expect(AuthSessionStore.instance.accessToken, isNull);
      },
    );

    testWidgets('Sign out still ends the local session when the server is down '
        '[case:friends.introducer.account.api_failure]', (tester) async {
      final world = _World()..api.offline('POST /auth/logout');
      await _show(
        tester,
        world,
        extra: [pushNotificationServiceProvider.overrideWithValue(_Push())],
      );
      AuthSessionStore.instance.accessToken = 'session-token';
      await tester.tap(find.byTooltip('Account'));
      await _settle(tester);
      await tester.tap(find.text('Sign out'));
      await _settle(tester);
      expect(world.api.sent('POST', '/auth/logout'), hasLength(1));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(IntroducerScreen)),
      );
      expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('both workspaces render translated in every locale '
      '[case:friends.introducer.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await _show(tester, _World(), member: true, locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale member');
      expect(find.text(l10n.friendsIntroducerMemberTitle), findsOneWidget);
      expect(find.text(l10n.friendsIntroducerAllow), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _show(tester, _World(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale introducer');
      expect(find.text(l10n.friendsIntroducerAskPermission), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
