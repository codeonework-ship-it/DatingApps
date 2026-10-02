import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/friend_social.dart';

/// Why a vouch or intro request failed when the server sent no message of
/// its own. Widgets show it in the member's language with
/// [FriendSocialState.errorText].
enum FriendSocialFailure {
  load,
  sendVouch,
  updateVouch,
  withdrawVouch,
  makeIntro,
  answerIntro,
}

class FriendSocialState {
  const FriendSocialState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.failure,
    this.vouchesAboutMe = const <FriendVouch>[],
    this.vouchesWritten = const <FriendVouch>[],
    this.introsReceived = const <FriendIntro>[],
    this.introsMade = const <FriendIntro>[],
  });

  final bool isLoading;
  final bool isMutating;

  /// The server's own message for the last failure, if it sent one.
  final String? error;

  /// The last failure when the server sent no message.
  final FriendSocialFailure? failure;
  final List<FriendVouch> vouchesAboutMe;
  final List<FriendVouch> vouchesWritten;
  final List<FriendIntro> introsReceived;
  final List<FriendIntro> introsMade;

  List<FriendIntro> get introsAwaitingMe =>
      introsReceived.where((intro) => intro.awaitingMe).toList();
  List<FriendVouch> get pendingVouches =>
      vouchesAboutMe.where((vouch) => vouch.isPending).toList();

  bool get hasError => error != null || failure != null;

  /// The last failure for display: the server's message, or a localized
  /// fallback.
  String? errorText(AppLocalizations l10n) =>
      error ??
      switch (failure) {
        FriendSocialFailure.load => l10n.friendsSocialLoadFailed,
        FriendSocialFailure.sendVouch => l10n.friendsVouchSendFailed,
        FriendSocialFailure.updateVouch => l10n.friendsVouchUpdateFailed,
        FriendSocialFailure.withdrawVouch => l10n.friendsVouchWithdrawFailed,
        FriendSocialFailure.makeIntro => l10n.friendsIntroMakeFailed,
        FriendSocialFailure.answerIntro => l10n.friendsIntroAnswerFailed,
        null => null,
      };

  FriendSocialState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    FriendSocialFailure? failure,
    bool clearError = false,
    List<FriendVouch>? vouchesAboutMe,
    List<FriendVouch>? vouchesWritten,
    List<FriendIntro>? introsReceived,
    List<FriendIntro>? introsMade,
  }) {
    // A new failure replaces the previous one, message and fallback alike.
    final keep = !clearError && error == null && failure == null;
    return FriendSocialState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: keep ? this.error : error,
      failure: keep ? this.failure : failure,
      vouchesAboutMe: vouchesAboutMe ?? this.vouchesAboutMe,
      vouchesWritten: vouchesWritten ?? this.vouchesWritten,
      introsReceived: introsReceived ?? this.introsReceived,
      introsMade: introsMade ?? this.introsMade,
    );
  }
}

class FriendSocialNotifier extends StateNotifier<FriendSocialState> {
  FriendSocialNotifier(this.ref) : super(const FriendSocialState()) {
    Future<void>.microtask(load);
  }

  final Ref ref;

  String? get _userId => ref.read(authNotifierProvider).userId;

