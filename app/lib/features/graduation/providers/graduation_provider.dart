import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/graduation.dart';

// ── Per-match graduation state ───────────────────────────────────────────────

class MatchGraduationState {
  const MatchGraduationState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.snapshot = const MatchGraduationSnapshot(),
    this.loaded = false,
    this.failure,
  });

  final bool isLoading;
  final bool isMutating;

  /// The server's message, or the request's en-US fallback.
  final String? error;

  /// Set with [error] when the server sent no message: widgets show this
  /// request's fallback in the member's language (`localizedGraduationError`).
  final GraduationFailure? failure;
  final MatchGraduationSnapshot snapshot;
  final bool loaded;

  Graduation? get graduation => snapshot.graduation;

  MatchGraduationState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    GraduationFailure? failure,
    bool clearError = false,
    MatchGraduationSnapshot? snapshot,
    bool? loaded,
  }) => MatchGraduationState(
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    error: clearError ? null : (error ?? this.error),
    failure: clearError ? null : (error != null ? failure : this.failure),
    snapshot: snapshot ?? this.snapshot,
    loaded: loaded ?? this.loaded,
  );
}

class MatchGraduationNotifier extends StateNotifier<MatchGraduationState> {
  MatchGraduationNotifier(this.ref, this.matchId)
    : super(const MatchGraduationState()) {
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
      state = state.copyWith(snapshot: _mockSnapshot(matchId), loaded: true);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>('/matches/$matchId/graduation');
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      state = state.copyWith(
        isLoading: false,
        loaded: true,
        snapshot: MatchGraduationSnapshot.fromJson(body),
      );
    } on Object catch (error) {
      log.error('Graduation load failed', error);
      final result = _graduationError(error, GraduationFailure.load);
      state = state.copyWith(
        isLoading: false,
        loaded: true,
        error: result.message,
        failure: result.kind,
      );
    }
  }

  Future<Graduation?> propose({
    String note = '',
    bool shareWithFriends = false,
  }) => _mutate(
    path: '/matches/$matchId/graduation',
    data: <String, dynamic>{
      if (note.trim().isNotEmpty) 'note': note.trim(),
      'share_with_friends': shareWithFriends,
    },
    failure: GraduationFailure.propose,
  );

  Future<Graduation?> decide({
    required String graduationId,
    required bool confirm,
    bool shareWithFriends = false,
  }) => _mutate(
    path: '/matches/$matchId/graduation/$graduationId/decision',
    data: <String, dynamic>{
      'decision': confirm ? 'confirm' : 'decline',
      'share_with_friends': shareWithFriends,
    },
    failure: confirm ? GraduationFailure.confirm : GraduationFailure.decline,
  );

  Future<Graduation?> withdraw({required String graduationId}) => _mutate(
    path: '/matches/$matchId/graduation/$graduationId/withdraw',
    data: const <String, dynamic>{},
    failure: GraduationFailure.withdraw,
  );

  Future<Graduation?> _mutate({
    required String path,
    required Map<String, dynamic> data,
    required GraduationFailure failure,
  }) async {
    if (kUseMockAuth) {
      return state.graduation;
    }
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(path, data: data);
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final json = body['graduation'];
      final graduation = json is Map<dynamic, dynamic>
          ? Graduation.fromJson(json.cast<String, dynamic>())
          : null;
      state = state.copyWith(isMutating: false);
      await load();
      return graduation;
    } on Object catch (error) {
      log.error('Graduation mutation failed', error);
      final result = _graduationError(error, failure);
      state = state.copyWith(
        isMutating: false,
        error: result.message,
        failure: result.kind,
      );
      return null;
    }
  }
}

final matchGraduationProvider =
    StateNotifierProvider.family<
      MatchGraduationNotifier,
      MatchGraduationState,
      String
    >((ref, matchId) {
      // Per member: rebuilt when someone else signs in on this device.
      watchSignedInUserId(ref);
      return MatchGraduationNotifier(ref, matchId);
    });

// ── The member's own discovery pause ─────────────────────────────────────────

class DiscoveryPauseState {
  const DiscoveryPauseState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.loaded = false,
    this.paused = false,
    this.pause,
    this.failure,
  });

  final bool isLoading;
  final bool isMutating;

  /// The server's message, or the request's en-US fallback.
  final String? error;

  /// Set with [error] when the server sent no message: widgets show this
  /// request's fallback in the member's language (`localizedGraduationError`).
  final GraduationFailure? failure;
  final bool loaded;
  final bool paused;
  final DiscoveryPause? pause;

  DiscoveryPauseState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    GraduationFailure? failure,
    bool clearError = false,
    bool? loaded,
    bool? paused,
    DiscoveryPause? pause,
    bool clearPause = false,
  }) => DiscoveryPauseState(
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    error: clearError ? null : (error ?? this.error),
    failure: clearError ? null : (error != null ? failure : this.failure),
    loaded: loaded ?? this.loaded,
    paused: paused ?? this.paused,
    pause: clearPause ? null : (pause ?? this.pause),
  );
}

