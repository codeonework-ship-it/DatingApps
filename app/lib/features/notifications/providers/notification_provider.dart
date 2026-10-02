import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/auth/auth_session_store.dart';
import '../../../core/config/app_runtime_config.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/realtime/notification_realtime_client.dart';
import '../../../core/realtime/replay_cursor_recovery.dart';
import '../../auth/providers/auth_provider.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.sequence,
    required this.eventType,
    required this.category,
    required this.title,
    required this.body,
    required this.payload,
    required this.isRead,
    required this.createdAt,
    this.actionRoute,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        sequence: (json['sequence'] as num?)?.toInt() ?? 0,
        eventType: json['event_type']?.toString() ?? '',
        category: json['category']?.toString() ?? 'system',
        title:
            json['title']?.toString() ??
            currentAppL10n().notificationsFallbackTitle,
        body: json['body']?.toString() ?? '',
        payload:
            (json['payload'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
        isRead: json['is_read'] as bool? ?? false,
        actionRoute: json['action_route']?.toString(),
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  final String id;
  final int sequence;
  final String eventType;
  final String category;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final bool isRead;
  final String? actionRoute;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    sequence: sequence,
    eventType: eventType,
    category: category,
    title: title,
    body: body,
    payload: payload,
    isRead: isRead ?? this.isRead,
    actionRoute: actionRoute,
    createdAt: createdAt,
  );
}

class PushNotificationAction {
  const PushNotificationAction({
    required this.eventType,
    required this.category,
    required this.data,
    this.actionRoute,
  });

  factory PushNotificationAction.fromData(Map<String, dynamic> data) =>
      PushNotificationAction(
        eventType: data['event_type']?.toString() ?? '',
        category: data['category']?.toString() ?? 'system',
        actionRoute: data['action_route']?.toString(),
        data: data,
      );

  final String eventType;
  final String category;
  final String? actionRoute;
  final Map<String, dynamic> data;
}

class NotificationPreferences {
  const NotificationPreferences({
    this.newMatches = true,
    this.newMessages = true,
    this.likes = true,
    this.matchNudges = true,
    this.incomingCalls = true,
    this.safety = true,
    this.friendPlans = true,
    this.inApp = true,
    this.push = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        newMatches: json['notify_new_match'] as bool? ?? true,
        newMessages: json['notify_new_message'] as bool? ?? true,
        likes: json['notify_likes'] as bool? ?? true,
        matchNudges: json['notify_match_nudges'] as bool? ?? true,
        incomingCalls: json['notify_incoming_calls'] as bool? ?? true,
        safety: json['notify_safety'] as bool? ?? true,
        friendPlans: json['notify_friend_plans'] as bool? ?? true,
        inApp: json['in_app_notifications_enabled'] as bool? ?? true,
        push: json['push_notifications_enabled'] as bool? ?? true,
      );

  final bool newMatches;
  final bool newMessages;
  final bool likes;
  final bool matchNudges;
  final bool incomingCalls;
  final bool safety;
  final bool friendPlans;
  final bool inApp;
  final bool push;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'notify_new_match': newMatches,
    'notify_new_message': newMessages,
    'notify_likes': likes,
    'notify_match_nudges': matchNudges,
    'notify_incoming_calls': incomingCalls,
    'notify_safety': safety,
    'notify_friend_plans': friendPlans,
    'in_app_notifications_enabled': inApp,
    'push_notifications_enabled': push,
  };

  NotificationPreferences copyWith({
    bool? newMatches,
    bool? newMessages,
    bool? likes,
    bool? matchNudges,
    bool? incomingCalls,
    bool? safety,
    bool? friendPlans,
    bool? inApp,
    bool? push,
  }) => NotificationPreferences(
    newMatches: newMatches ?? this.newMatches,
    newMessages: newMessages ?? this.newMessages,
    likes: likes ?? this.likes,
    matchNudges: matchNudges ?? this.matchNudges,
    incomingCalls: incomingCalls ?? this.incomingCalls,
    safety: safety ?? this.safety,
    friendPlans: friendPlans ?? this.friendPlans,
    inApp: inApp ?? this.inApp,
    push: push ?? this.push,
  );
}

class NotificationState {
  const NotificationState({
    this.items = const <AppNotification>[],
    this.preferences = const NotificationPreferences(),
    this.unreadCount = 0,
    this.lastSequence = 0,
    this.isLoading = false,
    this.isConnected = false,
    this.foregroundEvent,
    this.pushAction,
    this.error,
  });

