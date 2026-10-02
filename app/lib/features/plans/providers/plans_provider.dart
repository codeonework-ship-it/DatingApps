import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/date_plan.dart';

// ── Per-match plan state ─────────────────────────────────────────────────────

class MatchPlansState {
  const MatchPlansState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.snapshot = const MatchPlansSnapshot(),
    this.loaded = false,
    this.failure,
  });

  final bool isLoading;
  final bool isMutating;

  /// The server's message, or the request's en-US fallback.
  final String? error;

  /// Set with [error] when the server sent no message: widgets show this
  /// request's fallback in the member's language (`localizedDatePlanError`).
  final DatePlanFailure? failure;
  final MatchPlansSnapshot snapshot;
  final bool loaded;

  DatePlan? get plan => snapshot.plan;

  MatchPlansState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    DatePlanFailure? failure,
    bool clearError = false,
    MatchPlansSnapshot? snapshot,
    bool? loaded,
  }) => MatchPlansState(
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    error: clearError ? null : (error ?? this.error),
    failure: clearError ? null : (error != null ? failure : this.failure),
    snapshot: snapshot ?? this.snapshot,
    loaded: loaded ?? this.loaded,
  );
}

class MatchPlansNotifier extends StateNotifier<MatchPlansState> {
  MatchPlansNotifier(this.ref, this.matchId) : super(const MatchPlansState()) {
    Future<void>.microtask(load);
  }

  final Ref ref;
  final String matchId;

