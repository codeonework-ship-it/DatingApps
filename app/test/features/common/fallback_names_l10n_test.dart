import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/constants/app_constants.dart';
import 'package:verified_dating_app/core/i18n/app_l10n.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_data.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';

void main() {
  setUp(() => setCurrentAppLocale(const Locale('de')));
  tearDown(() => setCurrentAppLocale(null));

  test('a photo byline without a name reads "Ein Mitglied" in German '
      '[case:l10n-photo-theme-byline-fallback]', () {
    final entry = ThemeEntry.fromJson({'id': 'e1', 'author_name': '  '});
    expect(entry.firstName, 'Ein Mitglied');
    expect(
      ThemeEntry.fromJson({'id': 'e2', 'author_name': 'Priya Shah'}).firstName,
      'Priya',
    );
  });

  test('a discovery profile without a name gets the German placeholder, '
      'never "Unknown" [case:l10n-discovery-name-fallback]', () {
    final profile = SwipeNotifier.discoveryProfileFromApi({'id': 'u1'});
    expect(profile.name, 'Ein Mitglied');
    expect(profile.name, isNot('Unknown'));
  });

  test('the brand name is one constant [case:l10n-brand-name-constant]', () {
    expect(AppBrand.name, 'Connect');
  });
}
