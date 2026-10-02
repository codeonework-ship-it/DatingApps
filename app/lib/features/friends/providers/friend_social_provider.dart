import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/friend_social.dart';

class FriendSocialState {
  const FriendSocialState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.vouchesAboutMe = const <FriendVouch>[],
    this.vouchesWritten = const <FriendVouch>[],
    this.introsReceived = const <FriendIntro>[],
    this.introsMade = const <FriendIntro>[],
  });

  final bool isLoading;
  final bool isMutating;
  final String? error;
  final List<FriendVouch> vouchesAboutMe;
  final List<FriendVouch> vouchesWritten;
  final List<FriendIntro> introsReceived;
  final List<FriendIntro> introsMade;

  List<FriendIntro> get introsAwaitingMe =>
      introsReceived.where((intro) => intro.awaitingMe).toList();
  List<FriendVouch> get pendingVouches =>
      vouchesAboutMe.where((vouch) => vouch.isPending).toList();

  FriendSocialState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
    List<FriendVouch>? vouchesAboutMe,
    List<FriendVouch>? vouchesWritten,
    List<FriendIntro>? introsReceived,
    List<FriendIntro>? introsMade,
  }) => FriendSocialState(
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    error: clearError ? null : (error ?? this.error),
    vouchesAboutMe: vouchesAboutMe ?? this.vouchesAboutMe,
    vouchesWritten: vouchesWritten ?? this.vouchesWritten,
    introsReceived: introsReceived ?? this.introsReceived,
    introsMade: introsMade ?? this.introsMade,
  );
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
        error: apiErrorMessage(
          error,
          fallback: 'Unable to load vouches and intros.',
        ),
      );
    }
  }

  Future<bool> writeVouch({required String forUserId, required String text}) =>
      _mutate(
        method: 'POST',
        path: '/friends/$_userId/vouches',
        data: <String, dynamic>{'for_user_id': forUserId, 'text': text.trim()},
        fallback: 'Unable to send this vouch.',
      );

  Future<bool> decideVouch({required String vouchId, required bool approve}) =>
      _mutate(
        method: 'POST',
        path: '/friends/$_userId/vouches/$vouchId/decision',
        data: <String, dynamic>{'decision': approve ? 'approve' : 'hide'},
        fallback: 'Unable to update this vouch.',
      );

  Future<bool> withdrawVouch(String vouchId) => _mutate(
    method: 'DELETE',
    path: '/friends/$_userId/vouches/$vouchId',
    data: const <String, dynamic>{},
    fallback: 'Unable to withdraw this vouch.',
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
    fallback: 'Unable to make this intro.',
  );

  Future<bool> decideIntro({required String introId, required bool accept}) =>
      _mutate(
        method: 'POST',
        path: '/friends/$_userId/intros/$introId/decision',
        data: <String, dynamic>{'decision': accept ? 'accept' : 'decline'},
        fallback: 'Unable to answer this intro.',
      );

  Future<bool> _mutate({
    required String method,
    required String path,
    required Map<String, dynamic> data,
    required String fallback,
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
        error: apiErrorMessage(error, fallback: fallback),
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