  Future<void> load() async {
    if (matchId.isEmpty || matchId.startsWith('pending-')) {
      state = state.copyWith(loaded: true);
      return;
    }
    if (kUseMockAuth) {
      state = state.copyWith(
        snapshot: _mockMatchSnapshot(matchId),
        loaded: true,
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>('/matches/$matchId/plans');
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      state = state.copyWith(
        isLoading: false,
        loaded: true,
        snapshot: MatchPlansSnapshot.fromJson(body),
      );
    } on Object catch (error) {
      log.error('Date plans load failed', error);
      final failure = _planError(error, DatePlanFailure.load);
      state = state.copyWith(
        isLoading: false,
        loaded: true,
        error: failure.message,
        failure: failure.kind,
      );
    }
  }

  Future<DatePlan?> propose({
    String? sourceBlogResponseId,
    DatePlan? counterTo,
    String budgetPreference = 'flexible',
    List<String> atmospherePreferences = const <String>[],
    List<String> accessibilityPreferences = const <String>[],
    Map<String, String>? sharedWindow,
    required DateTime windowStart,
    required DateTime windowEnd,
    required String venueCategory,
    String venueName = '',
    String venueArea = '',
    String note = '',
    List<String> groupIds = const <String>[],
  }) => _mutate(
    path: counterTo == null
        ? '/matches/$matchId/plans'
        : '/matches/$matchId/plans/${counterTo.id}/counter',
    data: <String, dynamic>{
      if (sourceBlogResponseId != null)
        'source_blog_response_id': sourceBlogResponseId,
      'budget_preference': budgetPreference,
      'atmosphere_preferences': atmospherePreferences,
      'accessibility_preferences': accessibilityPreferences,
      if (sharedWindow != null) 'shared_window': sharedWindow,
      if (counterTo != null) 'expected_version': counterTo.lockVersion,
      'window_start': windowStart.toUtc().toIso8601String(),
      'window_end': windowEnd.toUtc().toIso8601String(),
      'venue_category': venueCategory,
      if (venueName.trim().isNotEmpty) 'venue_name': venueName.trim(),
      if (venueArea.trim().isNotEmpty) 'venue_area': venueArea.trim(),
      if (note.trim().isNotEmpty) 'note': note.trim(),
      'group_ids': groupIds,
    },
    failure: DatePlanFailure.propose,
  );

  Future<DatePlan?> decide({
    int? expectedVersion,
    required String planId,
    required bool accept,
    List<String> groupIds = const <String>[],
  }) => _mutate(
    path: '/matches/$matchId/plans/$planId/decision',
    data: <String, dynamic>{
      'expected_version': expectedVersion ?? state.plan?.lockVersion ?? 0,
      'decision': accept ? 'accept' : 'decline',
      'group_ids': groupIds,
    },
    failure: accept ? DatePlanFailure.accept : DatePlanFailure.decline,
  );

  Future<DatePlan?> cancel({required String planId, String reason = ''}) =>
      _mutate(
        path: '/matches/$matchId/plans/$planId/cancel',
        data: <String, dynamic>{
          if (reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
        failure: DatePlanFailure.cancel,
      );

  Future<DatePlan?> checkin({
    required String planId,
    required bool safe,
    String note = '',
  }) => _mutate(
    path: '/matches/$matchId/plans/$planId/checkin',
    data: <String, dynamic>{
      'status': safe ? 'safe' : 'need_help',
      if (note.trim().isNotEmpty) 'note': note.trim(),
    },
    failure: DatePlanFailure.checkin,
  );

  Future<DatePlan?> debrief({
    bool shareMutualInterest = false,
    required String planId,
    required bool happened,
    bool? wouldMeetAgain,
    bool? feltSafe,
    String note = '',
  }) => _mutate(
    path: '/matches/$matchId/plans/$planId/debrief',
    data: <String, dynamic>{
      'happened': happened,
      'share_mutual_interest': shareMutualInterest,
      'would_meet_again': ?wouldMeetAgain,
      'felt_safe': ?feltSafe,
      if (note.trim().isNotEmpty) 'note': note.trim(),
    },
    failure: DatePlanFailure.debrief,
  );

  Future<DatePlan?> _mutate({
    required String path,
    required Map<String, dynamic> data,
    required DatePlanFailure failure,
  }) async {
    if (kUseMockAuth) {
      return state.plan;
    }
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(path, data: data);
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final planJson = body['plan'];
      final plan = planJson is Map<dynamic, dynamic>
          ? DatePlan.fromJson(planJson.cast<String, dynamic>())
          : null;
      state = state.copyWith(isMutating: false);
      await load();
      return plan;
    } on Object catch (error) {
      log.error('Date plan mutation failed', error);
      final result = _planError(error, failure);
      state = state.copyWith(
        isMutating: false,
        error: result.message,
        failure: result.kind,
      );
      return null;
    }
  }
}

final matchPlansProvider =
    StateNotifierProvider.family<MatchPlansNotifier, MatchPlansState, String>((
      ref,
      matchId,
    ) {
      // Per member: rebuilt when someone else signs in on this device.
      watchSignedInUserId(ref);
      return MatchPlansNotifier(ref, matchId);
    });

// ── Cross-match feeds: my plans and my friends' plans ────────────────────────

class PlansFeedState {
  const PlansFeedState({
    this.isLoading = false,
    this.error,
    this.failure,
    this.mine = const <DatePlan>[],
    this.friends = const <FriendPlan>[],
  });

  final bool isLoading;

  /// The server's message, or the en-US fallback; see [failure].
  final String? error;

  /// Set with [error] when the server sent no message (see MatchPlansState).
  final DatePlanFailure? failure;
  final List<DatePlan> mine;
  final List<FriendPlan> friends;

  PlansFeedState copyWith({
    bool? isLoading,
    String? error,
    DatePlanFailure? failure,
    bool clearError = false,
    List<DatePlan>? mine,
    List<FriendPlan>? friends,
  }) => PlansFeedState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    failure: clearError ? null : (error != null ? failure : this.failure),
    mine: mine ?? this.mine,
    friends: friends ?? this.friends,
  );
}

class PlansFeedNotifier extends StateNotifier<PlansFeedState> {
  PlansFeedNotifier(this.ref) : super(const PlansFeedState()) {
    Future<void>.microtask(load);
  }

  final Ref ref;

