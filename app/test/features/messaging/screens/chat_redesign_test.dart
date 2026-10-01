import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/matching/providers/match_provider.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/features/messaging/models/messaging_models.dart';
import 'package:verified_dating_app/features/messaging/models/rose_gift.dart';
import 'package:verified_dating_app/features/messaging/providers/message_provider.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Messages extends MessageNotifier {
  _Messages({this.failSend = false, this.response});
  final bool failSend;
  final Completer<bool>? response;
  @override
  MessageState build(String matchId) => MessageState(
    messages: [
      Message(
        id: '2',
        matchId: matchId,
        senderId: 'me',
        text: 'A walk and coffee sounds like my kind of Sunday.',
        createdAt: DateTime.now(),
        readAt: DateTime.now(),
      ),
      Message(
        id: '1',
        matchId: matchId,
        senderId: 'them',
        text: 'What does your ideal weekend look like?',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
    giftCatalog: const [
      RoseGift(
        id: 'rose_red_single',
        name: 'Classic rose',
        gifUrl: '',
        priceCoins: 0,
        tier: 'free',
        isLimited: false,
        maxPerMatchPerDay: 0,
      ),
    ],
  );
  @override
  Future<void> refreshRoseEconomy() async {}
  @override
  void setTyping({required bool isTyping}) {
    state = state.copyWith(isTyping: isTyping);
  }

  @override
  void trackGiftPanelOpened() {}
  @override
  Future<bool> sendMessage(String text, {String? assistDraftId}) async {
    if (response != null) return response!.future;
    state = state.copyWith(error: failSend ? 'Please try again.' : null);
    return !failSend;
  }
}

class _Matches extends MatchNotifier {
  @override
  MatchState build() => MatchState(
    matches: [
      for (final name in ['Maya', 'Arjun'])
        Match(
          id: name,
          userId: name,
          userName: name,
          userPhoto: '',
          lastMessage: 'Hello there',
          lastMessageTime: DateTime.now(),
          unreadCount: name == 'Maya' ? 2 : 0,
          isOnline: false,
        ),
    ],
  );
}

Widget _app({
  required Widget child,
  ThemePreset preset = ThemePresets.daylight,
  bool failSend = false,
  double scale = 1,
  double keyboard = 0,
  Completer<bool>? response,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          data: <String, dynamic>{},
          statusCode: 200,
        ),
      ),
    ),
  );
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(_Auth.new),
      messageNotifierProvider(
        'layout-test',
      ).overrideWith(() => _Messages(failSend: failSend, response: response)),
      matchNotifierProvider.overrideWith(_Matches.new),
      // These tests exercise the people/chat views; the route's default
      // discovery view has dedicated free/premium acceptance tests.
      matchesViewProvider.overrideWith((ref) => MatchesView.people),
      apiClientProvider.overrideWithValue(dio),
      runtimeFeatureFlagsProvider.overrideWith(
        (_) => Stream.value(
          const RuntimeFeatureFlags({
            'gifts_enabled': true,
            'billing_enabled': true,
            'copilot_enabled': true,
            'date_plans_enabled': false,
            'graduation_enabled': false,
          }),
        ),
      ),
    ],
    child: MaterialApp(
      theme: ThemePresets.themeFor(preset),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: child!,
      ),
      home: child,
    ),
  );
}

const _chat = ChatScreen(
  matchId: 'layout-test',
  otherUserId: 'them',
  userName: 'Maya Alexandra',
  userPhotoUrl: '',
);

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    for (final preset in [ThemePresets.daylight, ThemePresets.ember]) {
      testWidgets('chat fits ${size.width} in ${preset.id}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app(child: _chat, preset: preset));
        await tester.pumpAndSettle();
        expect(find.text('Active now'), findsNothing);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Yesterday'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('qa.chat.desktop_sidebar')),
          size.width >= 1050 ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.byKey(const ValueKey('qa.chat.gift_tray_button')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('large text and keyboard leave the composer usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(child: _chat, scale: 2, keyboard: 280));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('qa.chat.composer')),
      'Hello!',
    );
    await tester.pump();
    expect(
      tester
          .getBottomLeft(find.byKey(const ValueKey('qa.chat.send_button')))
          .dy,
      lessThan(564),
    );
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    testWidgets(
      'draft ${fail ? 'survives a failed send' : 'clears after success'}',
      (tester) async {
        await tester.pumpWidget(_app(child: _chat, failSend: fail));
        await tester.pumpAndSettle();
        final field = find.byKey(const ValueKey('qa.chat.composer'));
        await tester.enterText(field, 'Keep this thought');
        await tester.pump();
        expect(find.textContaining('is typing'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('qa.chat.send_button')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.text,
          fail ? 'Keep this thought' : '',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a newer draft survives completion of an earlier send', (
    tester,
  ) async {
    final response = Completer<bool>();
    await tester.pumpWidget(_app(child: _chat, response: response));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('qa.chat.composer'));
    await tester.enterText(field, 'First thought');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('qa.chat.send_button')));
    await tester.pump();
    await tester.enterText(field, 'And another thing');
    response.complete(true);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field).controller!.text,
      'And another thing',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('focusing the composer closes the gift panel', (tester) async {
    await tester.pumpWidget(_app(child: _chat));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.chat.gift_tray_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.chat.composer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('qa.chat.gift_tray')), findsNothing);
  });

  testWidgets('conversation search and unread filter narrow real rows', (
    tester,
  ) async {
    await tester.pumpWidget(_app(child: const MatchesListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Arjun'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('qa.matches.conversations_tab')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unread · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Arjun'), findsNothing);
    await tester.tap(find.text('All conversations'));
    await tester.enterText(
      find.byKey(const ValueKey('qa.chat.search_conversations')),
      'arjun',
    );
    await tester.pumpAndSettle();
    expect(find.text('Maya'), findsNothing);
    expect(find.text('Arjun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('people cards and conversations remain separate choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(child: const MatchesListScreen(), scale: 1.4));
    await tester.pumpAndSettle();
    expect(find.text('Matches'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('qa.matches.person.Maya')),
      findsOneWidget,
    );
    expect(find.text('Hello there'), findsNothing);
    expect(find.text('Search your matches'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('qa.matches.conversations_tab')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('qa.matches.match_row.Maya')),
      findsOneWidget,
    );
    expect(find.text('Search conversations'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.matches.people_tab')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('qa.matches.person.Maya')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
