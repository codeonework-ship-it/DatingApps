import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/auth/auth_session_store.dart';
import '../../core/config/app_runtime_config.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/realtime/chat_realtime_client.dart';
import '../auth/providers/auth_provider.dart';

/// Shared chat for friend conversations, Conversation Rooms and groups
/// (`/v1/social/...`, migration 115). One [SocialChannel] per friend pair,
/// room or group; messages arrive over the same websocket match chat uses.

/// Conversations currently on screen, so foreground notifications for them
/// are skipped (the member is already reading them).
abstract final class SocialChatFocus {
  static final Set<String> open = <String>{};
}

int _int(Object? v) => v is num ? v.toInt() : 0;

DateTime? _time(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

class SocialChannel {
  const SocialChannel({
    required this.id,
    required this.kind,
    required this.title,
    this.refId = '',
    this.peerId = '',
    this.memberCount = 0,
    this.canModerate = false,
    this.lastMessageAt,
    this.lastMessage = '',
    this.unreadCount = 0,
    this.readOnly = false,
    this.readOnlyUntil,
    this.readOnlyMessage = '',
    this.muted = false,
    this.mutedUntil,
  });

  factory SocialChannel.fromJson(Map<dynamic, dynamic> json) => SocialChannel(
    id: json['id'] as String,
    kind: json['kind'] as String? ?? 'friend',
    title: json['title'] as String? ?? '',
    refId: json['ref_id'] as String? ?? '',
    peerId: json['peer_id'] as String? ?? '',
    memberCount: _int(json['member_count']),
    canModerate: json['can_moderate'] == true,
    lastMessageAt: _time(json['last_message_at']),
    lastMessage: json['last_message'] as String? ?? '',
    unreadCount: _int(json['unread_count']),
    readOnly: json['read_only'] == true,
    readOnlyUntil: _time(json['read_only_until']),
    readOnlyMessage: json['read_only_message'] as String? ?? '',
    muted: json['muted'] == true,
    mutedUntil: _time(json['muted_until']),
  );

  final String id;

  /// `friend`, `room` or `group`.
  final String kind;
  final String title;

  /// The room or group id (room and group channels).
  final String refId;

  /// The other friend (friend channels).
  final String peerId;
  final int memberCount;

  /// A room host or group owner/moderator may remove others' messages.
  final bool canModerate;
  final DateTime? lastMessageAt;
  final String lastMessage;
  final int unreadCount;

  /// The member may read but not post (muted in a room), until
  /// [readOnlyUntil] (null: until lifted).
  final bool readOnly;
  final DateTime? readOnlyUntil;

  /// The server's explanation of [readOnly], in English.
  final String readOnlyMessage;

  /// The member silenced this conversation's notifications, until
  /// [mutedUntil] (null while muted: until they turn them back on).
  final bool muted;
  final DateTime? mutedUntil;

  /// Rooms never notify, so they offer no notification mute.
  bool get canMuteNotifications => kind != 'room';

  /// This channel with a new notification mute state.
  SocialChannel withMute({required bool muted, DateTime? mutedUntil}) =>
      SocialChannel(
        id: id,
        kind: kind,
        title: title,
        refId: refId,
        peerId: peerId,
        memberCount: memberCount,
        canModerate: canModerate,
        lastMessageAt: lastMessageAt,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        readOnly: readOnly,
        readOnlyUntil: readOnlyUntil,
        readOnlyMessage: readOnlyMessage,
        muted: muted,
        mutedUntil: muted ? mutedUntil : null,
      );
}

/// How long to mute a conversation's notifications, as the API spells it.
enum SocialMuteDuration {
  oneHour('1h'),
  eightHours('8h'),
  oneWeek('1w'),
  untilTurnedOn('forever');

  const SocialMuteDuration(this.api);
  final String api;
}

/// `PUT /social/channels/{id}/mute`, or `DELETE` when [duration] is null.
Future<SocialChannel> setSocialChannelMute(
  Dio api,
  String channelId,
  SocialMuteDuration? duration,
) async {
  final response = duration == null
      ? await api.delete<dynamic>('/social/channels/$channelId/mute')
      : await api.put<dynamic>(
          '/social/channels/$channelId/mute',
          data: {'duration': duration.api},
        );
  return SocialChannel.fromJson((response.data as Map)['channel'] as Map);
}

class SocialMessage {
  const SocialMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.body,
    required this.clientMessageId,
    required this.createdAt,
    this.senderName = '',
    this.senderPhotoUrl = '',
    this.deleted = false,
    this.mine = false,
    this.pending = false,
    this.failed = false,
  });

  factory SocialMessage.fromJson(Map<dynamic, dynamic> json) => SocialMessage(
    id: json['id'] as String,
    channelId: json['channel_id'] as String? ?? '',
    senderId: json['sender_id'] as String? ?? '',
    senderName: json['sender_name'] as String? ?? '',
    senderPhotoUrl: json['sender_photo_url'] as String? ?? '',
    body: json['body'] as String? ?? '',
    clientMessageId: json['client_message_id'] as String? ?? '',
    createdAt: _time(json['created_at']) ?? DateTime.now(),
    deleted: json['deleted'] == true,
    mine: json['mine'] == true,
  );

  final String id, channelId, senderId, senderName, senderPhotoUrl, body;
  final String clientMessageId;
  final DateTime createdAt;
  final bool deleted, mine;

  /// Sent from this device and not yet confirmed.
  final bool pending;

  /// Sending failed; the member can retry.
  final bool failed;

  SocialMessage copyWith({bool? pending, bool? failed}) => SocialMessage(
    id: id,
    channelId: channelId,
    senderId: senderId,
    senderName: senderName,
    senderPhotoUrl: senderPhotoUrl,
    body: body,
    clientMessageId: clientMessageId,
    createdAt: createdAt,
    deleted: deleted,
    mine: mine,
    pending: pending ?? this.pending,
    failed: failed ?? this.failed,
  );
}

