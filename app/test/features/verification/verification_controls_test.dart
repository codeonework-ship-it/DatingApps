// Control-level tests for ID verification: landing, ID photo, selfie and
// status. The image picker's platform channel is faked (it hands back a real
// PNG on disk), so the app's own handling of the picked photo, the upload
// and the server's answers is exercised end to end. Real camera capture is a
// device check. Each test name carries its catalog case ids.
// Some catalog case ids are longer than a line; they stay whole in a tag.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/verification/screens/verification_landing_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_selfie_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_status_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_upload_id_screen.dart';

import '../../support/qa_api.dart';

final _en = qaL10n(const Locale('en'));

/// A valid 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

late Directory _dir;
String get _idPath => '${_dir.path}/id.png';
String get _selfiePath => '${_dir.path}/selfie.png';

const _status = '/verification/me';
const _submit = '/verification/me/submit';

/// Fake picker: records each request and answers with [next] (null =
/// the member cancelled).
class _Picker {
  _Picker(this.next);
  String? next;
  final requests = <Map<Object?, Object?>>[];

  static const _channel = MethodChannel('plugins.flutter.io/image_picker');

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(_channel, (call) async {
            if (call.method != 'pickImage') {
              return null;
            }
            requests.add(call.arguments as Map<Object?, Object?>);
            return next;
          });
    addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));
  }

  List<int> get sources => [for (final r in requests) r['source']! as int];
}

QaReply _slow(QaReply reply) => QaReply(
  reply.status,
  reply.body,
  offline: reply.offline,
  delay: const Duration(milliseconds: 400),
);

QaApi _api({String status = ''}) => QaApi()
  ..json('GET $_status', {'status': status, 'rejection_reason': null})
  ..json('POST $_submit', {'status': 'pending', 'rejection_reason': null});

Finder _key(String key) => find.byKey(ValueKey(key));

/// Reading a picked file is real disk I/O, one step per event-loop turn;
/// give each step a real turn, then settle.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  await qaSettle(tester);
}

/// Disposes the previous tree so the next pump starts fresh (no cached
/// providers, no pushed routes).
Future<void> _fresh(WidgetTester tester) => tester.pumpWidget(const SizedBox());

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pump();
  await tester.tap(_key(key));
  await _settleIo(tester);
}

Finder _photo(String path) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is FileImage &&
      (w.image as FileImage).file.path == path,
);

