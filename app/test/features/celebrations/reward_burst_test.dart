import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/celebrations/celebrations_data.dart';
import 'package:verified_dating_app/features/celebrations/reward_burst.dart';
import 'package:verified_dating_app/features/celebrations/reward_burst_host.dart';
import 'package:verified_dating_app/features/celebrations/reward_ledger.dart';
import 'package:verified_dating_app/features/celebrations/rose_rain.dart';
import 'package:verified_dating_app/features/engagement/providers/level_progression_provider.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    userId: 'member-1',
    isAuthenticated: true,
    username: 'member_one',
  );
}

const _burst = RewardBurst(
  kind: RewardBurstKind.xp,
  title: 'Chapter published',
  subtitle: 'Your chapter is out in the world.',
  xp: 25,
);

Finder _burstPainters([RewardBurstStyle? style]) => find.byWidgetPredicate(
  (w) =>
      w is CustomPaint &&
      w.painter is RewardBurstPainter &&
      (style == null || (w.painter! as RewardBurstPainter).style == style),
);

Finder _rosePainters() => find.byWidgetPredicate(
  (w) =>
      w is CustomPaint &&
      w.painter != null &&
      w.painter.runtimeType.toString() == '_RoseRainPainter',
);

Widget _app(Widget home, {ThemePreset? preset, bool reduceMotion = false}) =>
    MaterialApp(
      theme: preset == null
          ? AppTheme.lightTheme
          : ThemePresets.themeFor(preset),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: home,
      ),
    );

