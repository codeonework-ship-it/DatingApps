// Dead-control audit: every enabled, hit-testable control on every screen in
// the matrix (and in the dialogs, sheets and menus those controls open) must
// do something a member can observe when tapped.
//
// Why: buttons shipped that did nothing — the profile's Message/Love popped a
// value its opener ignored, Spotlight's Like/Pass/Message never reached the
// server, Spotlight's "Passed (n)" had an empty callback — while the tests
// only checked that the controls existed.
//
// How it works (see dead_control_harness.dart):
//   * Each screen is pushed over a launcher with offline fixtures and a
//     recording fake API, NavigatorObserver and platform-channel recorder.
//   * Every app-built control is found by widget type (IconButton, the
//     Filled/Outlined/Text/Elevated buttons, GlassButton and other app
//     buttons via their InkWell/GestureDetector, ListTile, switches, chips,
//     menus, dropdowns, FAB, sliders, tabs, bottom navigation items).
//   * Each control is tapped in a fresh pump; the test fails when the tap
//     produced no API call, route or main-tab change, platform call, focus
//     change or visible change.
//
// Files:
//   * dead_control_manifest.json — generated inventory, one test per entry,
//     named `<Screen>: <control> has an effect [case:<catalog case id>]`.
//   * dead_control_allowlist.json — inert-by-design controls, with reasons.
//   * ../qa/catalog/dead_controls.json — confirmed dead controls (product
//     bugs); their tests are skipped until the entry is removed.
//
// Controls a screen gained since the manifest was generated are still audited
// by each screen's "controls not in the manifest" test, so a new dead button
// fails the suite even before anyone regenerates.
//
// Regenerate the manifest after UI changes (all screens, or a subset):
//   flutter test test/features/responsive/dead_control_audit_test.dart \
//     --dart-define=DEAD_CONTROL_UPDATE=true \
//     [--dart-define=DEAD_CONTROL_SCREENS=SpotlightProfilesScreen,ChatScreen]

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../support/layout_webview_platform.dart';
import 'dead_control_harness.dart';
import 'screen_matrix_harness.dart';

const _update = bool.fromEnvironment('DEAD_CONTROL_UPDATE');
const _only = String.fromEnvironment('DEAD_CONTROL_SCREENS');

/// Screens that cannot be audited in a widget test, and why.
const _unauditable = <String, String>{
  // The hosted payment page is a platform WebView; only its chrome renders
  // here, and its close control is covered by the back-affordance audit.
  'CheckoutWebViewScreen': 'platform WebView content',
};

void main() {
  WebViewPlatform.instance = LayoutWebViewPlatform();
  final screens = buildScreenMatrix();
  final selected = _only.isEmpty
      ? screens.keys.toSet()
      : _only.split(',').map((s) => s.trim()).toSet();
  if (_update) {
    _declareUpdate(screens, selected);
  } else {
    _declareAudit(screens);
  }
}

String _deadMessage(ManifestEntry entry, ProbeResult result) {
  final c = result.control;
  return 'DEAD CONTROL on ${entry.screen}: ${c?.describe() ?? entry.control}\n'
      '  path: ${entry.control}\n'
      '  tapping it made no API call, route or main-tab change, platform '
      'call, focus '
      'change or visible change.\n'
      '${result.errors.isEmpty ? '' : '  errors during the tap: ${result.errors.take(3).join(' | ')}\n'}'
      '  Fix the control, or — if it is inert by design — add it to '
      '$deadControlAllowlistPath with a reason.';
}

void _declareAudit(Map<String, Widget Function()> screens) {
  final manifest = readManifest();
  final allowlist = readControlList(deadControlAllowlistPath, 'reason');
  final knownDead = readControlList(deadControlsPath, 'effect_expected');

  test('the dead-control manifest covers every screen in the matrix', () {
    final missing = screens.keys
        .where((s) => !manifest.containsKey(s) && !_unauditable.containsKey(s))
        .toList();
    expect(
      missing,
      isEmpty,
      reason:
          'Screens never audited for dead controls. Regenerate with:\n'
          '$deadControlUpdateCommand',
    );
  });

  for (final MapEntry(key: screen, value: build) in screens.entries) {
    if (_unauditable.containsKey(screen)) continue;
    final entries = manifest[screen] ?? const <ManifestEntry>[];
    final seenNames = <String, int>{};

    void declare(ManifestEntry entry) {
      final base = entry.testName();
      final n = (seenNames[base] ?? 0) + 1;
      seenNames[base] = n;
      final name = entry.testName(occurrence: n);
      // `group('<Screen>:')` + test `<control> has an effect …` gives the
      // full name `<Screen>: <control> has an effect [case:…]`.
      final local = name.substring('$screen: '.length);
      final reason = knownDead[(screen, entry.control)];
      group(
        '$screen:',
        () {
          testWidgets(local, (tester) async {
            final session = await AuditSession.open(tester, screen, build);
            final ProbeResult result;
            try {
              result = await session.probe(entry.path);
            } finally {
              await session.close();
            }
            expect(
              result.found,
              isTrue,
              reason:
                  'Stale dead-control manifest: "${result.missingStep}" is no '
                  'longer on $screen. Regenerate with:\n'
                  '$deadControlUpdateCommand '
                  '--dart-define=DEAD_CONTROL_SCREENS=$screen\n'
                  'On screen now: ${result.available.join(', ')}',
            );
            expect(
              result.reachable,
              isTrue,
              reason:
                  '${result.control?.describe()} is covered or off screen '
                  'and cannot be tapped.',
            );
            expect(
              result.effects,
              isNotEmpty,
              reason: _deadMessage(entry, result),
            );
          });
        },
        skip: reason == null
            ? null
            : 'Known dead control, listed in qa/catalog/dead_controls.json '
                  '(expected: $reason). Remove the entry once fixed.',
      );
    }

    for (final entry in entries) {
      if (allowlist.containsKey((screen, entry.control))) continue;
      declare(entry);
    }

    // New controls the manifest has not seen yet are audited here.
    group('$screen:', () {
      testWidgets('controls not yet in the dead-control manifest have an effect', (
        tester,
      ) async {
        final known = {for (final e in entries) e.control};
        var session = await AuditSession.open(tester, screen, build);
        // Close (which restores FlutterError.onError) even when discovery
        // throws: otherwise the error is reported against the overridden
        // handler and the test hangs instead of failing.
        final List<LiveControl> live;
        try {
          live = session.controls();
        } finally {
          await session.close();
        }
        final fresh = live
            .where(
              (c) =>
                  !known.contains(c.identity) &&
                  !allowlist.containsKey((screen, c.identity)) &&
                  !knownDead.containsKey((screen, c.identity)),
            )
            .toList();
        final dead = <String>[];
        for (final control in fresh) {
          session = await AuditSession.open(tester, screen, build);
          final ProbeResult result;
          try {
            result = await session.probe([control.identity]);
          } finally {
            await session.close();
          }
          if (result.dead) {
            dead.add('${control.describe()}  (identity: ${control.identity})');
          }
        }
        if (fresh.isNotEmpty) {
          debugPrint(
            '$screen has ${fresh.length} control(s) not in the dead-control '
            'manifest (${fresh.map((c) => c.identity).join(', ')}); '
            'regenerate it so each gets its own test:\n'
            '$deadControlUpdateCommand --dart-define=DEAD_CONTROL_SCREENS=$screen',
          );
        }
        expect(
          dead,
          isEmpty,
          reason:
              'DEAD CONTROLS on $screen (no API call, route or main-tab change, '
              'platform call, focus change or visible change):\n'
              '${dead.join('\n')}',
        );
      });
    });
  }
}

