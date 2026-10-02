import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/matching/matching_l10n.dart';
import 'package:verified_dating_app/features/matching/providers/activity_session_provider.dart';
import 'package:verified_dating_app/features/matching/providers/match_provider.dart';
import 'package:verified_dating_app/features/matching/providers/trust_filter_provider.dart';
import 'package:verified_dating_app/features/matching/screens/activity_session_screen.dart';
import 'package:verified_dating_app/features/matching/screens/match_notification_screen.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Matches extends MatchNotifier {
  _Matches(this.initial);
  final MatchState initial;
  @override
  MatchState build() => initial;
}

Match _match(String id, String name, {int unread = 0, String? message}) =>
    Match(
      id: id,
      userId: 'user-$id',
      userName: name,
      userPhoto: '',
      lastMessage: message ?? kMatchEmptyLastMessage,
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: unread,
      isOnline: false,
    );

Dio _dio() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) => h.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: o,
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      ),
    ),
  );
  return dio;
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  MatchState matches = const MatchState(),
  MatchesView view = MatchesView.people,
  Locale locale = const Locale('de'),
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        apiClientProvider.overrideWithValue(_dio()),
        matchNotifierProvider.overrideWith(() => _Matches(matches)),
        matchesViewProvider.overrideWith((ref) => view),
        runtimeFeatureFlagsProvider.overrideWith(
          (ref) => Stream.value(
            const RuntimeFeatureFlags({
              'calls_enabled': false,
              'intentional_dating_enabled': true,
              'date_plans_enabled': true,
            }),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('matches people view speaks German', (tester) async {
    await _pump(
      tester,
      const MatchesListScreen(),
      matches: MatchState(
        matches: [
          _match('a', 'Anya', unread: 2),
          _match('b', kMatchUnknownName),
        ],
      ),
    );
    expect(find.text('Matches'), findsOneWidget); // navMatches: same in de
    expect(find.text('2 Matches'), findsOneWidget);
    expect(find.text('Deine Matches'), findsOneWidget);
    expect(find.text('Unterhaltungen'), findsOneWidget);
    expect(find.text('Entdecken'), findsOneWidget);
    expect(
      find.text(
        'Menschen, die du gewählt hast. Möglichkeiten, die ihr gemeinsam gestaltet.',
      ),
      findsOneWidget,
    );
    expect(find.text('Deine Matches durchsuchen'), findsOneWidget);
    expect(
      find.text('Ihr habt euch beide füreinander entschieden'),
      findsNWidgets(2),
    );
    expect(find.text('Chat · 2 ungelesen'), findsOneWidget);
    expect(find.text('Chat öffnen'), findsOneWidget);
    expect(find.text('Date planen'), findsNWidgets(2));
    expect(find.text('Unbekannt'), findsOneWidget);
    expect(find.text('Unknown'), findsNothing);
    expect(find.byTooltip('Match-Optionen für Anya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conversation rows and options sheet speak German', (
    tester,
  ) async {
    await _pump(
      tester,
      const MatchesListScreen(),
      view: MatchesView.conversations,
      matches: MatchState(matches: [_match('a', 'Anya', unread: 1)]),
    );
    expect(find.text('Alle Unterhaltungen'), findsOneWidget);
    expect(find.text('Ungelesen · 1'), findsOneWidget);
    expect(find.text('Sag Hallo 👋'), findsOneWidget);
    expect(find.text('vor 5 Min.'), findsOneWidget);
    await tester.tap(find.byTooltip('Optionen für die Unterhaltung mit Anya'));
    await tester.pumpAndSettle();
    expect(find.text('Unterhaltung beenden'), findsOneWidget);
    expect(find.text('Melden'), findsOneWidget);
    await tester.tap(find.text('Unterhaltung beenden'));
    await tester.pumpAndSettle();
    expect(find.text('Diese Unterhaltung beenden?'), findsOneWidget);
    expect(find.text('Weiter schreiben'), findsOneWidget);
    await tester.tap(find.text('Weiter schreiben'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and error states translate known fallbacks only', (
    tester,
  ) async {
    await _pump(
      tester,
      const MatchesListScreen(),
      matches: const MatchState(error: kMatchesLoadError),
    );
    expect(find.text('Matches konnten nicht geladen werden'), findsOneWidget);
    expect(
      find.text(
        'Matches konnten nicht geladen werden. Bitte versuch es erneut.',
      ),
      findsOneWidget,
    );
    expect(find.text('Erneut versuchen'), findsOneWidget);

    final l10n = await AppLocalizations.delegate.load(const Locale('de'));
    expect(localizeMatchesError(l10n, 'Server says no'), 'Server says no');
    expect(
      localizeActivityError(l10n, kActivityAnswerAllError),
      'Bitte beantworte alle Fragen, bevor du absendest.',
    );
    expect(
      localizedTrustBadgeLabel(
        l10n,
        const TrustBadgeOption(code: 'verified_active', label: 'x'),
      ),
      'Verifiziert & aktiv',
    );
    expect(
      localizeTrustFilterError(l10n, kTrustFilterSaveError),
      'Vertrauensfilter konnten nicht gespeichert werden. Bitte versuch es erneut.',
    );
  });

  testWidgets('trust-filtered empty state uses German plurals', (tester) async {
    await _pump(
      tester,
      const MatchesListScreen(),
      matches: const MatchState(
        trustFilterActive: true,
        trustFilteredOutCount: 3,
      ),
    );
    expect(find.text('Noch keine Matches'), findsOneWidget);
    expect(
      find.text(
        'Vertrauensfilter haben 3 Matches ausgeblendet. Lockere die Vertrauensfilter unter Entdecken.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('new match screen speaks German', (tester) async {
    // The avatars are network images; test HTTP always answers 400.
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is! NetworkImageLoadException) {
        onError?.call(details);
      }
    };
    await _pump(
      tester,
      const MatchNotificationScreen(
        matchId: 'm',
        otherUserId: 'u',
        otherUserName: 'Mira',
        otherUserPhotoUrl: '',
      ),
    );
    expect(find.text('Neues Match'), findsOneWidget);
    expect(find.text('Es ist ein Match!'), findsOneWidget);
    expect(
      find.text('Du und Mira habt euch gegenseitig geliked'),
      findsOneWidget,
    );
    expect(find.text('Nachricht senden'), findsOneWidget);
    expect(find.text('Weiter swipen'), findsOneWidget);
    FlutterError.onError = onError;
  });

  testWidgets('activity labels are German but answers stay English', (
    tester,
  ) async {
    await _pump(
      tester,
      const ActivitySessionScreen(
        matchId: 'm',
        otherUserId: 'u',
        otherUserName: 'Mira',
      ),
    );
    expect(find.text('2-Minuten-Entweder-oder'), findsOneWidget);
    expect(
      find.text('Beantworte alle 8 Runden, bevor die Zeit abläuft.'),
      findsOneWidget,
    );
    expect(find.text('Status: aktiv'), findsOneWidget);
    expect(find.text('Runde 1'), findsOneWidget);
    expect(find.text('Ideales erstes Treffen?'), findsOneWidget);
    expect(find.text('Spaziergang mit Kaffee'), findsOneWidget);
    expect(find.text('Coffee walk'), findsNothing);
    // The wire values sent to the server are unchanged.
    expect(buildDefaultActivityQuestions().first.options, [
      'Coffee walk',
      'Bookstore browse',
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('English text is unchanged', (tester) async {
    await _pump(
      tester,
      const MatchesListScreen(),
      locale: const Locale('en'),
      matches: MatchState(matches: [_match('a', 'Anya', unread: 2)]),
    );
    expect(find.text('1 match'), findsOneWidget);
    expect(find.text('Your matches'), findsOneWidget);
    expect(find.text('You both chose to connect'), findsOneWidget);
    expect(find.text('Chat · 2 unread'), findsOneWidget);
    expect(find.text('Search your matches'), findsOneWidget);
  });
}
