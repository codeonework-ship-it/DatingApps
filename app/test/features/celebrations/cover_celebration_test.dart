import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/celebrations/celebrations_data.dart';

void main() {
  test('a cover celebration names Cover of the Week and opens the gallery', () {
    final cover = WallCelebration.fromJson({
      'id': 'w1',
      'kind': 'cover',
      'content_id': 'p1',
      'theme_id': 't1',
      'tier': 1,
      'reach': 0,
      'title': 'Pancakes, then nowhere to be.',
    });
    expect(cover.isCover, isTrue);
    expect(cover.isPhoto, isTrue);
    expect(cover.headline, 'Your photo is Cover of the Week');
    expect(cover.message, contains('this week'));
  });

  test('wall tiers keep their headlines', () {
    WallCelebration of(String kind) => WallCelebration(
      id: 'w',
      kind: kind,
      contentId: 'c',
      tier: 1,
      reach: 50,
      title: '',
    );
    expect(of('photo').headline, 'Your photo reached 50 walls');
    expect(of('chapter').headline, 'Your chapter reached 50 walls');
    expect(of('chapter').isPhoto, isFalse);
    expect(of('photo').isCover, isFalse);
  });
}