  Future<void> load() async {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    if (kUseMockAuth) {
      state = state.copyWith(mine: _mockMyPlans(), friends: _mockFriendPlans());
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        dio.get<dynamic>(
          '/plans/$userId',
          queryParameters: {'scope': 'all', 'limit': 100},
        ),
        dio.get<dynamic>('/friends/$userId/plans'),
      ]);
      final mineBody =
          ((results[0] as dynamic).data as Map?)?.cast<String, dynamic>() ?? {};
      final friendsBody =
          ((results[1] as dynamic).data as Map?)?.cast<String, dynamic>() ?? {};
      state = state.copyWith(
        isLoading: false,
        mine: (mineBody['plans'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((row) => DatePlan.fromJson(row.cast<String, dynamic>()))
            .toList(),
        friends: (friendsBody['plans'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((row) => FriendPlan.fromJson(row.cast<String, dynamic>()))
            .toList(),
      );
    } on Object catch (error) {
      log.error('Plans feed load failed', error);
      final failure = _planError(error, DatePlanFailure.feed);
      state = state.copyWith(
        isLoading: false,
        error: failure.message,
        failure: failure.kind,
      );
    }
  }
}

final plansFeedProvider =
    StateNotifierProvider<PlansFeedNotifier, PlansFeedState>((ref) {
      // Per member: rebuilt when someone else signs in on this device.
      watchSignedInUserId(ref);
      return PlansFeedNotifier(ref);
    });

// ── Errors ───────────────────────────────────────────────────────────────────

/// en-US fallbacks kept in provider state (logs, tests); widgets show
/// `datePlanFailureMessage` in the member's language instead.
const Map<DatePlanFailure, String> _fallbacks = <DatePlanFailure, String>{
  DatePlanFailure.load: 'Unable to load date plans.',
  DatePlanFailure.feed: 'Unable to load plans.',
  DatePlanFailure.propose: 'Unable to propose this plan.',
  DatePlanFailure.accept: 'Unable to accept this plan.',
  DatePlanFailure.decline: 'Unable to decline this plan.',
  DatePlanFailure.cancel: 'Unable to cancel this plan.',
  DatePlanFailure.checkin: 'Unable to check in right now.',
  DatePlanFailure.debrief: 'Unable to save your debrief.',
};

/// The server's message when it sent one (kind null), else the en-US
/// fallback with the failed request's kind.
({String message, DatePlanFailure? kind}) _planError(
  Object error,
  DatePlanFailure failure,
) {
  final server = apiErrorMessage(error, fallback: '');
  return server.isEmpty
      ? (message: _fallbacks[failure]!, kind: failure)
      : (message: server, kind: null);
}

// ── Mock data for QA fixtures and the screen matrix ──────────────────────────

MatchPlansSnapshot _mockMatchSnapshot(String matchId) {
  final start = DateTime.now().add(const Duration(days: 2, hours: 3));
  return MatchPlansSnapshot(
    plan: DatePlan(
      id: 'plan-$matchId',
      matchId: matchId,
      proposerUserId: 'qa-user',
      inviteeUserId: 'qa-match',
      status: 'accepted',
      windowStart: start,
      windowEnd: start.add(const Duration(hours: 2)),
      venueCategory: 'coffee',
      venueArea: 'Indiranagar',
      checkinDueAt: start.add(const Duration(hours: 3)),
      viewerRole: 'proposer',
      partnerUserId: 'qa-match',
      partnerName: 'Priya',
      nextAction: 'upcoming',
      friendRecipients: 3,
    ),
    shareGroups: const <DatePlanShareGroup>[
      DatePlanShareGroup(id: 'group-1', name: 'Weekend crew'),
    ],
    canPropose: false,
    unlockState: 'conversation_unlocked',
  );
}

List<DatePlan> _mockMyPlans() => <DatePlan>[
  _mockMatchSnapshot('qa-match-1').plan!,
];

List<FriendPlan> _mockFriendPlans() {
  final start = DateTime.now().add(const Duration(days: 1, hours: 5));
  return <FriendPlan>[
    FriendPlan(
      planId: 'friend-plan-1',
      friendUserId: 'qa-friend',
      friendName: 'Meera',
      partnerName: 'Dev',
      status: 'accepted',
      latestUpdate: 'accepted',
      title: 'Meera has a date with Dev',
      description: 'Coffee · Koramangala',
      windowStart: start,
      windowEnd: start.add(const Duration(hours: 2)),
      venueCategory: 'coffee',
      venueArea: 'Koramangala',
      via: 'friend',
      updatedAt: DateTime.now(),
    ),
  ];
}
