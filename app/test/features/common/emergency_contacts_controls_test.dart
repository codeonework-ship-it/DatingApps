// Control-level tests for Emergency contacts: add / edit / remove (with their
// dialogs, validation and server failures), the 3-contact limit and Retry
// after a failed load.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/common/screens/emergency_contacts_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

final AppLocalizations en = qaL10n(const Locale('en'));

class _ContactServer {
  _ContactServer({List<Map<String, dynamic>>? contacts})
    : contacts =
          contacts ??
          [
            {
              'id': 'c-mum',
              'name': 'Mum',
              'phone_number': '+919876543210',
              'ordering': 1,
            },
          ] {
    Map<String, dynamic> list() => {'contacts': this.contacts};
    api
      ..on('GET /emergency-contacts/me', (_) => qaOk(list()))
      ..on('POST /emergency-contacts/me', (call) {
        if (this.contacts.length >= 3) {
          return qaError(409, message: 'You can add up to 3 contacts.');
        }
        this.contacts = [
          ...this.contacts,
          {
            'id': 'c-${this.contacts.length + 1}',
            ...call.body,
            'ordering': this.contacts.length + 1,
          },
        ];
        return qaOk(list());
      })
      ..on('PUT /emergency-contacts/me/*', (call) {
        final id = call.path.split('/').last;
        this.contacts = [
          for (final c in this.contacts)
            c['id'] == id ? {...c, ...call.body} : c,
        ];
        return qaOk(list());
      })
      ..on('DELETE /emergency-contacts/me/*', (call) {
        final id = call.path.split('/').last;
        this.contacts = this.contacts.where((c) => c['id'] != id).toList();
        return qaOk(list());
      });
  }

  final api = QaApi();
  List<Map<String, dynamic>> contacts;
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _open(
  WidgetTester tester,
  _ContactServer server, {
  Locale? locale,
}) => pumpQa(
  tester,
  server.api,
  const EmergencyContactsScreen(),
  launcher: true,
  locale: locale,
);

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await qaSettle(tester);
}

/// Fills the add/edit dialog and taps Save.
Future<void> _save(WidgetTester tester, String name, String phone) async {
  await tester.enterText(_key('qa.emergency.name_field'), name);
  await tester.enterText(_key('qa.emergency.phone_field'), phone);
  await _tap(tester, 'qa.emergency.editor_save');
}

