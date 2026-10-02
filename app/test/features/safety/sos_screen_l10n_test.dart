import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/safety/providers/sos_provider.dart';
import 'package:verified_dating_app/features/safety/screens/sos_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _SignedOutAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

/// Holds one past alert and never touches the network.
class _HistorySos extends SosNotifier {
  _HistorySos(super.ref) {
    state = SosState(
      alerts: [
        SosAlert(
          id: 'a1',
          userId: 'me',
          emergencyLevel: 'high',
          status: 'open',
          triggeredAt: DateTime(2026, 10, 2, 21, 15),
          resolutionNote: 'Member confirmed safe',
        ),
      ],
    );
  }

  @override
  Future<void> loadAlerts() async {}
}

Widget _app(Locale locale, {bool withHistory = false}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_SignedOutAuth.new),
    if (withHistory) sosProvider.overrideWith(_HistorySos.new),
  ],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const SosScreen(),
  ),
);

void main() {
  testWidgets('SOS screen speaks German', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const Locale('de')));
    await tester.pump();

    expect(find.text('Notfall-SOS'), findsOneWidget);
    expect(find.text('Notfallalarm auslösen'), findsOneWidget);
    expect(find.text('Dringend'), findsOneWidget);
    expect(find.text('SOS auslösen'), findsOneWidget);
    expect(find.text('Alarmverlauf'), findsOneWidget);
    // The prefilled message follows the language too.
    expect(
      find.text('Ich brauche sofort Hilfe. Bitte meldet euch bei mir.'),
      findsOneWidget,
    );
    // The provider's signed-out message is shown in German.
    expect(
      find.text('Bitte melde dich an, um deinen SOS-Verlauf zu sehen.'),
      findsOneWidget,
    );
  });

  testWidgets('English alert history keeps its wording', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const Locale('en'), withHistory: true));
    await tester.pump();

    expect(find.text('HIGH · open'), findsOneWidget);
    expect(find.text('02/10/2026 21:15 · no location'), findsOneWidget);
    expect(find.text('Resolution: Member confirmed safe'), findsOneWidget);
    expect(
      find.text('I need immediate assistance. Please check on me.'),
      findsOneWidget,
    );
  });

  testWidgets('German alert history translates level and status', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const Locale('de'), withHistory: true));
    await tester.pump();

    expect(find.text('HOCH · offen'), findsOneWidget);
    expect(find.text('2.10.2026 21:15 · ohne Standort'), findsOneWidget);
    expect(find.text('Lösung: Member confirmed safe'), findsOneWidget);
  });
}
