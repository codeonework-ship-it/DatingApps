import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/core/widgets/themed_screen_scaffold.dart';

void main() {
  group('ThemedScreenScaffold', () {
    testWidgets('renders body content on normal state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThemedScreenScaffold(body: Center(child: Text('Main Content'))),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.byType(PostLoginBackdrop), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThemedScreenScaffold(
            isLoading: true,
            loadingMessage: 'Fetching data…',
            body: Text('Hidden'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching data…'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
    });

    testWidgets('shows error state with retry button', (tester) async {
      var retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ThemedScreenScaffold(
            errorMessage: 'Network timeout',
            onRetry: () => retryTapped = true,
            body: const Text('Hidden'),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Network timeout'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);

      // Tap retry
      await tester.tap(find.text('Try Again'));
      expect(retryTapped, isTrue);
    });

    testWidgets('shows empty state with custom icon and title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThemedScreenScaffold(
            isEmpty: true,
            emptyIcon: Icons.favorite_border,
            emptyTitle: 'No matches yet',
            emptySubtitle: 'Start swiping!',
            body: Text('Hidden'),
          ),
        ),
      );

      expect(find.text('No matches yet'), findsOneWidget);
      expect(find.text('Start swiping!'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('uses bgGradient for pre-login mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThemedScreenScaffold(
            isPreLogin: true,
            body: Center(child: Text('Pre-Login')),
          ),
        ),
      );

      expect(find.text('Pre-Login'), findsOneWidget);
      // Should NOT have PostLoginBackdrop
      expect(find.byType(PostLoginBackdrop), findsNothing);
    });

    testWidgets('wraps body with PostLoginBackdrop by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThemedScreenScaffold(body: Center(child: Text('Post-Login'))),
        ),
      );

      expect(find.byType(PostLoginBackdrop), findsOneWidget);
    });

    testWidgets('renders appBar when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ThemedScreenScaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: AppBar(title: const Text('Test AppBar')),
            ),
            body: const Center(child: Text('Body')),
          ),
        ),
      );

      expect(find.text('Test AppBar'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('no overflow on compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: ThemedScreenScaffold(
            isLoading: true,
            loadingMessage: 'Please wait...',
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state uses default text when none provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThemedScreenScaffold(isEmpty: true, body: Text('Hidden')),
        ),
      );

      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('error state shows without retry when onRetry is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThemedScreenScaffold(
            errorMessage: 'Some error occurred',
            body: Text('Hidden'),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Some error occurred'), findsOneWidget);
      expect(find.text('Try Again'), findsNothing);
    });
  });
}
