import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/common/providers/account_lifecycle_provider.dart';
import 'package:verified_dating_app/features/common/screens/account_data_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// Serves a fixed lifecycle state so the screen can be driven without a
/// backend. The notifier's network methods are never reached in these tests.
class _StubLifecycleNotifier extends AccountLifecycleNotifier {
  _StubLifecycleNotifier(this._state);
  final AccountLifecycle _state;

  @override
  Future<AccountLifecycle> build() async => _state;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  AccountLifecycle lifecycle, {
  ThemeMode themeMode = ThemeMode.light,
  Locale? locale,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountLifecycleProvider.overrideWith(
          () => _StubLifecycleNotifier(lifecycle),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AccountDataScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _normal = AccountLifecycle(isActive: true, deactivated: false);
const _paused = AccountLifecycle(isActive: true, deactivated: true);

void main() {
  group('AccountDataScreen', () {
    testWidgets('offers all three journeys on a normal account', (
      tester,
    ) async {
      await _pumpScreen(tester, _normal);

      expect(find.text('Take a break'), findsOneWidget);
      expect(find.text('Download your data'), findsOneWidget);
      expect(find.text('Delete my account'), findsWidgets);
    });

    testWidgets(
      'a paused account is told it is hidden and offered a way back',
      (tester) async {
        await _pumpScreen(tester, _paused);

        expect(find.text('Your profile is hidden'), findsOneWidget);
        expect(find.text('Unhide my profile'), findsOneWidget);
        expect(find.text('Hide my profile'), findsNothing);
      },
    );

    // The countdown is the member's window to change their mind, so it must be
    // present and actionable whenever a deletion is pending.
    testWidgets('a pending deletion leads with a cancellable countdown', (
      tester,
    ) async {
      final lifecycle = AccountLifecycle(
        isActive: true,
        deactivated: true,
        deletionRequestedAt: DateTime.now(),
        deletionEffectiveAt: DateTime.now().add(const Duration(days: 14)),
        deletionCancellable: true,
      );
      await _pumpScreen(tester, lifecycle);

      expect(find.textContaining('Deletion in'), findsOneWidget);
      final cancel = find.byKey(
        const ValueKey('qa.account.cancel_deletion_button'),
      );
      expect(cancel, findsOneWidget);
      expect(tester.widget<FilledButton>(cancel).onPressed, isNotNull);
    });

    // Both controls act on visibility, and a scheduled deletion has already
    // hidden the member; leaving them live would offer two switches for one
    // state and let a pause silently contradict a pending erasure.
    testWidgets('pause and delete are disabled once deletion is scheduled', (
      tester,
    ) async {
      final lifecycle = AccountLifecycle(
        isActive: true,
        deactivated: true,
        deletionEffectiveAt: DateTime.now().add(const Duration(days: 3)),
        deletionCancellable: true,
      );
      await _pumpScreen(tester, lifecycle);

      final pause = tester.widget<FilledButton>(
        find.byKey(const ValueKey('qa.account.pause_toggle_button')),
      );
      expect(pause.onPressed, isNull);

      final delete = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('qa.account.delete_button')),
      );
      expect(delete.onPressed, isNull);
      expect(find.text('Deletion already scheduled'), findsOneWidget);
    });

    // Deletion is the only irreversible action in the app. It must never be a
    // single tap, and the reversible alternative belongs in the same dialog —
    // a member who wants to disappear usually wants to be hidden, not erased.
    testWidgets('delete asks for confirmation and offers hiding instead '
        '[case:common.account_data.delete_your_account.action]', (
      tester,
    ) async {
      await _pumpScreen(tester, _normal);

      // Delete sits below the fold on the default test viewport, as it does on
      // a phone — reaching it is part of the journey.
      final deleteButton = find.byKey(
        const ValueKey('qa.account.delete_button'),
      );
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.text('Hide instead'), findsOneWidget);
      expect(find.text('Keep my account'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('qa.account.delete_confirm_button')),
        findsOneWidget,
      );
    });

    testWidgets('renders on the dark theme without layout errors', (
      tester,
    ) async {
      await _pumpScreen(tester, _paused, themeMode: ThemeMode.dark);

      expect(tester.takeException(), isNull);
      expect(find.text('Your profile is hidden'), findsOneWidget);
    });
  });

  group('AccountLifecycle', () {
    test('parses the server payload', () {
      final lifecycle = AccountLifecycle.fromApi({
        'is_active': true,
        'deactivated': true,
        'deletion_effective_at': '2030-01-01T00:00:00Z',
        'deletion_cancellable': true,
        'export_ready': true,
      });

      expect(lifecycle.deactivated, isTrue);
      expect(lifecycle.deletionScheduled, isTrue);
      expect(lifecycle.deletionCancellable, isTrue);
      expect(lifecycle.exportReady, isTrue);
    });

    test('treats a missing or unparseable timestamp as no deletion', () {
      final blank = AccountLifecycle.fromApi({'is_active': true});
      expect(blank.deletionScheduled, isFalse);
      expect(blank.daysUntilDeletion, 0);

      final broken = AccountLifecycle.fromApi({
        'deletion_effective_at': 'not-a-timestamp',
      });
      expect(broken.deletionScheduled, isFalse);
    });

    // A past effective date must floor at zero rather than report a negative
    // countdown, which would render as "Deletion in -1 days".
    test('an elapsed deadline reports zero days, never negative', () {
      final overdue = AccountLifecycle(
        isActive: true,
        deactivated: true,
        deletionEffectiveAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(overdue.daysUntilDeletion, 0);
    });

    testWidgets('speaks the member\'s language (German)', (tester) async {
      await _pumpScreen(tester, _normal, locale: const Locale('de'));

      expect(find.text('Konto & Daten'), findsOneWidget);
      expect(find.text('Mach eine Pause'), findsOneWidget);
      expect(find.text('Deine Daten herunterladen'), findsOneWidget);
      expect(find.text('Account & Data'), findsNothing);
    });
  });
}
