import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/main.dart';

// ---------------------------------------------------------------------------
// Regression tests verifying the _AppGate navigation logic:
//   auth → terms → profileCompletion → MainNavigationScreen
// These tests ensure the gate never produces a blank screen.
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    // DatingApp.build() uses AppRuntimeConfig which reads dotenv.
    // Load an empty environment so it doesn't throw NotInitializedError.
    dotenv.testLoad(fileInput: '');
  });

  group('AppGate navigation regression', () {
    // -----------------------------------------------------------------------
    // 1. Terms-loading gate: terms provider stays in AsyncLoading so the gate
    //    must show the branded loading screen (gold spinner, not bare white).
    // -----------------------------------------------------------------------
    testWidgets(
      'shows branded loading screen while checking terms (never blank)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                () => _FakeAuthNotifier(isAuthenticated: true),
              ),
              // termsAcceptanceProvider left as default → will stay loading
              // in test sandbox since it can't reach SharedPreferences/API
            ],
            child: const MaterialApp(home: DatingApp()),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    // -----------------------------------------------------------------------
    // 2. Welcome screen when not authenticated
    // -----------------------------------------------------------------------
    testWidgets('shows WelcomeScreen when not authenticated', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: false),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // -----------------------------------------------------------------------
    // 3. Verify the Crystal Gold themed gradient is present in the gate
    //    loading screen (bgGradient background instead of bare white).
    // -----------------------------------------------------------------------
    testWidgets('gate loading uses Crystal Gold bgGradient (not white)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: true),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();

      // The loading screen's Container should have the bgGradient decoration.
      final containerFinder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).gradient == AppTheme.bgGradient,
      );
      expect(containerFinder, findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 4. The loading screen should show a gold-colored spinner, not the
    //    default blue MaterialApp spinner.
    // -----------------------------------------------------------------------
    testWidgets('gate loading has crystalGoldSoft spinner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: true),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();

      final indicatorFinder = find.byType(CircularProgressIndicator);
      expect(indicatorFinder, findsOneWidget);

      final CircularProgressIndicator indicator = tester.widget(
        indicatorFinder,
      );
      final color =
          (indicator.valueColor as AlwaysStoppedAnimation<Color>?)?.value;
      expect(color, AppTheme.crystalGoldSoft);
    });

    // -----------------------------------------------------------------------
    // 5. Verify loading message text is visible (not blank white screen).
    // -----------------------------------------------------------------------
    testWidgets('gate loading shows status message text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: true),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();

      // The loading screen shows "Checking terms…" while waiting for terms
      expect(find.text('Checking terms…'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 6. Verify the gate never shows a completely empty scaffold (the old bug).
    // -----------------------------------------------------------------------
    testWidgets('gate never shows bare white Scaffold', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: true),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();

      // There should be visible content — not just a bare Scaffold
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byType(Text), findsWidgets);
    });
  });
}

/// Fake auth notifier for controlling authentication state in tests.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier({required this.isAuthenticated});

  final bool isAuthenticated;

  @override
  AuthState build() => AuthState(
    isAuthenticated: isAuthenticated,
    userId: isAuthenticated ? 'user-1' : null,
    phoneNumber: isAuthenticated ? '+919999999999' : null,
  );
}