  final List<AppNotification> items;
  final NotificationPreferences preferences;
  final int unreadCount;
  final int lastSequence;
  final bool isLoading;
  final bool isConnected;
  final AppNotification? foregroundEvent;
  final PushNotificationAction? pushAction;
  final String? error;

  NotificationState copyWith({
    List<AppNotification>? items,
    NotificationPreferences? preferences,
    int? unreadCount,
    int? lastSequence,
    bool? isLoading,
    bool? isConnected,
    Object? foregroundEvent = _unset,
    Object? pushAction = _unset,
    Object? error = _unset,
  }) => NotificationState(
    items: items ?? this.items,
    preferences: preferences ?? this.preferences,
    unreadCount: unreadCount ?? this.unreadCount,
    lastSequence: lastSequence ?? this.lastSequence,
    isLoading: isLoading ?? this.isLoading,
    isConnected: isConnected ?? this.isConnected,
    foregroundEvent: identical(foregroundEvent, _unset)
        ? this.foregroundEvent
        : foregroundEvent as AppNotification?,
    pushAction: identical(pushAction, _unset)
        ? this.pushAction
        : pushAction as PushNotificationAction?,
    error: identical(error, _unset) ? this.error : error as String?,
  );

  static const Object _unset = Object();
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this.ref) : super(const NotificationState()) {
    Future<void>.microtask(bootstrap);
  }

  final Ref ref;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _cursorRecoveryAttempted = false;
  bool _disposed = false;

  String? get _userId => ref.read(authNotifierProvider).userId;

  Future<void> bootstrap() async {
    final userId = _userId;
    if (userId == null || _disposed) {
      return;
    }
    final loaded = await _loadAuthoritativeState(userId, showLoading: true);
    if (!loaded) {
      _scheduleReconnect();
      return;
    }
    unawaited(_connect());
    unawaited(
      ref
          .read(pushNotificationServiceProvider)
          .start(userId: userId, onOpened: _onPushOpened),
    );
  }

  Future<bool> _loadAuthoritativeState(
    String userId, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final responses = await Future.wait(<Future<dynamic>>[
        ref.read(apiClientProvider).get<dynamic>('/notifications/$userId'),
        ref
            .read(apiClientProvider)
            .get<dynamic>('/notifications/$userId/unread-count'),
        ref
            .read(apiClientProvider)
            .get<dynamic>('/notifications/$userId/preferences'),
      ]);
      // Signed out or switched member while loading: this notifier is gone.
      if (_disposed) {
        return false;
      }
      final inbox = (responses[0].data as Map?)?.cast<String, dynamic>() ?? {};
      final count = (responses[1].data as Map?)?.cast<String, dynamic>() ?? {};
      final prefRoot =
          (responses[2].data as Map?)?.cast<String, dynamic>() ?? {};
      final items =
          ((inbox['notifications'] as List?) ?? const [])
              .whereType<Map<Object?, Object?>>()
              .map(
                (row) => AppNotification.fromJson(row.cast<String, dynamic>()),
              )
              .toList()
            ..sort((a, b) => b.sequence.compareTo(a.sequence));
      final preferences = NotificationPreferences.fromJson(
        (prefRoot['preferences'] as Map?)?.cast<String, dynamic>() ?? {},
      );
      final latest = items.isEmpty ? 0 : items.first.sequence;
      state = state.copyWith(
        items: items,
        preferences: preferences,
        unreadCount: (count['unread_count'] as num?)?.toInt() ?? 0,
        lastSequence: latest,
        isLoading: false,
        error: null,
      );
      return true;
    } on Object catch (error) {
      if (_disposed) {
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(
          error,
          fallback: currentAppL10n().notificationsLoadFailed,
        ),
      );
      return false;
    }
  }

  void _onPushOpened(Map<String, dynamic> data) {
    if (_disposed) {
      return;
    }
    state = state.copyWith(pushAction: PushNotificationAction.fromData(data));
  }

  void consumePushAction() {
    state = state.copyWith(pushAction: null);
  }

  Future<void> _connect() async {
    final token = AuthSessionStore.instance.accessToken;
    if (_disposed || token == null || token.isEmpty || _channel != null) {
      return;
    }
    final client = NotificationRealtimeClient(
      apiBaseUrl: AppRuntimeConfig.apiBaseUrl,
    );
    final channel = client.connect(
      accessToken: token,
      after: state.lastSequence,
    );
    _channel = channel;
    _subscription = channel.stream.listen(
      _onRealtimeData,
      onError: (_) => _onDisconnected(),
      onDone: _onDisconnected,
      cancelOnError: true,
    );
    try {
      await channel.ready;
    } on Object {
      await _subscription?.cancel();
      await channel.sink.close();
      if (identical(_channel, channel)) {
        _subscription = null;
        _channel = null;
      }
      _reconnectTimer?.cancel();
      final userId = _userId;
      if (userId != null &&
          shouldAttemptCursorSnapshot(
            lastSequence: state.lastSequence,
            alreadyAttempted: _cursorRecoveryAttempted,
          )) {
        _cursorRecoveryAttempted = true;
        final recovered = await _loadAuthoritativeState(
          userId,
          showLoading: false,
        );
        if (recovered && !_disposed) {
          _reconnectAttempt = 0;
          _scheduleReconnect(immediate: true);
          return;
        }
      }
      _scheduleReconnect();
    }
  }

  void _onRealtimeData(dynamic raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) {
        return;
      }
      final map = decoded.cast<String, dynamic>();
      if (map['type'] == 'stream.connected') {
        _reconnectAttempt = 0;
        _cursorRecoveryAttempted = false;
        state = state.copyWith(isConnected: true, error: null);
        return;
      }
      final item = AppNotification.fromJson(map);
      if (item.id.isEmpty || item.sequence <= state.lastSequence) {
        return;
      }
      state = state.copyWith(
        items: <AppNotification>[
          item,
          ...state.items.where((existing) => existing.id != item.id),
        ],
        unreadCount: state.unreadCount + (item.isRead ? 0 : 1),
        lastSequence: item.sequence,
        isConnected: true,
        foregroundEvent: item,
        error: null,
      );
    } on Object {
      // Ignore malformed frames and keep the resumable stream alive.
    }
  }

  void _onDisconnected() {
    _subscription = null;
    _channel = null;
    if (!_disposed) {
      state = state.copyWith(isConnected: false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect({bool immediate = false}) {
    if (_disposed || _reconnectTimer?.isActive == true) {
      return;
    }
    _reconnectAttempt = (_reconnectAttempt + 1).clamp(1, 6);
    final delay = immediate
        ? Duration.zero
        : Duration(seconds: 1 << (_reconnectAttempt - 1));
    _reconnectTimer = Timer(delay, () => unawaited(_connect()));
  }

  Future<void> markRead(String id) async {
    final userId = _userId;
    final item = state.items.where((entry) => entry.id == id).firstOrNull;
    if (userId == null || item == null || item.isRead) {
      return;
    }
    await ref
        .read(apiClientProvider)
        .post<dynamic>('/notifications/$userId/$id/read');
    state = state.copyWith(
      items: state.items
          .map((entry) => entry.id == id ? entry.copyWith(isRead: true) : entry)
          .toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, 1 << 31),
    );
  }

  Future<void> markAllRead() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await ref
        .read(apiClientProvider)
        .post<dynamic>('/notifications/$userId/read-all');
    state = state.copyWith(
      items: state.items.map((item) => item.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );
  }

  Future<void> dismiss(String id) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await ref
        .read(apiClientProvider)
        .delete<dynamic>('/notifications/$userId/$id');
    final removed = state.items.where((item) => item.id == id).firstOrNull;
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
      unreadCount: removed != null && !removed.isRead
          ? (state.unreadCount - 1).clamp(0, 1 << 31)
          : state.unreadCount,
    );
  }

  Future<void> updatePreferences(NotificationPreferences next) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    final previous = state.preferences;
    state = state.copyWith(preferences: next, error: null);
    try {
      final response = await ref
          .read(apiClientProvider)
          .patch<dynamic>(
            '/notifications/$userId/preferences',
            data: next.toJson(),
          );
      final root = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      state = state.copyWith(
        preferences: NotificationPreferences.fromJson(
          (root['preferences'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
      );
    } on Object catch (error) {
      state = state.copyWith(
        preferences: previous,
        error: apiErrorMessage(
          error,
          fallback: currentAppL10n().notificationsPrefsUpdateFailed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      // Per member: signing in as someone else on this device must never
      // show the previous member's notifications (the old notifier is disposed,
      // which also closes its real-time connection).
      ref.watch(authNotifierProvider.select((s) => s.userId));
      return NotificationNotifier(ref);
    });