/// Lets the host's fetch, the stored state and the diff chain finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  tearDown(debugResetRewardBursts);

  test('each look picks its own burst', () {
    expect(
      RewardBurstStyle.forPreset(ThemePresets.snow),
      RewardBurstStyle.snow,
    );
    expect(
      RewardBurstStyle.forPreset(ThemePresets.rose),
      RewardBurstStyle.roses,
    );
    expect(
      RewardBurstStyle.forPreset(ThemePresets.petal),
      RewardBurstStyle.roses,
    );
    expect(
      RewardBurstStyle.forPreset(ThemePresets.gothic),
      RewardBurstStyle.gothic,
    );
    expect(
      RewardBurstStyle.forPreset(ThemePresets.blueRose),
      RewardBurstStyle.roses,
    );
    expect(
      RewardBurstStyle.forPreset(ThemePresets.blueLotus),
      RewardBurstStyle.lotus,
    );
    for (final other in [
      ThemePresets.love,
      ThemePresets.realLife,
      ThemePresets.forge,
      null,
    ]) {
      expect(
        RewardBurstStyle.forPreset(other),
        RewardBurstStyle.confetti,
        reason: other?.id,
      );
    }
  });

  test('every style paints every frame without error', () {
    const palette = RewardBurstPalette(
      primary: Colors.red,
      secondary: Colors.pink,
      tertiary: Colors.amber,
      ink: Colors.white,
      glow: Colors.lightBlue,
    );
    for (final style in RewardBurstStyle.values) {
      for (final t in [0.0, 0.02, 0.1, 0.3, 0.5, 0.8, 0.97, 1.0]) {
        final recorder = ui.PictureRecorder();
        RewardBurstPainter(
          style: style,
          progress: t,
          palette: palette,
          seed: 7,
        ).paint(Canvas(recorder), const Size(390, 844));
        recorder.endRecording().dispose();
      }
    }
  });

  final cases = <ThemePreset?, RewardBurstStyle>{
    ThemePresets.snow: RewardBurstStyle.snow,
    ThemePresets.rose: RewardBurstStyle.roses,
    ThemePresets.petal: RewardBurstStyle.roses,
    ThemePresets.gothic: RewardBurstStyle.gothic,
    ThemePresets.blueRose: RewardBurstStyle.roses,
    ThemePresets.blueLotus: RewardBurstStyle.lotus,
    ThemePresets.deepField: RewardBurstStyle.confetti,
  };
  for (final MapEntry(key: preset, value: style) in cases.entries) {
    testWidgets('${preset?.id} plays the ${style.name} burst with the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          RewardBurstOverlay(burst: _burst, onDone: () {}),
          preset: preset,
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(_burstPainters(style), findsOneWidget);
      expect(find.text('Chapter published'), findsOneWidget);
      expect(find.text('+25 XP'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    });
  }

  testWidgets('reduced motion shows the card without particles', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        RewardBurstOverlay(burst: _burst, onDone: () {}),
        preset: ThemePresets.snow,
        reduceMotion: true,
      ),
    );
    await tester.pump();
    expect(find.text('Chapter published'), findsOneWidget);
    expect(_burstPainters(), findsNothing);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('the Calm look shows the card without particles', (tester) async {
    await tester.pumpWidget(
      _app(
        RewardBurstOverlay(burst: _burst, onDone: () {}),
        preset: ThemePresets.calm,
      ),
    );
    await tester.pump();
    expect(find.text('Chapter published'), findsOneWidget);
    expect(_burstPainters(), findsNothing);
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('the card is an accessible live region with a 48pt close', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        RewardBurstOverlay(burst: _burst, onDone: () {}),
        preset: ThemePresets.gothic,
        reduceMotion: true,
      ),
    );
    await tester.pump();
    final region = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^Chapter published')),
    );
    expect(region.flagsCollection.isLiveRegion, isTrue);
    expect(region.label, contains('plus 25 XP'));
    final close = find.byKey(const ValueKey('qa.reward_burst.close'));
    final size = tester.getSize(close);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await tester.pump(const Duration(seconds: 7));
    semantics.dispose();
  });

  testWidgets('showRewardBurst queues bursts and closes on demand', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
        preset: ThemePresets.rose,
        reduceMotion: true,
      ),
    );
    var firstDone = false;
    unawaited(showRewardBurst(ctx, _burst).then((_) => firstDone = true));
    unawaited(
      showRewardBurst(ctx, RewardBurst.rewardClaimed('Starter accent')),
    );
    await tester.pump();
    expect(find.text('Chapter published'), findsOneWidget);
    expect(find.text('Reward claimed'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('qa.reward_burst.close')));
    await tester.pump();
    expect(firstDone, isTrue);
    expect(find.text('Chapter published'), findsNothing);
    expect(find.text('Reward claimed'), findsOneWidget);

    // The second closes itself after a few seconds.
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('Reward claimed'), findsNothing);
  });

  group('wall celebration follows the look', () {
    const celebration = WallCelebration(
      id: 'c-1',
      kind: 'cover',
      contentId: 'entry-1',
      tier: 1,
      reach: 0,
      title: 'Golden hour',
    );

    testWidgets('Snow gets snow instead of the petal rain', (tester) async {
      await tester.pumpWidget(
        _app(
          const RoseRainOverlay(celebration: celebration),
          preset: ThemePresets.snow,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(_burstPainters(RewardBurstStyle.snow), findsOneWidget);
      expect(_rosePainters(), findsNothing);
      expect(find.text('Your photo is Cover of the Week'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Gothic gets bats and embers', (tester) async {
      await tester.pumpWidget(
        _app(
          const RoseRainOverlay(celebration: celebration),
          preset: ThemePresets.gothic,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(_burstPainters(RewardBurstStyle.gothic), findsOneWidget);
      expect(_rosePainters(), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Rose gets the rose burst on top of the petal rain', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const RoseRainOverlay(celebration: celebration),
          preset: ThemePresets.rose,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(_burstPainters(RewardBurstStyle.roses), findsOneWidget);
      expect(_rosePainters(), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('RewardBurstHost', () {
    late List<Map<String, dynamic>> ledger;
    late int level;

    Dio fakeApi() => Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final path = options.path;
            final Object body;
            if (path.endsWith('/ledger')) {
              body = <String, dynamic>{'entries': ledger};
            } else if (path.startsWith('/progression/')) {
              body = <String, dynamic>{
                'progression': <String, dynamic>{
                  'current_level': level,
                  'level_name': level == 4 ? 'Conversation Builder' : 'Level',
                },
              };
            } else {
              body = <String, dynamic>{
                'badges': [
                  {
                    'badge_code': 'respectful',
                    'badge_label': 'Respectful Communicator',
                    'status': 'active',
                  },
                ],
              };
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: body,
              ),
            );
          },
        ),
      );

    Map<String, dynamic> entry(int seq, String source, int xp) => {
      'sequence': seq,
      'source': source,
      'awarded_xp': xp,
      'multiplier': 1,
      'occurred_at': '2026-09-01T10:00:00Z',
    };

    Future<ProviderContainer> mount(WidgetTester tester, Dio api) async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          authNotifierProvider.overrideWith(_Auth.new),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(
            const Scaffold(
              body: Stack(
                children: [RewardBurstHost(pollInterval: Duration(seconds: 1))],
              ),
            ),
            preset: ThemePresets.snow,
            reduceMotion: true,
          ),
        ),
      );
      await _settle(tester);
      return container;
    }

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      ledger = [entry(1, 'like_received', 2), entry(2, 'like_received', 2)];
      level = 3;
    });

    testWidgets('baselines on first look, then celebrates new XP once', (
      tester,
    ) async {
      final api = fakeApi();
      await mount(tester, api);
      // A month-old backlog is not celebrated.
      expect(find.byType(RewardBurstCard), findsNothing);

      ledger = [entry(3, 'story_published', 25), ...ledger];
      await tester.pump(const Duration(seconds: 1));
      await _settle(tester);
      expect(find.text('Chapter published'), findsOneWidget);
      expect(find.text('+25 XP'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('qa.reward_burst.close')));
      await tester.pump();

      // Later polls do not replay it.
      await tester.pump(const Duration(seconds: 1));
      await _settle(tester);
      expect(find.byType(RewardBurstCard), findsNothing);

      // Neither does a fresh launch for the same member.
      await tester.pumpWidget(const SizedBox.shrink());
      debugResetRewardBursts();
      await mount(tester, api);
      await tester.pump(const Duration(seconds: 1));
      await _settle(tester);
      expect(find.byType(RewardBurstCard), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a level-up reported by the Level & XP screen plays', (
      tester,
    ) async {
      final api = fakeApi();
      final container = await mount(tester, api);
      expect(find.byType(RewardBurstCard), findsNothing);

      container
          .read(rewardSnapshotReportsProvider.notifier)
          .state = RewardSnapshot(
        ledger: [
          XPEntry.fromJson(entry(3, 'photo_shared', 20)),
          XPEntry.fromJson(entry(2, 'like_received', 2)),
        ],
        level: 4,
        levelName: 'Conversation Builder',
      );
      await _settle(tester);
      expect(find.text('Level 4 reached'), findsOneWidget);
      expect(find.text('Conversation Builder'), findsOneWidget);
      expect(find.text('+20 XP'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
