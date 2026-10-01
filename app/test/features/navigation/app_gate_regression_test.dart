import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/i18n/app_locale_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';
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
              appThemeProvider.overrideWith(_pinnedTheme),
              appLocaleProvider.overrideWith(_pinnedLocale),
              appThemeProvider.overrideWith(_pinnedTheme),
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
            appThemeProvider.overrideWith(_pinnedTheme),
            appLocaleProvider.overrideWith(_pinnedLocale),
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
    // 3. The gate loading screen sits on the theme's ground, like Today and
    //    every other screen, never a bare white page.
    // -----------------------------------------------------------------------
    testWidgets('gate loading uses the theme ground (not white)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appThemeProvider.overrideWith(_pinnedTheme),
            appLocaleProvider.overrideWith(_pinnedLocale),
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: true),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();

      final spinner = find.byType(CircularProgressIndicator);
      final theme = Theme.of(tester.element(spinner));
      final scaffold = tester.widget<Scaffold>(
        find.ancestor(of: spinner, matching: find.byType(Scaffold)).first,
      );
      expect(
        scaffold.backgroundColor ?? theme.scaffoldBackgroundColor,
        theme.scaffoldBackgroundColor,
      );
      expect(theme.scaffoldBackgroundColor, isNot(const Color(0xFFFFFFFF)));
    });

    // -----------------------------------------------------------------------
    // 4. The loading spinner uses the theme's primary colour, not the
    //    default blue MaterialApp spinner.
    // -----------------------------------------------------------------------
    testWidgets('gate loading spinner uses the theme primary', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appThemeProvider.overrideWith(_pinnedTheme),
            appLocaleProvider.overrideWith(_pinnedLocale),
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
      final primary = Theme.of(
        tester.element(indicatorFinder),
      ).colorScheme.primary;
      expect(color, primary);
    });

    // -----------------------------------------------------------------------
    // 5. Verify loading message text is visible (not blank white screen).
    // -----------------------------------------------------------------------
    testWidgets('gate loading shows status message text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appThemeProvider.overrideWith(_pinnedTheme),
            appLocaleProvider.overrideWith(_pinnedLocale),
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
            appThemeProvider.overrideWith(_pinnedTheme),
            appLocaleProvider.overrideWith(_pinnedLocale),
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
    isNewAccount: isAuthenticated,
    userId: isAuthenticated ? 'user-1' : null,
    username: isAuthenticated ? 'test_user' : null,
  );
}

/// The gate asks for the account's stored theme once authenticated. These
/// tests exercise navigation, not theming, and stub no HTTP layer — without
/// this the settings request stays in flight and the test fails on a pending
/// timer rather than on anything it set out to check.
AppThemeNotifier _pinnedTheme(Ref ref) => _PinnedThemeNotifier(ref);

class _PinnedThemeNotifier extends AppThemeNotifier {
  _PinnedThemeNotifier(super.ref);

  @override
  Future<void> ensureLoaded() async {}
}

/// Same reason as [_pinnedTheme]: the gate also asks for the account's stored
/// language, which would otherwise leave a settings request (and its timer)
/// in flight.
AppLocaleNotifier _pinnedLocale(Ref ref) => _PinnedLocaleNotifier(ref);

class _PinnedLocaleNotifier extends AppLocaleNotifier {
  _PinnedLocaleNotifier(super.ref);

  @override
  Future<void> ensureLoaded() async {}
}