class DiscoveryPauseNotifier extends StateNotifier<DiscoveryPauseState> {
  DiscoveryPauseNotifier(this.ref) : super(const DiscoveryPauseState()) {
    Future<void>.microtask(load);
  }

  final Ref ref;

  String? get _userId => ref.read(authNotifierProvider).userId;

  Future<void> load() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(loaded: true);
      return;
    }
    if (kUseMockAuth) {
      state = state.copyWith(loaded: true, paused: false);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>('/account/$userId/discovery/pause');
      _apply(response.data);
    } on Object catch (error) {
      log.error('Discovery pause load failed', error);
      // The screen may have closed while the request was in flight.
      if (!mounted) {
        return;
      }
      final result = _graduationError(error, GraduationFailure.pauseLoad);
      state = state.copyWith(
        isLoading: false,
        loaded: true,
        error: result.message,
        failure: result.kind,
      );
    }
  }

  Future<bool> pauseDiscovery() => _mutate(
    action: 'pause',
    data: const <String, dynamic>{'reason': 'manual'},
    failure: GraduationFailure.pause,
  );

  Future<bool> resumeDiscovery() => _mutate(
    action: 'resume',
    data: const <String, dynamic>{},
    failure: GraduationFailure.resume,
  );

  Future<bool> _mutate({
    required String action,
    required Map<String, dynamic> data,
    required GraduationFailure failure,
  }) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return false;
    }
    if (kUseMockAuth) {
      state = state.copyWith(
        paused: action == 'pause',
        pause: action == 'pause'
            ? DiscoveryPause(reason: 'manual', pausedAt: DateTime.now())
            : null,
        clearPause: action != 'pause',
      );
      return true;
    }
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>('/account/$userId/discovery/$action', data: data);
      _apply(response.data);
      return true;
    } on Object catch (error) {
      log.error('Discovery pause mutation failed', error);
      if (!mounted) {
        return false;
      }
      final result = _graduationError(error, failure);
      state = state.copyWith(
        isMutating: false,
        error: result.message,
        failure: result.kind,
      );
      return false;
    }
  }

  void _apply(Object? payload) {
    if (!mounted) {
      return;
    }
    final body = (payload as Map?)?.cast<String, dynamic>() ?? {};
    final pauseJson = body['pause'];
    state = state.copyWith(
      isLoading: false,
      isMutating: false,
      loaded: true,
      paused: body['paused'] as bool? ?? false,
      pause: pauseJson is Map<dynamic, dynamic>
          ? DiscoveryPause.fromJson(pauseJson.cast<String, dynamic>())
          : null,
      clearPause: pauseJson is! Map<dynamic, dynamic>,
    );
  }
}

final discoveryPauseProvider =
    StateNotifierProvider<DiscoveryPauseNotifier, DiscoveryPauseState>((ref) {
      // Per member: rebuilt when someone else signs in on this device.
      watchSignedInUserId(ref);
      return DiscoveryPauseNotifier(ref);
    });

// ── Errors ───────────────────────────────────────────────────────────────────

/// en-US fallbacks kept in provider state (logs, tests); widgets show
/// `graduationFailureMessage` in the member's language instead.
const Map<GraduationFailure, String> _fallbacks = <GraduationFailure, String>{
  GraduationFailure.load: 'Unable to load graduation.',
  GraduationFailure.propose: 'Unable to propose leaving together.',
  GraduationFailure.confirm: 'Unable to confirm right now.',
  GraduationFailure.decline: 'Unable to decline right now.',
  GraduationFailure.withdraw: 'Unable to withdraw the proposal.',
  GraduationFailure.pauseLoad: 'Unable to load discovery status.',
  GraduationFailure.pause: 'Unable to pause discovery.',
  GraduationFailure.resume: 'Unable to resume discovery.',
};

/// The server's message when it sent one (kind null), else the en-US
/// fallback with the failed request's kind.
({String message, GraduationFailure? kind}) _graduationError(
  Object error,
  GraduationFailure failure,
) {
  final server = apiErrorMessage(error, fallback: '');
  return server.isEmpty
      ? (message: _fallbacks[failure]!, kind: failure)
      : (message: server, kind: null);
}

// ── Mock data for QA fixtures and the screen matrix ──────────────────────────

MatchGraduationSnapshot _mockSnapshot(String matchId) =>
    MatchGraduationSnapshot(
      graduation: Graduation(
        id: 'graduation-$matchId',
        matchId: matchId,
        proposerUserId: 'qa-match',
        partnerUserId: 'qa-user',
        status: 'proposed',
        note: 'I think we found each other.',
        proposerShareWithFriends: true,
        viewerRole: 'partner',
        otherUserId: 'qa-match',
        otherName: 'Priya',
        nextAction: 'decide',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      unlockState: 'conversation_unlocked',
    );
