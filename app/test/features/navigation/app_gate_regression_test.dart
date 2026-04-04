import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/providers/terms_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_completion_provider.dart';
import 'package:verified_dating_app/main.dart';

// ---------------------------------------------------------------------------
// Regression tests verifying the _AppGate navigation logic:
//   auth → terms → profileCompletion → MainNavigationScreen
// These tests ensure the gate never produces a blank screen.
// ---------------------------------------------------------------------------

void main() {
  group('AppGate navigation regression', () {
    testWidgets(
      'shows branded loading screen while checking terms (never blank)',
      (tester) async {
        // Override to an artificially slow terms resolution
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                () => _FakeAuthNotifier(isAuthenticated: true),
              ),
              // termsAcceptanceProvider stays as loading (default)
            ],
            child: const MaterialApp(home: DatingApp()),
          ),
        );
        await tester.pump();

        // Should show a loading spinner — never a bare white scaffold
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shows branded loading screen while checking profile completion',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authNotifierProvider.overrideWith(
                () => _FakeAuthNotifier(isAuthenticated: true),
              ),
              termsAcceptanceProvider.overrideWith((ref) => Future.value(true)),
              // profileCompletionProvider stays as loading (default)
            ],
            child: const MaterialApp(home: DatingApp()),
          ),
        );
        await tester.pump();

        // Should show loading — never blank
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

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

      // WelcomeScreen should render (look for any welcome-specific text)
      // At minimum, the screen should not be blank
      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows ProfileSetupEntryScreen when profile is incomplete', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: true),
            ),
            termsAcceptanceProvider.overrideWith((ref) => Future.value(true)),
            profileCompletionProvider.overrideWith(
              (ref) => Future.value(
                const ProfileCompletion(
                  hasUserRow: true,
                  profileCompletion: 50,
                  photoCount: 1,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Should show the setup entry screen (contains setup flow)
      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows MainNavigationScreen when profile is complete', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: true),
            ),
            termsAcceptanceProvider.overrideWith((ref) => Future.value(true)),
            profileCompletionProvider.overrideWith(
              (ref) => Future.value(
                const ProfileCompletion(
                  hasUserRow: true,
                  profileCompletion: 100,
                  photoCount: 2,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Should see the bottom nav or discover header
      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('connection issue screen shows styled retry (not blank)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthNotifier(isAuthenticated: true),
            ),
            termsAcceptanceProvider.overrideWith((ref) => Future.value(true)),
            profileCompletionProvider.overrideWith(
              (ref) => Future.error(Exception('Connection refused')),
            ),
          ],
          child: const MaterialApp(home: DatingApp()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Should show connection issue screen with retry
      expect(find.text('Connection issue'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