void _declareUpdate(
  Map<String, Widget Function()> screens,
  Set<String> selected,
) {
  final manifest = readManifest();
  final report = <String, Object?>{};
  final catalog = CatalogIndex.load();

  Map<String, Object?> probeJson(
    List<String> path,
    LiveControl control,
    ProbeResult result,
    String? caseId,
  ) => {
    'path': path,
    'kind': control.kind,
    'label': control.label,
    'key': control.qaKey,
    'source': control.source?.toString(),
    'own_source': control.ownSource?.toString(),
    'case': caseId,
    'reachable': result.reachable,
    'dead': result.dead,
    'effects': result.effects,
    'errors': result.errors.take(5).toList(),
  };

  for (final MapEntry(key: screen, value: build) in screens.entries) {
    if (!selected.contains(screen) || _unauditable.containsKey(screen)) {
      continue;
    }
    testWidgets('discover controls on $screen', (tester) async {
      expect(
        widgetCreationTracked,
        isTrue,
        reason: 'run with --track-widget-creation (the flutter test default)',
      );
      final entries = <ManifestEntry>[];
      final probes = <Map<String, Object?>>[];

      var session = await AuditSession.open(tester, screen, build);
      final top = session.controls();
      await session.close();

      for (final control in top) {
        session = await AuditSession.open(tester, screen, build);
        final ProbeResult result;
        var popup = const <LiveControl>[];
        try {
          result = await session.probe([control.identity]);
          if (result.popupOpened) popup = session.controls();
        } finally {
          await session.close();
        }
        final caseId = catalog.caseFor(control);
        probes.add(probeJson([control.identity], control, result, caseId));
        if (!result.found || !result.reachable) continue;
        entries.add(
          ManifestEntry(
            screen: screen,
            path: [control.identity],
            label: control.label,
            kind: control.kind,
            qaKey: control.qaKey,
            source: control.source?.toString(),
            caseId: caseId,
            effects: result.effects,
          ),
        );

        // The dialog, sheet or menu this control opened.
        for (final inner in popup) {
          final path = [control.identity, inner.identity];
          session = await AuditSession.open(tester, screen, build);
          final ProbeResult innerResult;
          try {
            innerResult = await session.probe(path);
          } finally {
            await session.close();
          }
          final innerCase = catalog.caseFor(inner);
          probes.add(probeJson(path, inner, innerResult, innerCase));
          if (!innerResult.found || !innerResult.reachable) continue;
          entries.add(
            ManifestEntry(
              screen: screen,
              path: path,
              label: inner.label,
              kind: inner.kind,
              qaKey: inner.qaKey,
              source: inner.source?.toString(),
              caseId: innerCase,
              effects: innerResult.effects,
              openerLabel: control.label.isEmpty ? control.kind : control.label,
            ),
          );
        }
      }
      manifest[screen] = entries;
      report[screen] = probes;
      final dead = probes.where((p) => p['dead'] == true).toList();
      debugPrint(
        '$screen: ${top.length} controls, ${entries.length} audited '
        '(incl. dialogs/sheets/menus), ${dead.length} dead',
      );
      for (final d in dead) {
        debugPrint('  DEAD ${d['kind']} "${d['label']}" ${d['source']}');
      }
    });
  }

  tearDownAll(() {
    writeManifest(manifest);
    final file = File(deadControlReportPath);
    file.parent.createSync(recursive: true);
    final previous = file.existsSync()
        ? (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
        : <String, dynamic>{};
    file.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({...previous, ...report}),
    );
  });
}
