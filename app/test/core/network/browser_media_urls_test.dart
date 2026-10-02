import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/network/browser_media_urls.dart';

void main() {
  test(
    'local media uses same-origin API without changing external media or unrelated data',
    () {
      final result =
          browserMediaUrls({
                'photos': [
                  'http://10.0.2.2:18080/v1/media/approved/u/a.png',
                  'https://cdn.example.org/photo.png',
                ],
                'other': 'http://localhost:8000/help',
                'count': 2,
              }, Uri.parse('https://connect.example/v1'))
              as Map;
      expect(result['photos'], [
        'https://connect.example/v1/media/approved/u/a.png',
        'https://cdn.example.org/photo.png',
      ]);
      expect(result['other'], 'http://localhost:8000/help');
      expect(result['count'], 2);
    },
  );

  test('binary bodies are returned untouched', () {
    final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
    final result = browserMediaUrls(
      bytes,
      Uri.parse('https://connect.example/v1'),
    );
    expect(identical(result, bytes), isTrue);
    expect(result, isA<List<int>>());
  });
}
