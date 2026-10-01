import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/messaging/providers/copilot_provider.dart';
import 'package:verified_dating_app/features/messaging/widgets/copilot_sheet.dart';
import 'package:verified_dating_app/features/messaging/widgets/message_bubble.dart';

Dio _fakeApi(List<Map<String, dynamic>> requests) {
  final dio = Dio(BaseOptions(baseUrl: 'http://bff.test/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add((options.data as Map).cast<String, dynamic>());
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'draft': {
                'draft_id': 'draft-1',
                'kind': (options.data as Map)['kind'],
                'tone': (options.data as Map)['tone'],
                'text': 'Hi Arjun, I noticed bouldering on your profile.',
                'provider': 'template',
                'disclosure': 'Say it in your own words.',
                'drafts_remaining_today': 9,
              },
            },
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  testWidgets('drafts in the chosen kind and tone and hands back the draft', (
    tester,
  ) async {
    final requests = <Map<String, dynamic>>[];
    CopilotDraft? chosen;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_fakeApi(requests))],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    chosen = await showCopilotSheet(
                      context: context,
                      matchId: 'match-1',
                      partnerName: 'Arjun',
                      conversationStarted: false,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Help me say it'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.copilot.tone.playful')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.copilot.generate')));
    await tester.pumpAndSettle();

    expect(requests.single['kind'], 'opener');
    expect(requests.single['tone'], 'playful');
    expect(find.byKey(const ValueKey('qa.copilot.draft')), findsOneWidget);
    expect(find.textContaining('9 drafts left today'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('qa.copilot.use')));
    await tester.pumpAndSettle();
    expect(chosen?.id, 'draft-1');
    expect(chosen?.text, contains('bouldering'));
  });

  testWidgets('an assisted message shows the honest caption', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: 'Hi there',
            isFromCurrentUser: false,
            timestamp: DateTime.now(),
            isDelivered: true,
            isRead: true,
            assisted: true,
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('qa.chat.assisted_label')),
      findsOneWidget,
    );
    expect(find.text('Drafted with help'), findsOneWidget);
  });

  test('models parse the BFF payloads', () {
    final trust = ConversationTrust.fromJson({
      'human_verified': true,
      'partner_verified': true,
      'viewer_verified': true,
      'partner_badges': ['shows_up'],
      'assisted_messages': 2,
    });
    expect(trust.partnerShowsUp, isTrue);
    final draft = CopilotDraft.fromJson({
      'draft_id': 'd',
      'kind': 'reply',
      'text': 't',
      'drafts_remaining_today': 3,
    });
    expect(draft.remainingToday, 3);
  });
}
