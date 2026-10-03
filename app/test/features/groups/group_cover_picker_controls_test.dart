import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/features/groups/group_cover_picker.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'groups_world.dart';

// The cover photo picker: the source sheet (Choose from your photos / Take
// a photo), then the banner preview with Cancel / Use this photo. Each test
// drives the real sheets with the OS picker replaced, and asserts which
// source was asked for and what the picker hands back to its opener.

final _en = qaL10n(const Locale('en'));

/// Opens the cover picker the way the screens do and records the result.
class _Host extends ConsumerWidget {
  const _Host({required this.results});
  final List<PickedGroupCover?> results;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: IconButton(
        key: const ValueKey('qa.test.cover'),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        onPressed: () async => results.add(await pickGroupCover(context, ref)),
      ),
    ),
  );
}

Future<List<PickedGroupCover?>> _openSources(
  WidgetTester tester,
  QaCoverPicker picker,
) async {
  final results = <PickedGroupCover?>[];
  await pumpQa(
    tester,
    GroupsWorld().api,
    _Host(results: results),
    extra: [qaPickerOverride(picker)],
  );
  await qaTap(tester, qaKey('qa.test.cover'));
  expect(find.text(_en.groupsCoverSheetTitle), findsOneWidget);
  return results;
}

Finder get _preview => find.byType(GroupCoverPreview);

void main() {
  testWidgets(
    'Choose from your photos asks the gallery and shows the photo as the '
    'banner preview '
    '[case:groups.group_cover_picker.groups_cover_gallery.action]',
    (tester) async {
      final picker = QaCoverPicker(qaCoverFile('beach.png'));
      final results = await _openSources(tester, picker);
      await qaTap(tester, qaKey('groups.cover.gallery'));
      expect(picker.sources, [ImageSource.gallery]);
      expect(find.text(_en.groupsCoverSheetTitle), findsNothing);
      expect(find.text(_en.groupsCoverPreviewTitle), findsOneWidget);
      expect(tester.widget<GroupCoverPreview>(_preview).bytes, qaPng);
      expect(results, isEmpty, reason: 'nothing is chosen until confirmed');
    },
  );

  testWidgets(
    'Take a photo asks the camera and shows the photo as the banner preview '
    '[case:groups.group_cover_picker.groups_cover_camera.action]',
    (tester) async {
      final picker = QaCoverPicker(qaCoverFile('selfie.png'));
      final results = await _openSources(tester, picker);
      await qaTap(tester, qaKey('groups.cover.camera'));
      expect(picker.sources, [ImageSource.camera]);
      expect(find.text(_en.groupsCoverPreviewTitle), findsOneWidget);
      expect(_preview, findsOneWidget);
      expect(results, isEmpty);

      // Backing out of the camera (no photo) ends quietly with nothing.
      await qaTap(tester, find.text(_en.groupsCancel));
      picker.file = null;
      await qaTap(tester, qaKey('qa.test.cover'));
      await qaTap(tester, qaKey('groups.cover.camera'));
      expect(picker.sources, [ImageSource.camera, ImageSource.camera]);
      expect(find.text(_en.groupsCoverPreviewTitle), findsNothing);
      expect(results, [null, null]);
    },
  );

  testWidgets(
    'Use this photo closes the preview and hands back the photo bytes and '
    'its file name '
    '[case:groups.group_cover_picker.groups_cover_confirm.action]',
    (tester) async {
      final picker = QaCoverPicker(qaCoverFile('beach.png'));
      final results = await _openSources(tester, picker);
      await qaTap(tester, qaKey('groups.cover.gallery'));
      await qaTap(tester, qaKey('groups.cover.confirm'));
      expect(find.text(_en.groupsCoverPreviewTitle), findsNothing);
      expect(results, hasLength(1));
      expect(results.single!.filename, 'beach.png');
      expect(results.single!.bytes, qaPng);
    },
  );

  testWidgets('Cancel on the preview closes it and hands back nothing '
      '[case:groups.group_cover_picker.cancel.action]', (tester) async {
    final picker = QaCoverPicker(qaCoverFile());
    final results = await _openSources(tester, picker);
    await qaTap(tester, qaKey('groups.cover.gallery'));
    expect(_preview, findsOneWidget);
    await qaTap(tester, find.widgetWithText(OutlinedButton, _en.groupsCancel));
    expect(_preview, findsNothing);
    expect(find.text(_en.groupsCoverPreviewTitle), findsNothing);
    expect(results, [null]);
    expect(picker.sources, hasLength(1));
  });

  testWidgets(
    'the cover picker sheets render translated in every locale with nothing '
    'left in English [case:groups.group_cover_picker.l10n]',
    (tester) async {
      final picker = QaCoverPicker(qaCoverFile());
      Widget host() => const _Host(results: []);
      // The source sheet.
      await qaExpectRendersInAllLocales(
        tester,
        GroupsWorld().api,
        host,
        extra: [qaPickerOverride(picker)],
        prepare: (tester, l) => qaTap(tester, qaKey('qa.test.cover')),
        expected: [
          (l) => l.groupsCoverSheetTitle,
          (l) => l.groupsCoverSheetBody,
          (l) => l.groupsCoverFromPhotos,
          (l) => l.groupsCoverTakePhoto,
        ],
      );
      // The preview sheet.
      await qaExpectRendersInAllLocales(
        tester,
        GroupsWorld().api,
        host,
        extra: [qaPickerOverride(picker)],
        prepare: (tester, l) async {
          await qaTap(tester, qaKey('qa.test.cover'));
          await qaTap(tester, qaKey('groups.cover.gallery'));
        },
        expected: [
          (l) => l.groupsCoverPreviewTitle,
          (l) => l.groupsCoverPreviewBody,
          (l) => l.groupsCancel,
          (l) => l.groupsCoverUseThisPhoto,
        ],
      );
    },
  );
}