ButtonStyleButton _button(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(_key(key));

void main() {
  setUpAll(() {
    _dir = Directory.systemTemp.createTempSync('qa_verification_');
    File(_idPath).writeAsBytesSync(_png);
    File(_selfiePath).writeAsBytesSync(_png);
  });
  tearDownAll(() => _dir.deleteSync(recursive: true));

  group('Landing', () {
    testWidgets(
      'Start secure verification opens the ID step '
      '[case:verification.verification_landing.verification_landing_start_button.action]',
      (tester) async {
        final api = _api();
        await pumpQa(tester, api, const VerificationLandingScreen());
        expect(api.sent('GET', _status), hasLength(1));
        expect(_key('qa.verification.landing.status_button'), findsNothing);

        await _tap(tester, 'qa.verification.landing.start_button');

        expect(find.byType(VerificationUploadIdScreen), findsOneWidget);
        expect(find.text(_en.verificationUploadIdTitle), findsOneWidget);
        expect(api.writes, isEmpty);
      },
    );

    testWidgets('View review status opens the status of a submitted check '
        '[case:verification.verification_landing.view_review_status.action]', (
      tester,
    ) async {
      await pumpQa(
        tester,
        _api(status: 'pending'),
        const VerificationLandingScreen(),
      );
      expect(_key('qa.verification.landing.start_button'), findsNothing);
      expect(
        tester
            .widget<GlassButton>(_key('qa.verification.landing.status_button'))
            .label,
        _en.verificationViewReviewStatus,
      );
      await _tap(tester, 'qa.verification.landing.status_button');

      expect(find.byType(VerificationStatusScreen), findsOneWidget);
      expect(find.text(_en.verificationStatusPending), findsOneWidget);
      expect(find.text(_en.verificationStatusPendingMessage), findsOneWidget);

      // A verified member gets the verified wording and status.
      await _fresh(tester);
      await pumpQa(
        tester,
        _api(status: 'verified'),
        const VerificationLandingScreen(),
      );
      expect(
        tester
            .widget<GlassButton>(_key('qa.verification.landing.status_button'))
            .label,
        _en.verificationViewVerifiedStatus,
      );
      await _tap(tester, 'qa.verification.landing.status_button');
      expect(find.text(_en.verificationStatusVerifiedMessage), findsOneWidget);
    });

    testWidgets('Verification landing renders in every language '
        '[case:verification.verification_landing.l10n]', (tester) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        await _fresh(tester);
        await pumpQa(
          tester,
          _api(),
          const VerificationLandingScreen(),
          locale: locale,
        );
        expect(find.text(l10n.verificationLandingTitle), findsOneWidget);
        expect(
          find.text(l10n.settingsGovernmentVerificationTitle),
          findsOneWidget,
        );
        expect(
          tester
              .widget<GlassButton>(_key('qa.verification.landing.start_button'))
              .label,
          l10n.verificationStartButton,
        );
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('ID photo', () {
    testWidgets(
      'Gallery picks the ID photo, shows it and enables Next '
      '[case:verification.verification_upload_id.verification_id_gallery_button.action]',
      (tester) async {
        final picker = _Picker(null)..install();
        await pumpQa(tester, _api(), const VerificationUploadIdScreen());
        expect(
          _button(tester, 'qa.verification.id.next_button').onPressed,
          isNull,
        );

        // Cancelled pick: nothing changes.
        await _tap(tester, 'qa.verification.id.gallery_button');
        expect(_photo(_idPath), findsNothing);
        expect(
          _button(tester, 'qa.verification.id.next_button').onPressed,
          isNull,
        );

        picker.next = _idPath;
        await _tap(tester, 'qa.verification.id.gallery_button');
        expect(picker.sources, [
          ImageSource.gallery.index,
          ImageSource.gallery.index,
        ]);
        expect(picker.requests.last['imageQuality'], 85);
        expect(_photo(_idPath), findsOneWidget);
        expect(
          _button(tester, 'qa.verification.id.next_button').onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('Camera takes the ID photo and shows it '
        '[case:verification.verification_upload_id.camera.action]', (
      tester,
    ) async {
      final picker = _Picker(_idPath)..install();
      await pumpQa(tester, _api(), const VerificationUploadIdScreen());
      await _tap(tester, 'qa.verification.id.camera_button');

      expect(picker.sources, [ImageSource.camera.index]);
      expect(_photo(_idPath), findsOneWidget);
      expect(
        _button(tester, 'qa.verification.id.next_button').onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'Next carries the ID photo to the selfie step '
      '[case:verification.verification_upload_id.verification_id_next_button.action]',
      (tester) async {
        _Picker(_idPath).install();
        await pumpQa(tester, _api(), const VerificationUploadIdScreen());
        await _tap(tester, 'qa.verification.id.gallery_button');
        await _tap(tester, 'qa.verification.id.next_button');

        final selfie = tester.widget<VerificationSelfieScreen>(
          find.byType(VerificationSelfieScreen),
        );
        expect(selfie.idPhoto.path, _idPath);
        expect(find.text(_en.verificationSelfieTitle), findsOneWidget);
      },
    );

    testWidgets('ID step renders in every language '
        '[case:verification.verification_upload_id.l10n]', (tester) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        await _fresh(tester);
        await pumpQa(
          tester,
          _api(),
          const VerificationUploadIdScreen(),
          locale: locale,
        );
        expect(find.text(l10n.verificationUploadIdTitle), findsOneWidget);
        expect(find.text(l10n.verificationGallery), findsOneWidget);
        expect(find.text(l10n.verificationCamera), findsOneWidget);
        expect(find.text(l10n.verificationNext), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('Selfie', () {
    Future<List<Object?>> open(WidgetTester tester, QaApi api) => pumpQa(
      tester,
      api,
      VerificationSelfieScreen(idPhoto: XFile(_idPath)),
      launcher: true,
    );

    testWidgets(
      'Gallery picks the selfie and enables Submit '
      '[case:verification.verification_selfie.verification_selfie_gallery_button.action]',
      (tester) async {
        final picker = _Picker(_selfiePath)..install();
        await open(tester, _api());
        expect(
          _button(tester, 'qa.verification.selfie.submit_button').onPressed,
          isNull,
        );
        await _tap(tester, 'qa.verification.selfie.gallery_button');

        expect(picker.sources, [ImageSource.gallery.index]);
        expect(_photo(_selfiePath), findsOneWidget);
        expect(
          _button(tester, 'qa.verification.selfie.submit_button').onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('Camera takes the selfie and enables Submit '
        '[case:verification.verification_selfie.camera.action]', (
      tester,
    ) async {
      final picker = _Picker(_selfiePath)..install();
      await open(tester, _api());
      await _tap(tester, 'qa.verification.selfie.camera_button');

      expect(picker.sources, [ImageSource.camera.index]);
      expect(_photo(_selfiePath), findsOneWidget);
      expect(
        _button(tester, 'qa.verification.selfie.submit_button').onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'Submit uploads both photos and shows the review status '
      '[case:verification.verification_selfie.verification_selfie_submit_button.action]',
      (tester) async {
        _Picker(_selfiePath).install();
        final api = _api();
        final results = await open(tester, api);
        await _tap(tester, 'qa.verification.selfie.gallery_button');
        await _tap(tester, 'qa.verification.selfie.submit_button');

        expect(api.writeLines, ['POST $_submit']);
        final form = api.writes.single.data! as FormData;
        expect(
          [
            for (final f in form.files)
              (f.key, f.value.filename, f.value.length),
          ],
          [
            ('id_document', 'id.png', _png.length),
            ('selfie', 'selfie.png', _png.length),
          ],
        );
        expect(find.byType(VerificationSelfieScreen), findsNothing);
        expect(find.byType(VerificationStatusScreen), findsOneWidget);
        expect(find.text(_en.verificationStatusPending), findsOneWidget);
        expect(results, [null], reason: 'selfie step replaced by the status');
      },
    );

    testWidgets(
      'REGRESSION: a failed upload says so, re-enables Submit and a second '
      'tap does not upload twice '
      '[case:verification.verification_selfie.verification_selfie_submit_button.api_failure]',
      (tester) async {
        // Submit stayed live while uploading: a second tap sent the identity
        // evidence twice.
        _Picker(_selfiePath).install();
        final api = _api()
          ..on(
            'POST $_submit',
            (_) => _slow(
              qaError(
                503,
                message:
                    'identity verification provider is temporarily unavailable',
              ),
            ),
          );
        await open(tester, api);
        await _tap(tester, 'qa.verification.selfie.gallery_button');
        final submit = _key('qa.verification.selfie.submit_button');
        await tester.tap(submit);
        await tester.pump();
        expect(
          _button(tester, 'qa.verification.selfie.submit_button').onPressed,
          isNull,
        );
        await tester.tap(submit, warnIfMissed: false); // impatient second tap
        await _settleIo(tester);

        expect(api.writeLines, ['POST $_submit']);
        expect(find.text(_en.verificationUploadFailed), findsOneWidget);
        expect(find.byType(VerificationSelfieScreen), findsOneWidget);
        expect(find.byType(VerificationStatusScreen), findsNothing);
        expect(
          _button(tester, 'qa.verification.selfie.submit_button').onPressed,
          isNotNull,
        );
        expect(_photo(_selfiePath), findsOneWidget, reason: 'selfie kept');

        // Offline: same message; the retry then goes through.
        api.offline('POST $_submit');
        await _tap(tester, 'qa.verification.selfie.submit_button');
        expect(find.text(_en.verificationUploadFailed), findsOneWidget);
        api.json('POST $_submit', {'status': 'pending'});
        await _tap(tester, 'qa.verification.selfie.submit_button');
        expect(api.writeLines, List.filled(3, 'POST $_submit'));
        expect(find.byType(VerificationStatusScreen), findsOneWidget);
      },
    );

    testWidgets(
      'REGRESSION: a failed status check is not shown as a failed upload '
      '[case:verification.verification_selfie.verification_selfie_submit_button.api_failure]',
      (tester) async {
        _Picker(_selfiePath).install();
        final api = _api()..offline('GET $_status');
        await open(tester, api);
        expect(find.text(_en.verificationUploadFailed), findsNothing);
        await _tap(tester, 'qa.verification.selfie.gallery_button');
        expect(find.text(_en.verificationUploadFailed), findsNothing);
        expect(
          _button(tester, 'qa.verification.selfie.submit_button').onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('Selfie step renders in every language '
        '[case:verification.verification_selfie.l10n]', (tester) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        await _fresh(tester);
        await pumpQa(
          tester,
          _api(),
          VerificationSelfieScreen(idPhoto: XFile(_idPath)),
          locale: locale,
        );
        expect(find.text(l10n.verificationSelfieTitle), findsOneWidget);
        expect(find.text(l10n.verificationSelfieInstruction), findsOneWidget);
        expect(find.text(l10n.verificationSubmit), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('Status', () {
    testWidgets(
      'REGRESSION: an unreachable status offers Retry, which reloads it '
      '[case:verification.verification_status.retry.action]',
      (tester) async {
        // A failed status fetch used to read as "Not Started", telling a
        // member under review to start again; Retry could never appear.
        final api = _api(status: 'pending')..offline('GET $_status');
        await pumpQa(tester, api, const VerificationStatusScreen());
        expect(find.text(_en.verificationStatusNotStarted), findsNothing);
        expect(_key('qa.verification.status.retry'), findsOneWidget);
        expect(find.text(_en.verificationRetry), findsOneWidget);

        api.json('GET $_status', {'status': 'pending'});
        await _tap(tester, 'qa.verification.status.retry');

        expect(api.sent('GET', _status), hasLength(2));
        expect(_key('qa.verification.status.retry'), findsNothing);
        expect(find.text(_en.verificationStatusPending), findsOneWidget);
      },
    );

    testWidgets('Rejected status shows the reviewer reason '
        '[case:verification.verification_status.rejection_reason.action]', (
      tester,
    ) async {
      final api = QaApi()
        ..json('GET $_status', {
          'status': 'rejected',
          'rejection_reason': 'The ID photo was blurred.',
        });
      await pumpQa(tester, api, const VerificationStatusScreen());
      expect(find.text(_en.verificationStatusRejected), findsOneWidget);
      expect(find.text('The ID photo was blurred.'), findsOneWidget);
    });

    testWidgets('Verification status renders in every language '
        '[case:verification.verification_status.l10n]', (tester) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        await _fresh(tester);
        await pumpQa(
          tester,
          _api(),
          const VerificationStatusScreen(),
          locale: locale,
        );
        expect(find.text(l10n.verificationStatusTitle), findsOneWidget);
        expect(find.text(l10n.verificationStatusNotStarted), findsOneWidget);
        expect(
          find.text(l10n.verificationStatusNotStartedMessage),
          findsOneWidget,
        );

        final failing = _api()..offline('GET $_status');
        await _fresh(tester);
        await pumpQa(
          tester,
          failing,
          const VerificationStatusScreen(),
          locale: locale,
        );
        expect(find.text(l10n.verificationRetry), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });
}
