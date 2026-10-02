import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Flutter keeps a SnackBar with an action on screen until it is tapped
// (`persist` defaults to true when `action` is set). In this app that left
// in-app banners ("… invited you · Open") covering the profile's Message and
// Love buttons indefinitely. Every action snack bar must opt out.
void main() {
  test('every SnackBar with an action sets persist: false', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('action: SnackBarAction(')) {
          continue;
        }
        final before = lines.sublist(i < 6 ? 0 : i - 6, i).join('\n');
        if (!before.contains('persist: false')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
