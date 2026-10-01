import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/web/web_member_workspace.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../support/layout_webview_platform.dart';
import 'screen_matrix_harness.dart';

/// Accessibility guideline checks for every screen in the matrix.
///
/// The layout matrix only switches semantics on; it never asks whether what it
/// builds is usable with TalkBack or VoiceOver, or with a thumb. These run
/// Flutter's own guideline checks over the settled semantics tree of every
/// screen in `screen_matrix_harness.dart` (plus the authenticated web shell),
/// on the reference phone, in both shipped themes:
///
///  * [labeledTapTargetGuideline] — anything tappable announces a label or
///    tooltip, so a screen reader never says just "button".
///  * [androidTapTargetGuideline] — anything tappable is at least 48x48.
///  * [textContrastGuideline] — text meets WCAG AA contrast against what is
///    actually painted behind it.
///
/// Screens are pumped exactly as the layout matrix pumps them — no backend —
/// so most show their signed-out, empty or error state. That is the state
/// being checked.
///
/// Known failures live in [_knownFailures]. It is a ratchet, not a skip list:
/// a screen may not fail any *other* guideline, may not fail an allowlisted one
/// on more nodes than recorded, and an entry that has improved or been fixed
/// must be lowered or deleted in the same change. The list only shrinks.
void main() {
  WebViewPlatform.instance = LayoutWebViewPlatform();

  // VoiceIcebreakersScreen constructs an AudioRecorder, which fires an
  // unawaited `create` on the record plugin's channel. The layout matrix never
  // lets real async work complete, so the MissingPluginException never lands;
  // the contrast check has to (it renders the frame for real), and the
  // exception would then surface as an uncaught test error. Answer the channel
  // instead: this is plugin plumbing, not something the guidelines judge.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (call) async => null,
        );
  });

  final guidelines = <String, AccessibilityGuideline>{
    _labels: labeledTapTargetGuideline,
    _tapTargets: androidTapTargetGuideline,
    _contrast: textContrastGuideline,
  };

  final themes = <String, ThemeData>{
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  };

  final reference = screenMatrixDevices[screenMatrixReferencePhone]!;
  final flags = <Override>[
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(RuntimeFeatureFlags.defaults),
    ),
  ];

  final targets = <String, _Target>{
    for (final entry in buildScreenMatrix().entries)
      entry.key: (build: entry.value, size: reference, overrides: const []),
    // The browser shell is not a *Screen, so the matrix does not list it.
    _webDesktop: (
      build: WebMemberWorkspace.new,
      size: const Size(1440, 900),
      overrides: flags,
    ),
    _webPhone: (
      build: WebMemberWorkspace.new,
      size: reference,
      overrides: flags,
    ),
  };

  themes.forEach((themeLabel, theme) {
    targets.forEach((label, target) {
      testWidgets('$label meets accessibility guidelines [$themeLabel]', (
        tester,
      ) async {
        final failing = <String, String>{};
        await pumpAndCollectLayoutErrors(
          tester,
          target.build(),
          target.size,
          theme,
          overrides: target.overrides,
          whileMounted: () async {
            for (final entry in guidelines.entries) {
              final evaluation = await entry.value.evaluate(tester);
              if (!evaluation.passed) {
                failing[entry.key] = evaluation.reason ?? '';
              }
            }
          },
        );

        final known = _knownFailures['$label [$themeLabel]'] ?? const {};
        final problems = <String>[];
        for (final guideline in guidelines.keys) {
          final reason = failing[guideline];
          final nodes = reason == null
              ? 0
              : 'SemanticsNode#'.allMatches(reason).length;
          final ceiling = known[guideline]?.nodes ?? 0;
          if (nodes > ceiling) {
            problems.add(
              '$guideline: $nodes failing node(s), allowlist permits $ceiling'
              '\n$reason',
            );
          } else if (nodes < ceiling) {
            problems.add(
              '$guideline improved: $nodes failing node(s), allowlist still '
              'says $ceiling. '
              '${nodes == 0 ? 'Delete' : 'Lower'} the "$label [$themeLabel]" '
              '$guideline entry in _knownFailures.',
            );
          }
        }
        expect(
          problems,
          isEmpty,
          reason:
              '$label [$themeLabel] accessibility:\n${problems.join('\n\n')}',
        );
      });
    });
  });

  test('every allowlisted accessibility failure names a real check', () {
    for (final MapEntry(key: target, value: entries)
        in _knownFailures.entries) {
      final match = RegExp(r'^(.*) \[(light|dark)\]$').firstMatch(target);
      expect(match, isNotNull, reason: '"$target" must end in [light|dark]');
      expect(
        targets.containsKey(match!.group(1)),
        isTrue,
        reason: '"$target" is not a screen this suite checks',
      );
      for (final MapEntry(key: guideline, value: known) in entries.entries) {
        expect(guidelines.containsKey(guideline), isTrue, reason: guideline);
        expect(known.nodes, greaterThan(0), reason: '$target $guideline');
        expect(known.why, isNotEmpty, reason: '$target $guideline');
      }
    }
  });
}

typedef _Target = ({
  Widget Function() build,
  Size size,
  List<Override> overrides,
});

typedef _Known = ({int nodes, String why});

const _labels = 'labeled tap targets';
const _tapTargets = 'android tap targets';
const _contrast = 'text contrast';
const _webDesktop = 'WebMemberWorkspace desktop 1440x900';
const _webPhone = 'WebMemberWorkspace phone';

// Shared reasons, so each class of debt reads the same wherever it appears.
const _swipeCardLinks =
    'SwipeCard\'s inline "View more" and "Message" text actions are 14-15pt '
    'tall. SwipeCard is shared with the golden-pinned discovery deck, so '
    'growing them needs a golden refresh.';
const _contrastBacklog =
    'Contrast backlog: theme-dependent text colours need a design pass across '
    'the Daylight/Ember themes and presets, not a per-screen patch.';

/// Per-screen, per-theme, per-guideline accessibility debt.
///
/// `nodes` is the exact number of failing semantics nodes today. The suite
/// fails if it grows, and also fails if it shrinks until the entry is lowered
/// or deleted, so this map can only get smaller. Do not add entries: fix the
/// screen.
const _knownFailures = <String, Map<String, _Known>>{
  // ── Tap targets and labels ──────────────────────────────────────────────
  'SpotlightProfilesScreen [light]': {
    _tapTargets: (nodes: 2, why: _swipeCardLinks),
  },
  'SpotlightProfilesScreen [dark]': {
    _tapTargets: (nodes: 2, why: _swipeCardLinks),
  },
  // ── Text contrast ───────────────────────────────────────────────────────
  'CallSessionScreen [light]': {
    _contrast: (
      nodes: 1,
      why: '"Call session" title, 1.05:1 on its ground. $_contrastBacklog',
    ),
  },
  'LevelProgressionScreen [light]': {
    _contrast: (
      nodes: 2,
      why:
          'Signed-out notice and Retry on an error-red card. $_contrastBacklog',
    ),
  },
  'LevelProgressionScreen [dark]': {
    _contrast: (
      nodes: 2,
      why:
          'Signed-out notice and Retry on an error-red card. $_contrastBacklog',
    ),
  },
  'SubscriptionScreen [light]': {
    _contrast: (nodes: 1, why: 'Signed-out notice, 3.74:1. $_contrastBacklog'),
  },
  'WalletPaymentScreen [light]': {
    _contrast: (
      nodes: 1,
      why: 'Muted footnote, under 4.5:1. $_contrastBacklog',
    ),
  },
};
