// Profile-area fixtures on top of the shared QA harness (test/support/qa_api.dart):
// a stateful fake of the BFF's profile draft endpoints, so a control's
// request lands in the draft and the screen shows what the server answered,
// plus a fake image picker for the photo buttons.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// The picker's platform interface is how a test answers "Gallery"/"Camera"
// without a device (the plugin itself only re-exports a few of its types).
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:verified_dating_app/features/profile/providers/preference_master_data_provider.dart';

import '../../../support/qa_api.dart';

/// A draft as `GET /profile/{id}/draft` returns it (`{'draft': ...}`).
Map<String, dynamic> qaDraftJson({
  String name = 'Ananya',
  String bio = 'This is a sufficiently long bio for tests.',
  int photoCount = 2,
  Map<String, dynamic> extra = const {},
}) => <String, dynamic>{
  'phone_number': '+919999999999',
  'name': name,
  'date_of_birth': '1998-06-20',
  'gender': 'F',
  'photos': [
    for (var i = 0; i < photoCount; i++)
      <String, dynamic>{
        'id': 'p${i + 1}',
        'photo_url': 'https://example.com/p${i + 1}.jpg',
        'storage_path': 'photos/p${i + 1}.jpg',
        'ordering': i,
        'moderation_status': 'approved',
      },
  ],
  'bio': bio,
  'height_cm': null,
  'education': null,
  'profession': null,
  'income_range': null,
  'seeking_genders': ['M', 'F'],
  'min_age_years': 21,
  'max_age_years': 40,
  'max_distance_km': 50,
  'education_filter': <String>[],
  'serious_only': true,
  'verified_only': false,
  'hookup_only': false,
  'drinking': 'Never',
  'smoking': 'Never',
  ...extra,
};

/// Stateful fake of the profile draft API on a [QaApi]: PATCH merges the
/// body into the stored draft, photo uploads/deletes/reorders change its
/// photo list, and every answer is the whole draft, like the real BFF.
class ProfileBff {
  ProfileBff(this.api, {Map<String, dynamic>? draft})
    : draft = Map<String, dynamic>.of(draft ?? qaDraftJson()) {
    install();
  }

  final QaApi api;
  Map<String, dynamic> draft;
  var _uploads = 0;

  List<Map<String, dynamic>> get photos =>
      (draft['photos'] as List).cast<Map<String, dynamic>>();

  List<String> get photoIds => [for (final p in photos) p['id'] as String];

  QaReply _answer() => qaOk({'draft': draft});

  void install() {
    api
      ..on('GET /profile/*/draft', (_) => _answer())
      ..on('PATCH /profile/*/draft', (call) {
        draft = {...draft, ...call.body};
        return _answer();
      })
      ..on('POST /profile/*/photos', (call) {
        _uploads++;
        final id = 'up$_uploads';
        draft = {
          ...draft,
          'photos': [
            ...photos,
            {
              'id': id,
              'photo_url': 'https://example.com/$id.jpg',
              'storage_path': 'photos/$id.jpg',
              'ordering': photos.length,
              'moderation_status': 'pending',
            },
          ],
        };
        return _answer();
      })
      ..on('DELETE /profile/*/photos/*', (call) {
        final id = call.path.split('/').last;
        draft = {
          ...draft,
          'photos': [
            for (final p in photos)
              if (p['id'] != id) p,
          ],
        };
        return _answer();
      })
      ..on('POST /profile/*/photos/reorder', (call) {
        final order = (call.body['photo_ids'] as List).cast<String>();
        final byId = {for (final p in photos) p['id']: p};
        draft = {
          ...draft,
          'photos': [
            for (var i = 0; i < order.length; i++)
              {...byId[order[i]]!, 'ordering': i},
          ],
        };
        return _answer();
      })
      ..on('POST /profile/*/complete', (_) => _answer());
  }

  /// The bodies of every `PATCH /profile/{id}/draft` the app sent.
  List<Map<String, dynamic>> get patches => [
    for (final c in api.sent('PATCH', '/profile/*/draft')) c.body,
  ];
}

/// Small, fixed preference catalogue so dropdown options are known.
const qaMasterData = PreferenceMasterData(
  countries: <String>['India', 'Canada'],
  statesByCountry: <String, List<String>>{
    'India': <String>['Karnataka'],
    'Canada': <String>['Ontario'],
  },
  citiesByState: <String, List<String>>{
    'Karnataka': <String>['Bengaluru'],
    'Ontario': <String>['Toronto'],
  },
  religions: <String>['Hindu', 'Christian'],
  motherTongues: <String>['Kannada'],
  languages: <String>['English'],
  dietPreferences: <String>['Veg'],
  workoutFrequencies: <String>['Often'],
  dietTypes: <String>['Balanced'],
  sleepSchedules: <String>['Early bird'],
  travelStyles: <String>['Adventurous'],
  politicalComfortRanges: <String>['Moderate'],
);

/// Overrides the preference catalogue with [qaMasterData].
List<Override> qaMasterDataOverrides() => [
  preferenceMasterDataProvider.overrideWith((ref) async => qaMasterData),
  preferenceMasterDataOfflineProvider.overrideWith((ref) => false),
];

/// Fake device picker: answers every Gallery/Camera request with [file]
/// (null = the member cancelled) and records the sources asked for.
class QaImagePicker extends ImagePickerPlatform {
  QaImagePicker({this.file});

  XFile? file;
  final sources = <ImageSource>[];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    sources.add(source);
    return file;
  }
}

/// A small JPEG-named photo as the picker hands it over.
XFile qaPickedPhoto({String path = 'qa/beach.jpg', int? length}) =>
    XFile.fromData(
      Uint8List.fromList(List<int>.generate(64, (i) => i)),
      path: path,
      mimeType: 'image/jpeg',
      length: length,
    );

/// Installs [picker] as the platform picker for this test.
QaImagePicker installQaPicker(QaImagePicker picker) {
  final previous = ImagePickerPlatform.instance;
  ImagePickerPlatform.instance = picker;
  addTearDown(() => ImagePickerPlatform.instance = previous);
  return picker;
}

/// The multipart upload body of a photo request.
FormData uploadForm(QaCall call) => call.data! as FormData;