void main() {
  group('add', () {
    testWidgets(
      'Add Contact → name and phone → Save adds it on the server and lists it '
      '[case:common.emergency_contacts.emergency_add.action] '
      '[case:common.emergency_contacts.save.action] '
      '[case:common.emergency_contacts.emergency_editor_save.action] '
      '[case:common.emergency_contacts.emergency_name_field_input.action] '
      '[case:common.emergency_contacts.emergency_phone_field_input.action]',
      (tester) async {
        final server = _ContactServer();
        await _open(tester, server);
        await _tap(tester, 'qa.emergency.add');
        expect(find.text(en.emergencyAddContact), findsNWidgets(2));
        expect(find.text(en.emergencyNameLabel), findsOneWidget);
        expect(find.text(en.emergencyPhoneLabel), findsOneWidget);

        await _save(tester, '  Priya Sharma ', ' +91 98200 11223 ');

        expect(server.api.sent('POST', '/emergency-contacts/me').single.body, {
          'name': 'Priya Sharma',
          'phone_number': '+91 98200 11223',
        });
        expect(find.byType(EmergencyContactsScreen), findsOneWidget);
        expect(find.text('Priya Sharma'), findsOneWidget);
        expect(find.text('+91 98200 11223'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // its position badge
        expect(qaSnackText(tester), en.emergencyAdded);
      },
    );

    testWidgets('Cancel in the editor adds nothing '
        '[case:common.emergency_contacts.emergency_editor_cancel.action]', (tester) async {
      final server = _ContactServer();
      await _open(tester, server);
      await _tap(tester, 'qa.emergency.add');
      await tester.enterText(_key('qa.emergency.name_field'), 'Dad');
      await _tap(tester, 'qa.emergency.editor_cancel');

      expect(find.text(en.emergencyNameLabel), findsNothing);
      expect(find.byType(EmergencyContactsScreen), findsOneWidget);
      expect(server.api.writes, isEmpty);
      expect(find.text('Dad'), findsNothing);
      expect(qaSnackText(tester), isNull);
    });

    testWidgets(
      'an empty or blank name is refused before anything is sent; unicode '
      'names are kept [case:common.emergency_contacts.emergency_name_field_input.validation]',
      (tester) async {
        final server = _ContactServer();
        await _open(tester, server);
        for (final name in ['', '    ']) {
          await _tap(tester, 'qa.emergency.add');
          await _save(tester, name, '+919876500000');
          expect(qaSnackText(tester), en.emergencyInvalidInput);
          ScaffoldMessenger.of(
            tester.element(find.byType(EmergencyContactsScreen)),
          ).clearSnackBars();
          await qaSettle(tester);
        }
        expect(server.api.writes, isEmpty);

        await _tap(tester, 'qa.emergency.add');
        await _save(tester, 'أمي Ánh 🌸', '+919876500000');
        expect(
          server.api.sent('POST', '/emergency-contacts/me').single.body['name'],
          'أمي Ánh 🌸',
        );
        expect(find.text('أمي Ánh 🌸'), findsOneWidget);
      },
    );

    testWidgets(
      'phone numbers must have 8–16 digits (spaces, dashes and + allowed) '
      '[case:common.emergency_contacts.emergency_phone_field_input.validation]',
      (tester) async {
        final server = _ContactServer();
        await _open(tester, server);
        for (final phone in [
          '',
          '12345',
          'call me maybe',
          '+12345678901234567',
        ]) {
          await _tap(tester, 'qa.emergency.add');
          await _save(tester, 'Dad', phone);
          expect(qaSnackText(tester), en.emergencyInvalidInput, reason: phone);
          ScaffoldMessenger.of(
            tester.element(find.byType(EmergencyContactsScreen)),
          ).clearSnackBars();
          await qaSettle(tester);
        }
        expect(server.api.writes, isEmpty);

        await _tap(tester, 'qa.emergency.add');
        await _save(tester, 'Dad', '020-7946-0018');
        expect(
          server.api
              .sent('POST', '/emergency-contacts/me')
              .single
              .body['phone_number'],
          '020-7946-0018',
        );
        expect(qaSnackText(tester), en.emergencyAdded);
      },
    );

    testWidgets('a refused add explains and keeps the list as it was '
        '[case:common.emergency_contacts.emergency_add.api_failure]', (
      tester,
    ) async {
      final server = _ContactServer();
      server.api.fail('POST /emergency-contacts/me', status: 500);
      await _open(tester, server);
      await _tap(tester, 'qa.emergency.add');
      await _save(tester, 'Dad', '+919876500000');

      expect(qaSnackText(tester), en.emergencyAddFailed);
      expect(find.text('Dad'), findsNothing);
      expect(find.text('Mum'), findsOneWidget);
      expect(server.api.writes, hasLength(1));
      // The add button still works.
      expect(
        tester.widget<GlassButton>(_key('qa.emergency.add')).onPressed,
        isNotNull,
      );
    });

    testWidgets('with three contacts the add button is disabled and says why '
        '[case:common.emergency_contacts.emergency_add.limit]', (tester) async {
      final server = _ContactServer(
        contacts: [
          for (var i = 1; i <= 3; i++)
            {
              'id': 'c-$i',
              'name': 'Contact $i',
              'phone_number': '+44770090000$i',
              'ordering': i,
            },
        ],
      );
      await _open(tester, server);
      expect(find.text(en.emergencyMaxReached), findsOneWidget);
      expect(
        tester.widget<GlassButton>(_key('qa.emergency.add')).onPressed,
        isNull,
      );
      await tester.tap(_key('qa.emergency.add'), warnIfMissed: false);
      await qaSettle(tester);
      expect(find.text(en.emergencyNameLabel), findsNothing);
    });
  });

  group('edit', () {
    testWidgets('Edit opens the editor prefilled; Save updates that contact '
        '[case:common.emergency_contacts.emergency_edit_x.action]', (
      tester,
    ) async {
      final server = _ContactServer();
      await _open(tester, server);
      await _tap(tester, 'qa.emergency.edit.c-mum');

      expect(find.text(en.emergencyEditContact), findsOneWidget);
      expect(
        tester
            .widget<TextField>(_key('qa.emergency.name_field'))
            .controller!
            .text,
        'Mum',
      );
      expect(
        tester
            .widget<TextField>(_key('qa.emergency.phone_field'))
            .controller!
            .text,
        '+919876543210',
      );

      await _save(tester, 'Mum (home)', '+912212345678');
      expect(
        server.api.sent('PUT', '/emergency-contacts/me/c-mum').single.body,
        {'name': 'Mum (home)', 'phone_number': '+912212345678'},
      );
      expect(find.text('Mum (home)'), findsOneWidget);
      expect(find.text('+912212345678'), findsOneWidget);
      expect(qaSnackText(tester), en.emergencyUpdated);
    });

    testWidgets(
      'an invalid edit is refused locally and a refused save explains '
      '[case:common.emergency_contacts.emergency_edit_x.api_failure]',
      (tester) async {
        final server = _ContactServer();
        await _open(tester, server);
        await _tap(tester, 'qa.emergency.edit.c-mum');
        await _save(tester, 'Mum', '123');
        expect(qaSnackText(tester), en.emergencyInvalidInput);
        expect(server.api.writes, isEmpty);
        ScaffoldMessenger.of(
          tester.element(find.byType(EmergencyContactsScreen)),
        ).clearSnackBars();
        await qaSettle(tester);

        server.api.offline('PUT /emergency-contacts/me/*');
        await _tap(tester, 'qa.emergency.edit.c-mum');
        await _save(tester, 'Mother', '+912212345678');
        expect(qaSnackText(tester), en.emergencyUpdateFailed);
        expect(find.text('Mum'), findsOneWidget);
        expect(find.text('Mother'), findsNothing);
        expect(server.api.writes, hasLength(1));
      },
    );
  });

  group('remove', () {
    testWidgets('Delete asks first; Remove deletes it on the server '
        '[case:common.emergency_contacts.emergency_delete_x.action] '
        '[case:common.emergency_contacts.remove_contact.action] '
        '[case:common.emergency_contacts.emergency_remove_confirm.action]', (tester) async {
      final server = _ContactServer();
      await _open(tester, server);
      await _tap(tester, 'qa.emergency.delete.c-mum');
      expect(find.text(en.emergencyRemoveTitle), findsOneWidget);
      expect(find.text(en.emergencyRemoveBody('Mum')), findsOneWidget);
      expect(server.api.writes, isEmpty);

      await _tap(tester, 'qa.emergency.remove_confirm');
      expect(server.api.writeLines, ['DELETE /emergency-contacts/me/c-mum']);
      expect(find.text(en.emergencyRemoveTitle), findsNothing);
      expect(find.byType(EmergencyContactsScreen), findsOneWidget);
      expect(find.text('Mum'), findsNothing);
      expect(find.text(en.emergencyEmpty), findsOneWidget);
      expect(qaSnackText(tester), en.emergencyRemoved);
    });

    testWidgets(
      'Cancel keeps the contact [case:common.emergency_contacts.emergency_remove_cancel.action]',
      (tester) async {
        final server = _ContactServer();
        await _open(tester, server);
        await _tap(tester, 'qa.emergency.delete.c-mum');
        await _tap(tester, 'qa.emergency.remove_cancel');
        expect(find.text(en.emergencyRemoveTitle), findsNothing);
        expect(find.byType(EmergencyContactsScreen), findsOneWidget);
        expect(server.api.writes, isEmpty);
        expect(find.text('Mum'), findsOneWidget);
      },
    );

    testWidgets(
      'a refused delete explains and keeps the contact '
      '[case:common.emergency_contacts.emergency_delete_x.api_failure]',
      (tester) async {
        final server = _ContactServer();
        server.api.fail('DELETE /emergency-contacts/me/*', status: 500);
        await _open(tester, server);
        await _tap(tester, 'qa.emergency.delete.c-mum');
        await _tap(tester, 'qa.emergency.remove_confirm');
        expect(qaSnackText(tester), en.emergencyRemoveFailed);
        expect(find.text('Mum'), findsOneWidget);
        expect(server.api.writes, hasLength(1));
      },
    );
  });

  testWidgets('a failed load is not shown as "no contacts" (which would invite '
      'duplicates past the limit); Retry reloads (regression) '
      '[case:common.emergency_contacts.emergency_retry.action]', (tester) async {
    final server = _ContactServer();
    server.api.fail('GET /emergency-contacts/me', status: 503);
    await _open(tester, server);
    expect(find.text(en.emergencyEmpty), findsNothing);
    expect(_key('qa.emergency.add'), findsNothing);
    expect(find.text(en.commonSomethingWentWrongTryAgain), findsOneWidget);

    server.api.on(
      'GET /emergency-contacts/me',
      (_) => qaOk({'contacts': server.contacts}),
    );
    await _tap(tester, 'qa.emergency.retry');
    expect(server.api.sent('GET', '/emergency-contacts/me'), hasLength(2));
    expect(find.text('Mum'), findsOneWidget);
  });

  testWidgets('Emergency contacts renders translated in all 10 languages '
      '[case:common.emergency_contacts.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final l10n = qaL10n(locale);
      await _open(tester, _ContactServer(), locale: locale);
      expect(find.text(l10n.privacyEmergencyContacts), findsOneWidget);
      expect(find.text(l10n.emergencyIntro), findsOneWidget);
      await _tap(tester, 'qa.emergency.add');
      expect(find.text(l10n.emergencyNameLabel), findsOneWidget);
      expect(find.text(l10n.emergencyPhoneLabel), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
