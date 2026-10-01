import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/discovery_profile.dart';
import 'swipe_provider.dart';

/// Today's curated set: up to five members chosen once per UTC day from the
/// caller's eligible deck (`GET /discovery/{id}/today`). The server persists
/// the set, so a reload shows the same faces; members the caller has since
/// swiped, blocked or matched are dropped by the server.
class CuratedDailySetState {
  const CuratedDailySetState({
    this.profiles = const <DiscoveryProfile>[],
    this.setDate,
    this.refreshedAt,
    this.isLoading = false,
    this.error,
  });

  final List<DiscoveryProfile> profiles;
  final String? setDate;
  final DateTime? refreshedAt;
  final bool isLoading;
  final String? error;

  static const Object _unchanged = Object();

  CuratedDailySetState copyWith({
    List<DiscoveryProfile>? profiles,
    Object? setDate = _unchanged,
    Object? refreshedAt = _unchanged,
    bool? isLoading,
    Object? error = _unchanged,
  }) => CuratedDailySetState(
    profiles: profiles ?? this.profiles,
    setDate: identical(setDate, _unchanged) ? this.setDate : setDate as String?,
    refreshedAt: identical(refreshedAt, _unchanged)
        ? this.refreshedAt
        : refreshedAt as DateTime?,
    isLoading: isLoading ?? this.isLoading,
    error: identical(error, _unchanged) ? this.error : error as String?,
  );
}

class CuratedDailySetNotifier extends StateNotifier<CuratedDailySetState> {
  CuratedDailySetNotifier(this.ref)
    : super(const CuratedDailySetState(isLoading: true)) {
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
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (_disposed) {
          return;
        }
        state = CuratedDailySetState(
          profiles: _mockCuratedProfiles(),
          setDate: DateTime.now().toUtc().toIso8601String().substring(0, 10),
          refreshedAt: DateTime.now().toUtc(),
        );
        return;
      }

      final userId = ref.read(authNotifierProvider).userId;
      if (userId == null || userId.isEmpty) {
        state = const CuratedDailySetState();
        return;
      }
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>(
            '/discovery/$userId/today',
            queryParameters: ref.read(curatedDiscoveryFiltersProvider),
          );
      if (_disposed) {
        return;
      }
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final raw = (body['candidates'] as List?) ?? const [];
      final profiles = raw
          .whereType<Map<dynamic, dynamic>>()
          .map((row) => row.cast<String, dynamic>())
          .map(SwipeNotifier.discoveryProfileFromApi)
          .where((profile) => profile.id.isNotEmpty)
          .toList(growable: false);
      state = CuratedDailySetState(
        profiles: profiles,
        setDate: body['set_date']?.toString(),
        refreshedAt: DateTime.tryParse(body['refreshed_at']?.toString() ?? ''),
      );
    } on DioException catch (e, stackTrace) {
      if (_disposed) {
        return;
      }
      // A disabled flag (403) or an unavailable service simply hides the
      // rail; the deck itself is unaffected.
      log.error('Failed to load curated daily set', e, stackTrace);
      state = state.copyWith(isLoading: false, error: 'unavailable');
    } on Object catch (e, stackTrace) {
      if (_disposed) {
        return;
      }
      log.error('Failed to load curated daily set', e, stackTrace);
      state = state.copyWith(isLoading: false, error: 'unavailable');
    }
  }

  static List<DiscoveryProfile> _mockCuratedProfiles() {
    const catalogue = <List<String>>[
      <String>['Shares your intent', 'Verified & active'],
      <String>['Both reply within a day', 'Speaks your language'],
      <String>['Shows up', 'Active this week'],
      <String>['Respectful communicator', 'Shares your intent'],
      <String>['Verified & active'],
    ];
    final picks = mockDiscoveryProfiles.take(catalogue.length).toList();
    return <DiscoveryProfile>[
      for (var i = 0; i < picks.length; i++)
        DiscoveryProfile(
          id: picks[i].id,
          name: picks[i].name,
          dateOfBirth: picks[i].dateOfBirth,
          bio: picks[i].bio,
          additionalInfo: picks[i].additionalInfo,
          profession: picks[i].profession,
          education: picks[i].education,
          instagramHandle: picks[i].instagramHandle,
          hobbies: picks[i].hobbies,
          favoriteSongs: picks[i].favoriteSongs,
          extraCurriculars: picks[i].extraCurriculars,
          intentTags: picks[i].intentTags,
          languageTags: picks[i].languageTags,
          isVerified: picks[i].isVerified,
          photoUrls: picks[i].photoUrls,
          reasons: catalogue[i],
          why: 'Picked for you today: ${catalogue[i].join(' · ')}',
        ),
    ];
  }
}

final curatedDiscoveryFiltersProvider = StateProvider<Map<String, String>>((
  ref,
) {
  ref.watch(authNotifierProvider.select((auth) => auth.userId));
  return const {};
});

final curatedDailySetProvider =
    StateNotifierProvider<CuratedDailySetNotifier, CuratedDailySetState>((ref) {
      // A new session gets its own set.
      ref.watch(authNotifierProvider.select((auth) => auth.userId));
      ref.watch(curatedDiscoveryFiltersProvider);
      return CuratedDailySetNotifier(ref);
    });
