// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';

import '../../support/qa_api.dart';
import 'support/profile_bff.dart';

// Control-level tests for the photo step (SetupPhotosScreen): uploads from
// the gallery and camera (through a fake device picker), delete with its
// confirmation, reorder by drag and "Set as profile picture", and Next.
// Each asserts the request the BFF received and what the member sees.

const _gallery = ValueKey('qa.setup.photos.gallery_button');
const _camera = ValueKey('qa.setup.photos.camera_button');
const _next = ValueKey('qa.setup.photos.next_button');
const _confirmDelete = ValueKey('qa.setup.photos.confirm_delete');
const _cancelDelete = ValueKey('qa.setup.photos.cancel_delete');
ValueKey<String> _delete(String id) => ValueKey('qa.setup.photos.delete_$id');
ValueKey<String> _setPrimary(String id) =>
    ValueKey('qa.setup.photos.set_primary_$id');
ValueKey<String> _reorder(String id) => ValueKey('qa.setup.photos.reorder_$id');

final _en = qaL10n(const Locale('en'));

Future<List<Object?>> _open(
  WidgetTester tester,
  QaApi api, {
  bool setupFlow = false,
  Locale? locale,
}) => pumpQa(
  tester,
  api,
  SetupPhotosScreen(isSetupFlow: setupFlow),
  launcher: true,
  locale: locale,
  extra: qaMasterDataOverrides(),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await qaSettle(tester, frames: 2);
  await tester.tap(finder);
  await qaSettle(tester);
}

/// Row titles top to bottom ("Primary photo", "Photo 2", ...) by photo id.
List<String> _rowOrder(WidgetTester tester, List<String> ids) {
  final placed = [
    for (final id in ids)
      if (find.byKey(_delete(id)).evaluate().isNotEmpty)
        (id, tester.getTopLeft(find.byKey(_delete(id))).dy),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final p in placed) p.$1];
}

