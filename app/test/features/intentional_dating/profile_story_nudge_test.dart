import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_story_nudge.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Map<String, dynamic> story(String prompt) => {
  'prompt_id': prompt,
  'text': 'A story about $prompt',
};

Widget host(
  Future<Map<String, dynamic>> Function() stories, {
  double width = 390,
  double scale = 1,
  Brightness brightness = Brightness.light,
  Locale? locale,
}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    profileStoriesProvider.overrideWith((ref, user) => stories()),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    theme: ThemePresets.themeFor(
      ThemePresets.realLife,
    ).copyWith(brightness: brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SizedBox(width: width - 40, child: const ProfileStoryNudge()),
      ),
    ),
  ),
);

void main() {
  testWidgets('German member sees the story card in German', (tester) async {
    await tester.pumpWidget(
      host(
        () async => {
          'stories': [story('little_joy')],
        },
        locale: const Locale('de'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 von 3 Geschichten geteilt'), findsOneWidget);
    expect(
      find.textContaining(
        'Zuletzt: „Eine Kleinigkeit, für die ich mir immer Zeit nehme“.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('1 von 3 Geschichten geschrieben'),
      findsOneWidget,
    );
    expect(find.text('Weitere Geschichte hinzufügen'), findsOneWidget);
    expect(find.text('Add another story'), findsNothing);
  });

  testWidgets('German member with no stories gets German prompt ideas', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(() async => {'stories': <Object>[]}, locale: const Locale('de')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Erzähl ein bisschen mehr von deiner Geschichte'),
      findsOneWidget,
    );
    expect(find.text('Ideen für den Anfang'), findsOneWidget);
    expect(
      find.text('Ein Wochenende, das sich zu erzählen lohnt'),
      findsOneWidget,
    );
    expect(find.text('Schreib deine erste Geschichte'), findsOneWidget);
  });

  testWidgets('no stories yet: explains stories, suggests prompts and '
      'invites the first one', (tester) async {
    await tester.pumpWidget(host(() async => {'stories': <Object>[]}));
    await tester.pumpAndSettle();
    expect(find.text('Tell a little more of your story'), findsOneWidget);
    expect(find.textContaining('People read these'), findsOneWidget);
    expect(find.bySemanticsLabel('0 of 3 stories written'), findsOneWidget);
    expect(find.text('Ideas to start with'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(3));
    expect(find.text('Write your first story'), findsOneWidget);
  });

  testWidgets('some stories: shows progress and the latest prompt', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        () async => {
          'stories': [story('little_joy'), story('weekend')],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 of 3 stories shared'), findsOneWidget);
    expect(find.textContaining('A weekend worth sharing'), findsOneWidget);
    expect(find.bySemanticsLabel('2 of 3 stories written'), findsOneWidget);
    expect(find.text('Ideas to start with'), findsNothing);
    expect(find.text('Add another story'), findsOneWidget);
  });

  testWidgets('three stories: complete, offers editing', (tester) async {
    await tester.pumpWidget(
      host(
        () async => {
          'stories': [story('little_joy'), story('weekend'), story('care')],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your story is complete'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Edit your stories'), findsOne);
  });

  testWidgets('a failed load still offers the way in without a count', (
    tester,
  ) async {
    await tester.pumpWidget(host(() async => throw StateError('offline')));
    await tester.pumpAndSettle();
    expect(find.text('Open your stories'), findsOneWidget);
    expect(find.textContaining('stories written'), findsNothing);
  });

  testWidgets('the button opens the stories screen', (tester) async {
    await tester.pumpWidget(host(() async => {'stories': <Object>[]}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.today.stories')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileStoriesScreen), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits a small phone at large text ($brightness)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          () async => {'stories': <Object>[]},
          width: 320,
          scale: 2,
          brightness: brightness,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
