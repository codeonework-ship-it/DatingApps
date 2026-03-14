import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileViewer {

  factory ProfileViewer.fromJson(Map<String, dynamic> json) => ProfileViewer(
    userId: json['user_id']?.toString() ?? '',
    name: (json['name']?.toString() ?? '').trim(),
    photoUrl: (json['photo_url']?.toString() ?? '').trim(),
    viewedAt: json['viewed_at']?.toString() ?? '',
  );
  const ProfileViewer({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.viewedAt,
  });

  final String userId;
  final String name;
  final String photoUrl;
  final String viewedAt;
}

final profileViewersProvider = FutureProvider.autoDispose<List<ProfileViewer>>((
  ref,
) async {
  final userId = ref.read(authNotifierProvider).userId;
  if (userId == null || userId.isEmpty) {
    return const [];
  }

  final dio = ref.read(apiClientProvider);
  final response = await dio.get<Map<String, dynamic>>(
    '/profile/$userId/viewers',
    queryParameters: {'limit': 100},
  );
  final body = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
  final raw = (body['viewers'] as List?) ?? const [];

  return raw
      .whereType<Map<String, dynamic>>()
      .map(ProfileViewer.fromJson)
      .where((item) => item.userId.isNotEmpty)
      .toList();
});
