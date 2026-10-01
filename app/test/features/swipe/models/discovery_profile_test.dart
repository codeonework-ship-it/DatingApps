import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';

void main() {
  test('reasons default to empty and why to null', () {
    final profile = DiscoveryProfile(
      id: 'p1',
      name: 'Asha',
      dateOfBirth: DateTime(1998, 1, 1),
      bio: null,
      additionalInfo: null,
      profession: null,
      education: null,
      instagramHandle: null,
      hobbies: const <String>[],
      favoriteSongs: const <String>[],
      extraCurriculars: const <String>[],
      intentTags: const <String>[],
      languageTags: const <String>[],
      isVerified: false,
      photoUrls: const <String>[],
    );
    expect(profile.reasons, isEmpty);
    expect(profile.why, isNull);
  });

  test('maps reasons and why from a discovery candidate row', () {
    final profile = SwipeNotifier.discoveryProfileFromApi(<String, dynamic>{
      'id': 'c1',
      'name': 'Bina',
      'isVerified': true,
      'photoUrls': <String>['https://example.com/b.jpg'],
      'reasons': <dynamic>['Shares your intent', ' Verified & active ', '', 7],
      'why': ' Picked for you today: Shares your intent ',
    });
    expect(profile.id, 'c1');
    expect(profile.reasons, <String>[
      'Shares your intent',
      'Verified & active',
      '7',
    ]);
    expect(profile.why, 'Picked for you today: Shares your intent');
  });

  test('a deck row without reasons maps to an empty list', () {
    final profile = SwipeNotifier.discoveryProfileFromApi(<String, dynamic>{
      'id': 'c2',
      'name': 'Chitra',
      'reasons': <dynamic>[],
      'why': '',
    });
    expect(profile.reasons, isEmpty);
    expect(profile.why, isNull);

    final missing = SwipeNotifier.discoveryProfileFromApi(<String, dynamic>{
      'id': 'c3',
      'name': 'Devi',
    });
    expect(missing.reasons, isEmpty);
    expect(missing.why, isNull);
  });
}