void main() {
  group('Gallery', () {
    testWidgets(
      'uploads the picked photo as multipart and shows it '
      '[case:profile.setup_photos.setup_photos_x_button_pickgallery.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        final picker = installQaPicker(QaImagePicker(file: qaPickedPhoto()));
        await _open(tester, api);
        await _tap(tester, find.byKey(_gallery));

        expect(picker.sources, [ImageSource.gallery]);
        final upload = api.sent('POST', '/profile/me/photos').single;
        expect(upload.options.contentType, startsWith('multipart/form-data'));
        final form = uploadForm(upload);
        expect(form.files.single.key, 'image');
        expect(form.files.single.value.filename, endsWith('.jpg'));
        expect(form.files.single.value.length, 64);
        expect(bff.photoIds, ['p1', 'p2', 'up1']);
        expect(find.byKey(_delete('up1')), findsOneWidget);
        expect(find.text(_en.profileSetupPhotoNumber(3)), findsOneWidget);
        expect(qaSnackText(tester), isNull);
      },
    );

    testWidgets(
      'offline upload explains, removes the placeholder and '
      're-enables both buttons '
      '[case:profile.setup_photos.setup_photos_x_button_pickgallery.api_failure]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.offline('POST /profile/*/photos');
        installQaPicker(QaImagePicker(file: qaPickedPhoto()));
        await _open(tester, api);
        await _tap(tester, find.byKey(_gallery));

        expect(qaSnackText(tester), _en.networkOfflineTryAgain);
        expect(api.sent('POST', '/profile/*/photos'), hasLength(1));
        expect(_rowOrder(tester, ['p1', 'p2']), ['p1', 'p2']);
        expect(find.text(_en.profileSetupPhotoNumber(3)), findsNothing);
        for (final key in [_gallery, _camera]) {
          final button = tester.widget<GlassButton>(find.byKey(key));
          expect(button.onPressed, isNotNull, reason: '$key');
          expect(button.isLoading, isFalse, reason: '$key');
        }
      },
    );

    testWidgets(
      'a cancelled pick sends nothing and says nothing '
      '[case:profile.setup_photos.setup_photos_x_button_pickgallery.action]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        final picker = installQaPicker(QaImagePicker());
        await _open(tester, api);
        await _tap(tester, find.byKey(_gallery));
        expect(picker.sources, [ImageSource.gallery]);
        expect(api.writes, isEmpty);
        expect(qaSnackText(tester), isNull);
      },
    );

    testWidgets(
      'a photo over 10 MB is refused before upload '
      '[case:profile.setup_photos.setup_photos_x_button_pickgallery.validation]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        installQaPicker(
          QaImagePicker(file: qaPickedPhoto(length: 11 * 1024 * 1024)),
        );
        await _open(tester, api);
        await _tap(tester, find.byKey(_gallery));
        expect(qaSnackText(tester), _en.profileSetupPhotoTooLarge);
        expect(api.writes, isEmpty);
        expect(_rowOrder(tester, ['p1', 'p2']), ['p1', 'p2']);
      },
    );

    testWidgets(
      'at the 5-photo limit the picker is not even opened '
      '[case:profile.setup_photos.setup_photos_x_button_pickgallery.validation]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api, draft: qaDraftJson(photoCount: 5));
        final picker = installQaPicker(QaImagePicker(file: qaPickedPhoto()));
        await _open(tester, api);
        await _tap(tester, find.byKey(_gallery));
        expect(qaSnackText(tester), _en.profileSetupPhotosMaxReached(5));
        expect(picker.sources, isEmpty);
        expect(api.writes, isEmpty);
      },
    );
  });

  group('Camera', () {
    testWidgets('uploads the captured photo '
        '[case:profile.setup_photos.setup_photos_x_button_pickcamera.action]', (
      tester,
    ) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      final picker = installQaPicker(
        QaImagePicker(file: qaPickedPhoto(path: 'qa/selfie.png')),
      );
      await _open(tester, api);
      await _tap(tester, find.byKey(_camera));
      expect(picker.sources, [ImageSource.camera]);
      final form = uploadForm(api.sent('POST', '/profile/me/photos').single);
      expect(form.files.single.value.filename, endsWith('.png'));
      expect(bff.photoIds, ['p1', 'p2', 'up1']);
      expect(find.byKey(_delete('up1')), findsOneWidget);
    });

    testWidgets(
      'a rejected format shows the translated reason and rolls back '
      '[case:profile.setup_photos.setup_photos_x_button_pickcamera.api_failure]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.on('POST /profile/*/photos', (_) => const QaReply(415, null));
        installQaPicker(QaImagePicker(file: qaPickedPhoto()));
        await _open(tester, api);
        await _tap(tester, find.byKey(_camera));
        expect(qaSnackText(tester), _en.profileSetupPhotoUnsupportedType);
        expect(api.sent('POST', '/profile/*/photos'), hasLength(1));
        expect(find.text(_en.profileSetupPhotoNumber(3)), findsNothing);
        expect(
          tester.widget<GlassButton>(find.byKey(_camera)).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'a server message is shown as sent '
      '[case:profile.setup_photos.setup_photos_x_button_pickcamera.api_failure]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.fail(
          'POST /profile/*/photos',
          status: 422,
          message: 'Face not visible',
        );
        installQaPicker(QaImagePicker(file: qaPickedPhoto()));
        await _open(tester, api);
        await _tap(tester, find.byKey(_camera));
        expect(qaSnackText(tester), 'Face not visible');
      },
    );
  });

  group('Delete', () {
    testWidgets('the trash button asks "Remove this photo?" first '
        '[case:profile.setup_photos.remove_this_photo.action]', (tester) async {
      final api = QaApi();
      ProfileBff(api);
      await _open(tester, api);
      await _tap(tester, find.byKey(_delete('p2')));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(_en.profileSetupRemovePhotoTitle), findsOneWidget);
      expect(find.text(_en.profileSetupRemovePhotoBody), findsOneWidget);
      expect(api.writes, isEmpty, reason: 'nothing is deleted yet');
    });

    testWidgets('Cancel closes the question and keeps the photo '
        '[case:profile.setup_photos.setup_photos_cancel_delete.action]', (tester) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      await _open(tester, api);
      await _tap(tester, find.byKey(_delete('p2')));
      await _tap(tester, find.byKey(_cancelDelete));
      expect(find.byType(AlertDialog), findsNothing);
      expect(api.writes, isEmpty);
      expect(bff.photoIds, ['p1', 'p2']);
      expect(find.byKey(_delete('p2')), findsOneWidget);
    });

    testWidgets(
      'Remove deletes that photo on the server and from the list '
      '[case:profile.setup_photos.setup_photos_confirm_delete.action] '
      '[case:profile.setup_photos.setup_photos_delete_x_deletephoto.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api);
        await _tap(tester, find.byKey(_delete('p2')));
        await _tap(tester, find.byKey(_confirmDelete));
        expect(api.writeLines, ['DELETE /profile/me/photos/p2']);
        expect(bff.photoIds, ['p1']);
        expect(find.byKey(_delete('p2')), findsNothing);
        expect(find.byKey(_delete('p1')), findsOneWidget);
      },
    );

    testWidgets(
      'a failed delete explains and puts the photo back '
      '[case:profile.setup_photos.setup_photos_delete_x_deletephoto.api_failure]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        api.fail('DELETE /profile/*/photos/*', message: 'Photo is locked');
        await _open(tester, api);
        await _tap(tester, find.byKey(_delete('p2')));
        await _tap(tester, find.byKey(_confirmDelete));
        expect(qaSnackText(tester), 'Photo is locked');
        expect(api.writes, hasLength(1));
        expect(bff.photoIds, ['p1', 'p2']);
        expect(_rowOrder(tester, ['p1', 'p2']), ['p1', 'p2']);
        final trash = tester.widget<IconButton>(find.byKey(_delete('p2')));
        expect(trash.onPressed, isNotNull);
      },
    );
  });

  group('Order', () {
    testWidgets(
      'Set as profile picture moves that photo first '
      '[case:profile.setup_photos.setup_photos_set_primary_x_setprimary.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api);
        await _tap(tester, find.byKey(_setPrimary('p2')));
        expect(api.writeLines, ['POST /profile/me/photos/reorder']);
        expect(api.writes.single.body, {
          'photo_ids': ['p2', 'p1'],
        });
        expect(bff.photoIds, ['p2', 'p1']);
        expect(_rowOrder(tester, ['p1', 'p2']), ['p2', 'p1']);
        expect(find.byKey(_setPrimary('p2')), findsNothing);
        expect(find.byKey(_setPrimary('p1')), findsOneWidget);
      },
    );

    // Regression (2026-10-02): a second tap before the list rebuilt sent a
    // second reorder that put the old photo back first.
    testWidgets(
      'a double tap on Set as profile picture sends one reorder '
      '[case:profile.setup_photos.setup_photos_set_primary_x_setprimary.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api);
        final link = find.byKey(_setPrimary('p2'));
        await tester.ensureVisible(link);
        await qaSettle(tester, frames: 2);
        await tester.tap(link);
        await tester.tap(link, warnIfMissed: false);
        await qaSettle(tester);
        expect(api.sent('POST', '/profile/*/photos/reorder'), hasLength(1));
        expect(bff.photoIds, ['p2', 'p1']);
        expect(_rowOrder(tester, ['p1', 'p2']), ['p2', 'p1']);
      },
    );

    testWidgets(
      'a failed reorder explains and restores the order '
      '[case:profile.setup_photos.setup_photos_set_primary_x_setprimary.api_failure]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.on(
          'POST /profile/*/photos/reorder',
          (_) => const QaReply(500, null),
        );
        await _open(tester, api);
        await _tap(tester, find.byKey(_setPrimary('p2')));
        expect(qaSnackText(tester), _en.profileSetupPhotoUpdateFailed);
        expect(api.writes, hasLength(1));
        expect(_rowOrder(tester, ['p1', 'p2']), ['p1', 'p2']);
        expect(find.byKey(_setPrimary('p2')), findsOneWidget);
      },
    );

    testWidgets(
      'dragging the first photo below the second reorders them '
      '[case:profile.setup_photos.min_plural_1_please_upload_at_le_onreorder.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api);
        await _dragBelow(tester, from: 'p1', below: 'p2');
        expect(api.writeLines, ['POST /profile/me/photos/reorder']);
        expect(api.writes.single.body, {
          'photo_ids': ['p2', 'p1'],
        });
        expect(bff.photoIds, ['p2', 'p1']);
        expect(_rowOrder(tester, ['p1', 'p2']), ['p2', 'p1']);
      },
    );

    testWidgets(
      'a failed drag reorder explains and snaps back '
      '[case:profile.setup_photos.min_plural_1_please_upload_at_le_onreorder.api_failure]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.offline('POST /profile/*/photos/reorder');
        await _open(tester, api);
        await _dragBelow(tester, from: 'p1', below: 'p2');
        expect(qaSnackText(tester), _en.networkOfflineTryAgain);
        expect(api.writes, hasLength(1));
        expect(_rowOrder(tester, ['p1', 'p2']), ['p1', 'p2']);
      },
    );
  });

  // Regression (2026-10-02): the photo list had a fixed height of 92 px per
  // row and could not be scrolled, so rows taller than that (a safety-review
  // note, large text, long translations) pushed the last photos out of reach.
  testWidgets('with five photos under review every row stays reachable '
      '[case:profile.setup_photos.photo_list_rows.action]', (tester) async {
    final api = QaApi();
    final draft = qaDraftJson(photoCount: 5);
    draft['photos'] = [
      for (final p in (draft['photos'] as List).cast<Map<String, dynamic>>())
        {...p, 'moderation_status': 'pending'},
    ];
    ProfileBff(api, draft: draft);
    await _open(tester, api);
    final list = find.byType(ReorderableListView);
    final inner = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    expect(
      tester.state<ScrollableState>(inner).position.maxScrollExtent,
      0,
      reason: 'nothing may hide inside the non-scrolling list',
    );
    for (final id in ['p1', 'p2', 'p3', 'p4', 'p5']) {
      final trash = tester.getRect(
        find.byKey(_delete(id), skipOffstage: false),
      );
      expect(tester.getRect(list).contains(trash.center), isTrue, reason: id);
    }
    // The member reaches the last photo by scrolling the page itself.
    await tester.dragUntilVisible(
      find.byKey(_delete('p5')),
      find.byType(Scrollable).first,
      const Offset(0, -150),
    );
    await qaSettle(tester, frames: 3);
    await tester.tap(find.byKey(_delete('p5')));
    await qaSettle(tester);
    expect(find.text(_en.profileSetupRemovePhotoTitle), findsOneWidget);
  });

  group('Next and Back', () {
    testWidgets('Save Photos with fewer than 2 photos explains and stays '
        '[case:profile.setup_photos.setup_photos_next_button_next.action]', (
      tester,
    ) async {
      final api = QaApi();
      ProfileBff(api, draft: qaDraftJson(photoCount: 1));
      final results = await _open(tester, api);
      await _tap(tester, find.byKey(_next));
      expect(qaSnackText(tester), _en.profileSetupPhotosMinRequired(2));
      expect(find.byType(SetupPhotosScreen), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('Save Photos with enough photos closes the editor '
        '[case:profile.setup_photos.setup_photos_next_button_next.action]', (
      tester,
    ) async {
      final api = QaApi();
      ProfileBff(api);
      final results = await _open(tester, api);
      expect(find.text(_en.profileSetupSavePhotos), findsOneWidget);
      await _tap(tester, find.byKey(_next));
      expect(find.byType(SetupPhotosScreen), findsNothing);
      expect(results, [null]);
      expect(api.writes, isEmpty, reason: 'uploads are already saved');
    });

    testWidgets('Continue in the setup flow opens About you '
        '[case:profile.setup_photos.setup_photos_next_button_next.action]', (
      tester,
    ) async {
      final api = QaApi();
      ProfileBff(api);
      await _open(tester, api, setupFlow: true);
      await _tap(tester, find.byKey(_next));
      expect(find.byType(SetupAboutScreen), findsOneWidget);
    });

    testWidgets('Back closes the photo editor '
        '[case:profile.setup_photos.back_onback.action]', (tester) async {
      final api = QaApi();
      ProfileBff(api);
      final results = await _open(tester, api);
      await tester.tap(find.byTooltip(_en.profileSetupBackTooltip));
      await qaSettle(tester);
      expect(find.byType(SetupPhotosScreen), findsNothing);
      expect(results, [null]);
      expect(api.writes, isEmpty);
    });

    testWidgets('Retry reloads photos that failed to load '
        '[case:profile.setup_photos.something_went_wrong_please_try_onretry.action]', (tester) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      api.fail('GET /profile/*/draft');
      await _open(tester, api);
      expect(find.text(_en.profileSetupLoadErrorTitle), findsOneWidget);
      expect(find.byKey(_gallery), findsNothing);
      bff.install();
      await _tap(tester, find.text(_en.profileSetupRetry));
      expect(api.sent('GET', '/profile/me/draft'), hasLength(2));
      expect(find.byKey(_delete('p1')), findsOneWidget);
      expect(find.byKey(_delete('p2')), findsOneWidget);
    });
  });

  testWidgets('renders translated in every locale '
      '[case:profile.setup_photos.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final api = QaApi();
      ProfileBff(api);
      await _open(tester, api, locale: locale);
      final l10n = qaL10n(locale);
      expect(find.text(l10n.profileSetupPhotosTitle), findsOneWidget);
      expect(find.text(l10n.profileSetupGallery), findsOneWidget);
      expect(find.text(l10n.profileSetupCamera), findsOneWidget);
      expect(find.text(l10n.profileSetupPrimaryPhoto), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}

/// Drags photo [from] by its handle until it sits below photo [below].
Future<void> _dragBelow(
  WidgetTester tester, {
  required String from,
  required String below,
}) async {
  final handle = find.byKey(_reorder(from));
  await tester.ensureVisible(handle);
  await qaSettle(tester, frames: 2);
  final target = tester.getBottomLeft(find.byKey(_delete(below))).dy + 40;
  final start = tester.getCenter(handle);
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 50));
  for (var y = start.dy; y < target; y += 20) {
    await gesture.moveTo(Offset(start.dx, y + 20));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await qaSettle(tester);
}
