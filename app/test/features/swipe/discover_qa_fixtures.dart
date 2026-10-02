// Shared fixtures for the Discover / Spotlight / profile / Liked-you control
// tests: a recording fake BFF (test/support/qa_api.dart) pre-loaded with the
// routes those screens read, plus member rows in the server's shape.

import 'dart:async';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/friends/models/friend_social.dart';
import 'package:verified_dating_app/features/friends/providers/friend_social_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';

import '../../support/qa_api.dart';

/// A `/discovery` (or `/today`, `/liked-me`) row in the server's shape.
Map<String, dynamic> qaCandidate(
  String id,
  String name, {
  int age = 29,
  bool verified = true,
  bool spotlight = false,
  List<String> reasons = const [],
  String? likedAt,
}) => {
  'id': id,
  'name': name,
  'age': age,
  'bio': '$name sketches strangers on trains.',
  'profession': 'Designer',
  'isVerified': verified,
  'is_spotlight': spotlight,
  'reasons': reasons,
  'liked_at': ?likedAt,
};

/// A member as the app holds it, without photos (network images cannot load
/// in widget tests).
DiscoveryProfile qaMember(
  String id,
  String name, {
  int age = 29,
  bool verified = true,
}) => DiscoveryProfile(
  id: id,
  name: name,
  dateOfBirth: null,
  publicAge: age,
  bio: '$name sketches strangers on trains.',
  additionalInfo: null,
  profession: 'Designer',
  education: null,
  instagramHandle: null,
  hobbies: const [],
  favoriteSongs: const [],
  extraCurriculars: const [],
  intentTags: const [],
  languageTags: const [],
  isVerified: verified,
  photoUrls: const [],
);

/// A `/matches/{me}` row.
Map<String, dynamic> qaMatchRow(
  String matchId,
  String userId,
  String name, {
  String lastMessage = 'Hi there',
  int unread = 0,
}) => {
  'id': matchId,
  'user_id': userId,
  'user_name': name,
  'last_message': lastMessage,
  'last_message_time': '2026-10-02T10:00:00Z',
  'unreadCount': unread,
};

/// The fake BFF behind Discover. Every list starts empty; pass rows to fill
/// the deck, Spotlight, Today, Liked you and the member's matches. `POST
/// /swipe` answers [swipe] (add `match_id` for a mutual like).
QaApi qaDiscoverApi({
  List<Map<String, dynamic>> deck = const [],
  List<Map<String, dynamic>> spotlight = const [],
  List<Map<String, dynamic>> today = const [],
  List<Map<String, dynamic>> likedMe = const [],
  List<Map<String, dynamic>> matches = const [],
  Map<String, dynamic> swipe = const {},
}) {
  final names = <String, String>{
    for (final row in [...deck, ...spotlight, ...today, ...likedMe])
      row['id'] as String: row['name'] as String,
  };
  final api = QaApi()
    ..json('GET /discovery/me', {
      'candidates': deck,
      'spotlight_profiles': spotlight,
    })
    ..json('GET /discovery/me/today', {
      'candidates': today,
      'set_date': '2026-10-02',
    })
    ..json('GET /discovery/me/liked-me', {
      'profiles': likedMe,
      'count': likedMe.length,
    })
    ..json('GET /matches/me', {'matches': matches})
    ..json('POST /swipe', swipe)
    ..json('POST /profile/views', <String, dynamic>{})
    ..on('GET /profile/*', (call) {
      final id = call.path.split('/').last;
      return qaOk({
        'found': true,
        'profile': {
          'id': id,
          'name': names[id] ?? 'Member',
          'age': 29,
          'bio': '${names[id] ?? 'Member'} sketches strangers on trains.',
          'profession': 'Designer',
          'isVerified': true,
        },
      });
    })
    ..json('GET /engagement/daily-prompt/me', <String, dynamic>{})
    ..json('GET /engagement/daily-prompt/me/responders', {
      'responders': <dynamic>[],
    })
    ..json('GET /account/me/dating-preferences', <String, dynamic>{})
    ..json('GET /account/me/discovery/pause', {'paused': false})
    ..json('GET /friends/me', {'friends': <dynamic>[]})
    ..json('GET /friends/me/activities', {'activities': <dynamic>[]})
    // What a chat reads when Message opens one.
    ..json('GET /chat/*/messages', {'messages': <dynamic>[]})
    ..json('GET /matches/*/unlock-state', {'chat_unlocked': true})
    ..json('GET /matches/*/trust', <String, dynamic>{})
    ..json('GET /chat/gifts', {'gifts': <dynamic>[]})
    ..json('GET /wallet/me/coins', {'coins': 0});
  return api;
}

/// The `POST /swipe` bodies the app sent, in order.
List<Map<String, dynamic>> qaSwipes(QaApi api) =>
    api.sent('POST', '/swipe').map((c) => c.body).toList();

/// One like (`is_like: true`) or pass for [target] from the signed-in member.
Map<String, dynamic> qaSwipeBody(String target, {required bool like}) => {
  'user_id': 'me',
  'target_user_id': target,
  'is_like': like,
};

/// The daily-like refusal the BFF sends with a 429.
QaReply qaDailyLikeLimit() => const QaReply(429, {
  'success': false,
  'error': 'Daily like limit reached',
  'error_code': 'DAILY_LIKE_LIMIT_REACHED',
  'kind': 'like',
  'limit': 10,
  'plan_name': 'Free',
  'resets_at': '2026-10-03T00:00:00Z',
});

class _QuietNotifications extends NotificationNotifier {
  _QuietNotifications(super.ref);

  @override
  Future<void> bootstrap() async {}
}

/// Overrides every Discover-family screen needs beside the fake API: the
/// notification socket stays closed and the profile page's vouches and
/// stories are empty.
List<Override> qaDiscoverExtras() => [
  notificationProvider.overrideWith(_QuietNotifications.new),
  publicVouchesProvider.overrideWith((ref, id) async => const <PublicVouch>[]),
  profileStoriesProvider.overrideWith(
    (ref, id) async => {'published': false, 'stories': <dynamic>[]},
  ),
];

class _SilentHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  /// Photos stay "loading": no request ever completes, so no error either.
  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Completer<HttpClientRequest>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SilentHttp extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _SilentHttpClient();
}

/// Call at the top of `main()`: network photos (the server's placeholder,
/// the match screen's avatars) never load in widget tests, and the default
/// test client fails them with errors that are noise, not findings.
void qaSilenceNetworkImages() {
  setUpAll(() => HttpOverrides.global = _SilentHttp());
}

/// Network photos cannot load in widget tests; drop exactly those errors,
/// nothing else.
void qaDropImageErrors(WidgetTester tester) {
  for (var e = tester.takeException(); e != null; e = tester.takeException()) {
    expect(e, isA<NetworkImageLoadException>());
  }
}
