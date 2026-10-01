import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';

final chapterResourceProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, path) async {
      ref.watch(authNotifierProvider.select((s) => s.userId));
      final response = await ref.watch(apiClientProvider).get<dynamic>(path);
      return (response.data as Map).cast<String, dynamic>();
    });

String chapterShareUrl(String id) {
  const configured = String.fromEnvironment('CONNECT_PUBLIC_WEB_URL');
  final base = configured.isNotEmpty
      ? Uri.parse(configured)
      : kIsWeb
      ? Uri.base
      : Uri.parse('http://127.0.0.1:4190');
  return base
      .resolve('/chapter.html')
      .replace(queryParameters: {'share': id})
      .toString();
}