/// `GET /social/channels`: the member's conversations that have messages.
final socialChannelsProvider = FutureProvider.autoDispose<List<SocialChannel>>((
  ref,
) async {
  ref.watch(authNotifierProvider.select((s) => s.userId));
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/social/channels');
  return [
    for (final c in ((response.data as Map)['channels'] as List? ?? const []))
      SocialChannel.fromJson(c as Map),
  ];
});

/// Opens (or creates) the conversation with an accepted friend.
Future<SocialChannel> openFriendChannel(Dio api, String friendId) async {
  final response = await api.post<dynamic>('/social/friends/$friendId/channel');
  return SocialChannel.fromJson((response.data as Map)['channel'] as Map);
}

/// The server refused a post because the member is read-only (muted).
bool isSocialReadOnlyError(Object e) =>
    e is DioException &&
    e.response?.statusCode == 403 &&
    e.response?.data is Map &&
    (e.response!.data as Map)['error_code'] == 'CHANNEL_READ_ONLY';

class SocialChatState {
  const SocialChatState({
    this.channel,
    this.messages = const [],
    this.loading = true,
    this.loadingOlder = false,
    this.hasMore = false,
    this.error,
    this.live = false,
  });

  final SocialChannel? channel;

  /// Oldest first.
  final List<SocialMessage> messages;
  final bool loading, loadingOlder, hasMore;
  final Object? error;

  /// The real-time connection is up.
  final bool live;

  SocialChatState copyWith({
    SocialChannel? channel,
    List<SocialMessage>? messages,
    bool? loading,
    bool? loadingOlder,
    bool? hasMore,
    Object? error,
    bool clearError = false,
    bool? live,
  }) => SocialChatState(
    channel: channel ?? this.channel,
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
    live: live ?? this.live,
  );
}

