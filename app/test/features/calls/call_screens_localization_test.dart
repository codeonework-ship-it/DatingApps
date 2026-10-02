import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/calls/providers/call_provider.dart';
import 'package:verified_dating_app/features/calls/screens/call_history_screen.dart';
import 'package:verified_dating_app/features/calls/screens/call_session_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _FakeCallNotifier extends CallNotifier {
  _FakeCallNotifier(super.ref, this.seed);

  final CallState seed;

  @override
  Future<void> loadHistory() async => state = seed;

  @override
  Future<CallSession?> startCall({
    required String matchId,
    required String recipientUserId,
  }) async {
    state = seed;
    return null;
  }
}

Widget _app(Locale locale, CallState seed, Widget home) => ProviderScope(
  overrides: [callProvider.overrideWith((ref) => _FakeCallNotifier(ref, seed))],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

final _ended = CallSession(
  id: 'call-1',
  matchId: 'match-12345678',
  initiatorId: 'a',
  recipientId: 'b',
  status: 'ended',
  roomId: 'room',
  startedAt: DateTime(2026, 3, 4, 18, 5),
  durationSeconds: 245,
);

void main() {
  testWidgets('call history speaks German', (tester) async {
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        CallState(history: [_ended]),
        const CallHistoryScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Anrufverlauf'), findsOneWidget);
    expect(find.text('Beendet · 4:05'), findsOneWidget);
    expect(find.text('Match match-12'), findsOneWidget);
    expect(find.text('4.3.2026 · 18:05'), findsOneWidget);
  });

  testWidgets('call history shows English and a localized fallback error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Locale('en'),
        const CallState(
          error: 'Unable to load call history.',
          errorKind: CallErrorKind.loadHistory,
        ),
        const CallHistoryScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Call history'), findsOneWidget);
    expect(find.text('Unable to load call history.'), findsOneWidget);
    expect(find.text('No call sessions yet.'), findsOneWidget);
  });

  testWidgets('the call screen speaks German, server errors stay as sent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        const CallState(error: 'Room quota exceeded'),
        const CallSessionScreen(
          matchId: 'match-1',
          recipientUserId: 'user-2',
          recipientName: 'Maya',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Anruf'), findsOneWidget);
    expect(find.text('Anruf nicht verfügbar'), findsOneWidget);
    expect(find.text('Room quota exceeded'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}
