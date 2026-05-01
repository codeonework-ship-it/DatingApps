import 'package:flutter_test/flutter_test.dart';

import 'package:verified_dating_app/core/constants/app_constants.dart';

void main() {
  test('photo upload max is capped at 5', () {
    expect(ValidationConstants.maxPhotos, 5);
  });
}
