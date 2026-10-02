import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../../matching/providers/match_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../payment/providers/entitlements_provider.dart';
import '../models/discovery_profile.dart';
import 'swipe_provider.dart';
import '../discover_l10n.dart';

/// A member who liked the caller and is still waiting on an answer.
class LikedMeEntry {
  const LikedMeEntry({required this.profile, this.likedAt});

  final DiscoveryProfile profile;
  final DateTime? likedAt;
}

/// Who liked me (`GET /discovery/{id}/liked-me`): members who liked the
/// caller whom the caller has neither liked nor passed back. The server drops
/// blocked, restricted and unpublished members, and answering through
/// `/swipe` removes the member from the list.
class LikedMeState {
  const LikedMeState({
    this.entries = const <LikedMeEntry>[],
    this.count = 0,
    this.isLoading = false,
    this.error,
    this.answering = const <String>{},
  });

  final List<LikedMeEntry> entries;

  /// Pending likes on the server; can exceed [entries] when the page is full.
  final int count;
  final bool isLoading;
  final String? error;

  /// Member ids with a like-back or pass in flight.
  final Set<String> answering;

  static const Object _unchanged = Object();

  LikedMeState copyWith({
    List<LikedMeEntry>? entries,
    int? count,
    bool? isLoading,
    Object? error = _unchanged,
    Set<String>? answering,
  }) => LikedMeState(
    entries: entries ?? this.entries,
    count: count ?? this.count,
    isLoading: isLoading ?? this.isLoading,
    error: identical(error, _unchanged) ? this.error : error as String?,
    answering: answering ?? this.answering,
  );
}

/// The result of liking back or passing on someone who liked the caller.
class LikedMeAnswer {
  const LikedMeAnswer({this.matchId, this.dailyLimit, this.error});

  /// Set when a like back created the match.
  final String? matchId;
  final DailyLimit? dailyLimit;
  final String? error;

  bool get succeeded => dailyLimit == null && error == null;
}

class LikedMeNotifier extends StateNotifier<LikedMeState> {
  LikedMeNotifier(this.ref) : super(const LikedMeState(isLoading: true)) {
    Future<void>.microtask(load);
  }

  final Ref ref;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_disposed) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (kUseMockAuth || kUseMockDiscoveryData) {
        final mock = mockDiscoveryProfiles.take(2).toList(growable: false);
        state = LikedMeState(
          entries: [
            for (var i = 0; i < mock.length; i++)
              LikedMeEntry(
                profile: mock[i],
                likedAt: DateTime.now().subtract(Duration(hours: i + 1)),
              ),
          ],
          count: mock.length,
        );
        return;
      }

      final userId = ref.read(authNotifierProvider).userId;
      if (userId == null || userId.isEmpty) {
        state = const LikedMeState();
        return;
      }
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>(
            '/discovery/$userId/liked-me',
            queryParameters: {'limit': 100},
          );
      if (_disposed) {
        return;
      }
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final raw = (body['profiles'] as List?) ?? const [];
      final entries = raw
          .whereType<Map<dynamic, dynamic>>()
          .map((row) => row.cast<String, dynamic>())
          .map(
            (row) => LikedMeEntry(
              profile: SwipeNotifier.discoveryProfileFromApi(row),
              likedAt: DateTime.tryParse(row['liked_at']?.toString() ?? ''),
            ),
          )
          .where((entry) => entry.profile.id.isNotEmpty)
          .toList(growable: false);
      state = LikedMeState(
        entries: entries,
        count: (body['count'] as num?)?.toInt() ?? entries.length,
      );
    } on Object catch (e, stackTrace) {
      if (_disposed) {
        return;
      }
      log.error('Failed to load who liked me', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(e, fallback: DiscoverMessages.loadLikedMe),
      );
    }
  }

  /// Likes back (creating the match) or passes on [profile]. On success the
  /// member leaves the list; on failure the list is unchanged.
  Future<LikedMeAnswer> answer(
    DiscoveryProfile profile, {
    required bool like,
  }) async {
    if (state.answering.contains(profile.id)) {
      return const LikedMeAnswer(error: DiscoverMessages.answerInFlight);
    }
    state = state.copyWith(answering: {...state.answering, profile.id});
    try {
      String? matchId;
      if (!(kUseMockAuth || kUseMockDiscoveryData)) {
        final userId = ref.read(authNotifierProvider).userId;
        if (userId == null || userId.isEmpty) {
          return const LikedMeAnswer(
            error: DiscoverMessages.sessionUnavailable,
          );
        }
        final response = await ref
            .read(apiClientProvider)
            .post<Map<String, dynamic>>(
              '/swipe',
              data: {
                'user_id': userId,
                'target_user_id': profile.id,
                'is_like': like,
              },
            );
        final id = response.data?['match_id']?.toString() ?? '';
        matchId = id.isEmpty ? null : id;
      }
      if (_disposed) {
        return LikedMeAnswer(matchId: matchId);
      }
      final remaining = state.entries
          .where((entry) => entry.profile.id != profile.id)
          .toList(growable: false);
      state = state.copyWith(
        entries: remaining,
        count: state.count > 0 ? state.count - 1 : 0,
      );
      if (matchId != null) {
        await ref.read(matchNotifierProvider.notifier).refresh();
      }
      return LikedMeAnswer(matchId: matchId);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to answer a like', e, stackTrace);
      final limit = e.response?.statusCode == 429
          ? DailyLimit.fromRefusal(e.response?.data)
          : null;
      if (limit != null) {
        return LikedMeAnswer(dailyLimit: limit);
      }
      return LikedMeAnswer(
        error: apiErrorMessage(e, fallback: DiscoverMessages.answer),
      );
    } on Object catch (e, stackTrace) {
      log.error('Failed to answer a like', e, stackTrace);
      return const LikedMeAnswer(error: DiscoverMessages.answer);
    } finally {
      if (!_disposed) {
        state = state.copyWith(
          answering: {...state.answering}..remove(profile.id),
        );
      }
    }
  }
}

final likedMeProvider = StateNotifierProvider<LikedMeNotifier, LikedMeState>((
  ref,
) {
  // A new session gets its own list.
  ref.watch(authNotifierProvider.select((auth) => auth.userId));
  final notifier = LikedMeNotifier(ref);
  // A new like arriving over the notification stream refreshes the list, so
  // the count on Discover stays current without polling.
  ref.listen<int>(
    notificationProvider.select(
      (s) => s.items
          .where((n) => n.eventType == 'like.received')
          .fold<int>(
            0,
            (latest, n) => n.sequence > latest ? n.sequence : latest,
          ),
    ),
    (previous, next) {
      if (previous != null && next > previous) {
        notifier.load();
      }
    },
  );
  return notifier;
});
