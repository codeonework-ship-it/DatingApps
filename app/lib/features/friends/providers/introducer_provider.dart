import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/friend_social.dart';

class IntroducerConnection {
  const IntroducerConnection({
    required this.id,
    required this.userId,
    required this.name,
    required this.status,
    this.sharePhoto = false,
    this.shareCity = false,
  });
  factory IntroducerConnection.fromJson(Map<String, dynamic> json) =>
      IntroducerConnection(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        sharePhoto: json['share_photo'] == true,
        shareCity: json['share_city'] == true,
      );
  final String id, userId, name, status;
  final bool sharePhoto, shareCity;
}

final introducerConnectionsProvider =
    FutureProvider.autoDispose<List<IntroducerConnection>>((ref) async {
      ref.watch(authNotifierProvider.select((a) => a.userId));
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/introducer/connections');
      return ((response.data['connections'] as List?) ?? [])
          .map(
            (e) => IntroducerConnection.fromJson(
              (e as Map).cast<String, dynamic>(),
            ),
          )
          .toList();
    });

final introducerReceiptsProvider =
    FutureProvider.autoDispose<List<FriendIntro>>((ref) async {
      final id = ref.watch(authNotifierProvider.select((a) => a.userId));
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/friends/$id/intros');
      return ((response.data['made'] as List?) ?? [])
          .map((e) => FriendIntro.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    });
