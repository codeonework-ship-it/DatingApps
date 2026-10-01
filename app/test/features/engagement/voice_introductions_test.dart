import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/matching/providers/match_provider.dart';
import 'package:verified_dating_app/features/engagement/screens/voice_icebreakers_screen.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Matches extends MatchNotifier {
  @override
  MatchState build() => MatchState(
    matches: [
      Match(
        id: 'match-one',
        userId: 'them',
        userName: 'Maya',
        userPhoto: '',
        lastMessage: '',
        lastMessageTime: DateTime(2026),
        unreadCount: 0,
        isOnline: false,
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (c) async => null,
        );
  });
  for (final direct in [true, false]) {
    testWidgets(
      direct
          ? 'conversation voice shows transcript without autoplay'
          : 'voice uses a named conversation picker',
      (t) async {
        final paths = <String>[];
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (r, h) {
                paths.add(r.path);
                h.resolve(
                  Response<dynamic>(
                    requestOptions: r,
                    statusCode: 200,
                    data: r.path.endsWith('/prompts')
                        ? {
                            'prompts': [
                              {'id': 'p', 'prompt_text': 'A Sunday you love'},
                            ],
                          }
                        : {
                            'introductions': [
                              {
                                'id': 'v',
                                'match_id': 'match-one',
                                'sender_user_id': 'them',
                                'receiver_user_id': 'me',
                                'prompt_text': 'A Sunday you love',
                                'transcript':
                                    'I like a book and a quiet coffee.',
                                'duration_seconds': 24,
                                'status': 'sent',
                                'moderation_status': 'approved',
                                'play_count': 0,
                              },
                            ],
                          },
                  ),
                );
              },
            ),
          );
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(_Auth.new),
              apiClientProvider.overrideWithValue(dio),
              matchNotifierProvider.overrideWith(_Matches.new),
            ],
            child: MaterialApp(
              home: direct
                  ? const VoiceIcebreakersScreen(
                      matchId: 'match-one',
                      receiverUserId: 'them',
                      partnerName: 'Maya',
                    )
                  : const VoiceIcebreakersScreen(),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('Match ID'), findsNothing);
        expect(find.text('Receiver User ID'), findsNothing);
        if (!direct) {
          await t.tap(find.byKey(const ValueKey('qa.voice.conversation')));
          await t.pumpAndSettle();
          await t.tap(find.text('Maya').last);
          await t.pumpAndSettle();
        }
        await t.scrollUntilVisible(
          find.text('I like a book and a quiet coffee.'),
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pumpAndSettle();
        expect(find.text('I like a book and a quiet coffee.'), findsOneWidget);
        expect(
          paths.where((p) => p.endsWith('/play') || p.endsWith('/start')),
          isEmpty,
        );
        expect(paths, contains('/matches/match-one/voice-introductions'));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      },
    );
  }
}