/// Merges [incoming] into [current] by id (and client id for this device's
/// optimistic messages), oldest first.
List<SocialMessage> mergeSocialMessages(
  List<SocialMessage> current,
  List<SocialMessage> incoming,
) {
  final byId = <String, SocialMessage>{};
  final confirmedClientIds = {
    for (final m in incoming)
      if (m.clientMessageId.isNotEmpty) m.clientMessageId,
  };
  for (final m in current) {
    if ((m.pending || m.failed) &&
        confirmedClientIds.contains(m.clientMessageId)) {
      continue;
    }
    byId[m.id] = m;
  }
  for (final m in incoming) {
    byId[m.id] = m;
  }
  final out = byId.values.toList()
    ..sort((a, b) {
      final t = a.createdAt.compareTo(b.createdAt);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
  return out;
}

/// One open conversation: history, optimistic sends, deletes, and live
/// updates over the chat websocket (with a slow poll as a fallback).
class SocialChat extends AutoDisposeFamilyNotifier<SocialChatState, String> {
  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnect, _poll, _refreshSoon, _readOnlyEnds;
  int _cursor = 0;
  int _attempt = 0;
  bool _disposed = false;

  String get channelId => arg;
  Dio get _api => ref.read(apiClientProvider);

  @override
  SocialChatState build(String arg) {
    ref.watch(authNotifierProvider.select((s) => s.userId));
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _reconnect?.cancel();
      _poll?.cancel();
      _refreshSoon?.cancel();
      _readOnlyEnds?.cancel();
      unawaited(_subscription?.cancel());
      unawaited(_socket?.sink.close());
    });
    Future<void>.microtask(_start);
    return const SocialChatState();
  }

  Future<void> _start() async {
    await refresh();
    if (_disposed || state.error != null) return;
    unawaited(_connect());
    // A slow poll catches anything missed while the socket was down.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!state.live) unawaited(refresh(quiet: true));
    });
  }

  /// Reloads the channel and the newest page of messages.
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) state = state.copyWith(loading: true, clearError: true);
    try {
      final responses = await Future.wait([
        _api.get<dynamic>('/social/channels/$channelId'),
        _api.get<dynamic>('/social/channels/$channelId/messages'),
      ]);
      if (_disposed) return;
      final channel = SocialChannel.fromJson(
        (responses[0].data as Map)['channel'] as Map,
      );
      final page = responses[1].data as Map;
      final cursor = _int(page['realtime_cursor']);
      if (cursor > _cursor) _cursor = cursor;
      final incoming = [
        for (final m in (page['messages'] as List? ?? const []))
          SocialMessage.fromJson(m as Map),
      ];
      state = state.copyWith(
        channel: channel,
        messages: mergeSocialMessages(state.messages, incoming),
        hasMore: state.messages.isEmpty
            ? page['has_more'] == true
            : state.hasMore,
        loading: false,
        clearError: true,
      );
      _watchReadOnly(channel);
      unawaited(markRead());
    } on Object catch (e) {
      if (_disposed) return;
      state = state.copyWith(loading: false, error: quiet ? null : e);
    }
  }

  /// Re-reads the channel when a mute ends, so the composer opens again.
  void _watchReadOnly(SocialChannel channel) {
    _readOnlyEnds?.cancel();
    final until = channel.readOnlyUntil;
    if (!channel.readOnly || until == null) {
      return;
    }
    final wait = until.difference(DateTime.now()) + const Duration(seconds: 1);
    _readOnlyEnds = Timer(
      wait.isNegative ? Duration.zero : wait,
      () => unawaited(refresh(quiet: true)),
    );
  }

  /// Mutes this conversation's notifications for [duration], or turns them
  /// back on when it is null.
  Future<void> setMute(SocialMuteDuration? duration) async {
    final updated = await setSocialChannelMute(_api, channelId, duration);
    if (_disposed) {
      return;
    }
    final current = state.channel;
    state = state.copyWith(
      channel:
          current?.withMute(
            muted: updated.muted,
            mutedUntil: updated.mutedUntil,
          ) ??
          updated,
    );
  }

  Future<void> loadOlder() async {
    if (state.loadingOlder || !state.hasMore || state.messages.isEmpty) return;
    final oldest = state.messages.firstWhere(
      (m) => !m.pending && !m.failed,
      orElse: () => state.messages.first,
    );
    state = state.copyWith(loadingOlder: true);
    try {
      final response = await _api.get<dynamic>(
        '/social/channels/$channelId/messages',
        queryParameters: {'before': oldest.id},
      );
      final page = response.data as Map;
      state = state.copyWith(
        messages: mergeSocialMessages(state.messages, [
          for (final m in (page['messages'] as List? ?? const []))
            SocialMessage.fromJson(m as Map),
        ]),
        hasMore: page['has_more'] == true,
        loadingOlder: false,
      );
    } on Object {
      state = state.copyWith(loadingOlder: false);
      rethrow;
    }
  }

  /// Sends [body] at once (optimistic) and confirms with the server.
  Future<void> send(String body, {String? retryClientId}) async {
    final text = body.trim();
    if (text.isEmpty) return;
    final clientId = retryClientId ?? const Uuid().v4();
    final me = ref.read(authNotifierProvider).userId ?? '';
    final optimistic = SocialMessage(
      id: 'local-$clientId',
      channelId: channelId,
      senderId: me,
      body: text,
      clientMessageId: clientId,
      createdAt: DateTime.now(),
      mine: true,
      pending: true,
    );
    state = state.copyWith(
      messages: [
        for (final m in state.messages)
          if (m.clientMessageId != clientId) m,
        optimistic,
      ],
    );
    try {
      final response = await _api.post<dynamic>(
        '/social/channels/$channelId/messages',
        data: {'body': text, 'client_message_id': clientId},
      );
      final confirmed = SocialMessage.fromJson(
        (response.data as Map)['message'] as Map,
      );
      if (_disposed) return;
      state = state.copyWith(
        messages: mergeSocialMessages(state.messages, [confirmed]),
      );
    } on Object catch (e) {
      if (_disposed) return;
      if (isSocialReadOnlyError(e)) {
        // Muted meanwhile: drop the draft bubble and show the muted composer.
        state = state.copyWith(
          messages: [
            for (final m in state.messages)
              if (m.clientMessageId != clientId) m,
          ],
        );
        unawaited(refresh(quiet: true));
        rethrow;
      }
      state = state.copyWith(
        messages: [
          for (final m in state.messages)
            m.clientMessageId == clientId
                ? m.copyWith(pending: false, failed: true)
                : m,
        ],
      );
      rethrow;
    }
  }

  Future<void> retry(SocialMessage failed) =>
      send(failed.body, retryClientId: failed.clientMessageId);

  /// Deletes the member's own message, or removes one as a moderator.
  Future<void> delete(SocialMessage message) async {
    if (message.failed) {
      state = state.copyWith(
        messages: [
          for (final m in state.messages)
            if (m.clientMessageId != message.clientMessageId) m,
        ],
      );
      return;
    }
    await _api.delete<dynamic>(
      '/social/channels/$channelId/messages/${message.id}',
    );
    await refresh(quiet: true);
  }

  Future<void> markRead() async {
    try {
      await _api.post<dynamic>('/social/channels/$channelId/read');
    } on Object {
      // Read markers are best effort.
    }
  }

  Future<void> _connect() async {
    if (_disposed) return;
    final token = AuthSessionStore.instance.accessToken?.trim() ?? '';
    if (token.isEmpty) {
      _scheduleReconnect();
      return;
    }
    await _subscription?.cancel();
    await _socket?.sink.close();
    try {
      final socket = ChatRealtimeClient(
        apiBaseUrl: AppRuntimeConfig.apiBaseUrl,
      ).connect(accessToken: token, after: _cursor);
      _socket = socket;
      _subscription = socket.stream.listen(
        _onEvent,
        onError: (Object _) => _onDisconnected(),
        onDone: _onDisconnected,
        cancelOnError: true,
      );
      await socket.ready;
      if (_disposed) return;
      _attempt = 0;
      state = state.copyWith(live: true);
    } on Object {
      _onDisconnected();
    }
  }

  void _onEvent(Object? raw) {
    final event = ChatRealtimeEvent.tryParse(raw);
    if (event == null || _disposed) return;
    if (event.sequence > _cursor) _cursor = event.sequence;
    if (!event.type.startsWith('social.')) return;
    if (event.payload['channel_id'] != channelId) return;
    // Coalesce bursts into one refresh of the newest page.
    _refreshSoon?.cancel();
    _refreshSoon = Timer(
      const Duration(milliseconds: 120),
      () => unawaited(refresh(quiet: true)),
    );
  }

  void _onDisconnected() {
    if (_disposed) return;
    state = state.copyWith(live: false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnect?.isActive == true) return;
    final seconds = 1 << _attempt.clamp(0, 5);
    _attempt++;
    _reconnect = Timer(Duration(seconds: seconds), () => unawaited(_connect()));
  }
}

final socialChatProvider = NotifierProvider.autoDispose
    .family<SocialChat, SocialChatState, String>(SocialChat.new);
