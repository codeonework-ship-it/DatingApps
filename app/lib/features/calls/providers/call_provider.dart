import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/permissions/device_permission_service.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../auth/providers/auth_provider.dart';

class CallSession {
  const CallSession({
    required this.id,
    required this.matchId,
    required this.initiatorId,
    required this.recipientId,
    required this.status,
    required this.roomId,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.endedByUserId,
    this.joinUrl,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) => CallSession(
    id: json['id']?.toString() ?? '',
    matchId: json['match_id']?.toString() ?? '',
    initiatorId: json['initiator_id']?.toString() ?? '',
    recipientId: json['recipient_id']?.toString() ?? '',
    status: json['status']?.toString() ?? 'unknown',
    roomId: json['room_id']?.toString() ?? '',
    startedAt:
        DateTime.tryParse(json['started_at']?.toString() ?? '') ??
        DateTime.now(),
    endedAt: DateTime.tryParse(json['ended_at']?.toString() ?? ''),
    durationSeconds: (json['duration_sec'] as num?)?.toInt() ?? 0,
    endedByUserId: json['ended_by_user_id']?.toString(),
    joinUrl: json['join_url']?.toString(),
  );

  final String id;
  final String matchId;
  final String initiatorId;
  final String recipientId;
  final String status;
  final String roomId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? endedByUserId;
  final String? joinUrl;
}

/// Why a call action failed, so the screen can show the message in the
/// reader's language. `null` with a non-null [CallState.error] means the
/// server sent its own text.
enum CallErrorKind {
  signInForHistory,
  signInToCall,
  permissions,
  loadHistory,
  start,
  end,
  notConfigured,
  openRoom,
}

class CallState {
  const CallState({
    this.history = const [],
    this.activeSession,
    this.isLoading = false,
    this.isStarting = false,
    this.isEnding = false,
    this.error,
    this.errorKind,
    this.permissionDenied = false,
  });

  final List<CallSession> history;
  final CallSession? activeSession;
  final bool isLoading;
  final bool isStarting;
  final bool isEnding;
  final String? error;
  final CallErrorKind? errorKind;
  final bool permissionDenied;

  CallState copyWith({
    List<CallSession>? history,
    Object? activeSession = _unset,
    bool? isLoading,
    bool? isStarting,
    bool? isEnding,
    Object? error = _unset,
    Object? errorKind = _unset,
    bool? permissionDenied,
  }) => CallState(
    history: history ?? this.history,
    activeSession: identical(activeSession, _unset)
        ? this.activeSession
        : activeSession as CallSession?,
    isLoading: isLoading ?? this.isLoading,
    isStarting: isStarting ?? this.isStarting,
    isEnding: isEnding ?? this.isEnding,
    error: identical(error, _unset) ? this.error : error as String?,
    // A new error without a kind is server text; clearing the error clears
    // its kind too.
    errorKind: !identical(errorKind, _unset)
        ? errorKind as CallErrorKind?
        : identical(error, _unset)
        ? this.errorKind
        : null,
    permissionDenied: permissionDenied ?? this.permissionDenied,
  );

  static const Object _unset = Object();
}

class CallNotifier extends StateNotifier<CallState> {
  CallNotifier(this.ref) : super(const CallState());

  final Ref ref;

  String? get _userId => ref.read(authNotifierProvider).userId;

  Future<void> loadHistory() async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(
        error: 'Please sign in to view call history.',
        errorKind: CallErrorKind.signInForHistory,
      );
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>(
            '/calls/history/$userId',
            queryParameters: const {'limit': 100},
          );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final history = ((body['history'] as List?) ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map((row) => CallSession.fromJson(row.cast<String, dynamic>()))
          .toList();
      state = state.copyWith(history: history, isLoading: false, error: null);
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(error, fallback: 'Unable to load call history.'),
        errorKind: _fallbackKind(error, CallErrorKind.loadHistory),
      );
    }
  }

  Future<CallSession?> startCall({
    required String matchId,
    required String recipientUserId,
  }) async {
    final userId = _userId;
    if (userId == null) {
      state = state.copyWith(
        error: 'Please sign in before starting a call.',
        errorKind: CallErrorKind.signInToCall,
      );
      return null;
    }

    state = state.copyWith(
      isStarting: true,
      error: null,
      permissionDenied: false,
    );
    try {
      final granted = await ref
          .read(devicePermissionServiceProvider)
          .requestCallPermissions();
      if (!granted) {
        state = state.copyWith(
          isStarting: false,
          permissionDenied: true,
          error: 'Camera and microphone permissions are required for calls.',
          errorKind: CallErrorKind.permissions,
        );
        return null;
      }

      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/calls/start',
            data: {
              'match_id': matchId,
              'initiator_user_id': userId,
              'recipient_user_id': recipientUserId,
            },
          );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final raw = (body['session'] as Map?)?.cast<String, dynamic>();
      if (raw == null) throw const FormatException('Missing call session');
      final session = CallSession.fromJson(raw);
      state = state.copyWith(
        activeSession: session,
        isStarting: false,
        error: null,
      );
      return session;
    } on Object catch (error) {
      state = state.copyWith(
        isStarting: false,
        error: apiErrorMessage(
          error,
          fallback: 'Unable to start the call session.',
        ),
        errorKind: _fallbackKind(error, CallErrorKind.start),
      );
      return null;
    }
  }

  Future<bool> endCall() async {
    final userId = _userId;
    final active = state.activeSession;
    if (userId == null || active == null) return false;
    state = state.copyWith(isEnding: true, error: null);
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/calls/${active.id}/end',
            data: {'ended_by_user_id': userId},
          );
      final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      final raw = (body['session'] as Map?)?.cast<String, dynamic>();
      final ended = raw == null ? active : CallSession.fromJson(raw);
      state = state.copyWith(
        activeSession: null,
        history: [ended, ...state.history.where((item) => item.id != ended.id)],
        isEnding: false,
      );
      return true;
    } on Object catch (error) {
      state = state.copyWith(
        isEnding: false,
        error: apiErrorMessage(error, fallback: 'Unable to end the call.'),
        errorKind: _fallbackKind(error, CallErrorKind.end),
      );
      return false;
    }
  }

  Future<bool> openLiveRoom(CallSession session) async {
    final raw = session.joinUrl?.trim() ?? '';
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https') {
      state = state.copyWith(
        error: 'Live call rooms are not configured for this environment.',
        errorKind: CallErrorKind.notConfigured,
      );
      return false;
    }
    final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!opened) {
      state = state.copyWith(
        error: 'Unable to open the live call room.',
        errorKind: CallErrorKind.openRoom,
      );
    }
    return opened;
  }

  void clearError() => state = state.copyWith(error: null);
}

/// [kind] when [error] carries no server text of its own (the message is
/// the local fallback), otherwise `null` so the server's text is shown.
CallErrorKind? _fallbackKind(Object error, CallErrorKind kind) =>
    apiErrorMessage(error, fallback: '').isEmpty ? kind : null;

final callProvider = StateNotifierProvider<CallNotifier, CallState>(
  (ref) => CallNotifier(ref),
);