  Future<void> load() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    if (kUseMockAuth) {
      state = state.copyWith(
        introsReceived: _mockIntros(),
        vouchesAboutMe: _mockVouches(),
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        dio.get<dynamic>('/friends/$userId/vouches'),
        dio.get<dynamic>('/friends/$userId/intros'),
      ]);
      final vouches =
          ((results[0] as dynamic).data as Map?)?.cast<String, dynamic>() ?? {};
      final intros =
          ((results[1] as dynamic).data as Map?)?.cast<String, dynamic>() ?? {};
      state = state.copyWith(
        isLoading: false,
        vouchesAboutMe: _vouchList(vouches['about_me']),
        vouchesWritten: _vouchList(vouches['written']),
        introsReceived: _introList(intros['received']),
        introsMade: _introList(intros['made']),
      );
    } on Object catch (error) {
      log.error('Friend social load failed', error);
      state = state.copyWith(
        isLoading: false,
        error: _serverMessage(error),
        failure: FriendSocialFailure.load,
      );
    }
  }

  Future<bool> writeVouch({required String forUserId, required String text}) =>
      _mutate(
        method: 'POST',
        path: '/friends/$_userId/vouches',
        data: <String, dynamic>{'for_user_id': forUserId, 'text': text.trim()},
        failure: FriendSocialFailure.sendVouch,
      );

  Future<bool> decideVouch({required String vouchId, required bool approve}) =>
      _mutate(
        method: 'POST',
        path: '/friends/$_userId/vouches/$vouchId/decision',
        data: <String, dynamic>{'decision': approve ? 'approve' : 'hide'},
        failure: FriendSocialFailure.updateVouch,
      );

  Future<bool> withdrawVouch(String vouchId) => _mutate(
    method: 'DELETE',
    path: '/friends/$_userId/vouches/$vouchId',
    data: const <String, dynamic>{},
    failure: FriendSocialFailure.withdrawVouch,
  );

  Future<bool> makeIntro({
    required String firstUserId,
    required String secondUserId,
    String message = '',
  }) => _mutate(
    method: 'POST',
    path: '/friends/$_userId/intros',
    data: <String, dynamic>{
      'first_user_id': firstUserId,
      'second_user_id': secondUserId,
      if (message.trim().isNotEmpty) 'message': message.trim(),
    },
    failure: FriendSocialFailure.makeIntro,
  );

  Future<bool> decideIntro({required String introId, required bool accept}) =>
      _mutate(
        method: 'POST',
        path: '/friends/$_userId/intros/$introId/decision',
        data: <String, dynamic>{'decision': accept ? 'accept' : 'decline'},
        failure: FriendSocialFailure.answerIntro,
      );

  Future<bool> _mutate({
    required String method,
    required String path,
    required Map<String, dynamic> data,
    required FriendSocialFailure failure,
  }) async {
    if (kUseMockAuth) {
      return true;
    }
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final dio = ref.read(apiClientProvider);
      if (method == 'DELETE') {
        await dio.delete<dynamic>(path);
      } else {
        await dio.post<dynamic>(path, data: data);
      }
      state = state.copyWith(isMutating: false);
      await load();
      return true;
    } on Object catch (error) {
      log.error('Friend social mutation failed', error);
      state = state.copyWith(
        isMutating: false,
        error: _serverMessage(error),
        failure: failure,
      );
      return false;
    }
  }
}

final friendSocialProvider =
    StateNotifierProvider<FriendSocialNotifier, FriendSocialState>((ref) {
      // Per member: signing in as someone else on this device must never
      // show the previous member's intros and vouches.
      ref.watch(authNotifierProvider.select((s) => s.userId));
      return FriendSocialNotifier(ref);
    });

/// Approved vouches on another member's profile.
final publicVouchesProvider = FutureProvider.family<List<PublicVouch>, String>((
  ref,
  userId,
) async {
  // Per viewer: rebuilt when someone else signs in on this device.
  watchSignedInUserId(ref);
  if (kUseMockAuth) {
    return const <PublicVouch>[
      PublicVouch(
        text: 'Warm, curious and always the first to show up.',
        voucherName: 'Meera',
      ),
    ];
  }
  try {
    final response = await ref
        .read(apiClientProvider)
        .get<dynamic>('/users/$userId/vouches');
    final body = (response.data as Map?)?.cast<String, dynamic>() ?? {};
    return (body['vouches'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((row) => PublicVouch.fromJson(row.cast<String, dynamic>()))
        .toList();
  } on Object catch (error) {
    log.error('Public vouches load failed', error);
    return const <PublicVouch>[];
  }
});

List<FriendVouch> _vouchList(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((row) => FriendVouch.fromJson(row.cast<String, dynamic>()))
        .toList();

List<FriendIntro> _introList(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((row) => FriendIntro.fromJson(row.cast<String, dynamic>()))
        .toList();

List<FriendIntro> _mockIntros() => const <FriendIntro>[
  FriendIntro(
    id: 'intro-1',
    introducerUserId: 'qa-friend',
    introducerName: 'Meera',
    message: 'You two would get on.',
    status: 'open',
    myDecision: 'pending',
    other: IntroPreview(userId: 'qa-other', name: 'Dev', age: 31, city: 'Pune'),
    expiresAt: '2026-10-11T00:00:00Z',
    createdAt: '2026-09-27T00:00:00Z',
  ),
];

List<FriendVouch> _mockVouches() => const <FriendVouch>[
  FriendVouch(
    id: 'vouch-1',
    subjectUserId: 'qa-user',
    subjectName: 'You',
    voucherUserId: 'qa-friend',
    voucherName: 'Meera',
    text: 'Warm, curious and always the first to show up.',
    status: 'pending',
    createdAt: '2026-09-27T00:00:00Z',
  ),
];

/// The server's (or network layer's) own message for [error], or null when
/// there is none and the localized fallback should show.
String? _serverMessage(Object error) {
  final message = apiErrorMessage(error, fallback: '');
  return message.isEmpty ? null : message;
}
