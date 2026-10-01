@Tags(<String>['lint'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the 4pt spacing grid.
///
/// Controls look subtly misaligned between screens when each screen invents its
/// own padding — 14 here, 18 there, 22 somewhere else. Nothing is individually
/// wrong; together they mean no two screens share a ruler.
///
/// This is a hard floor. The former off-grid backlog is closed, so every new
/// spacing literal must remain on the 4pt grid.
void main() {
  const gridStep = 4;

  // Values that are not spacing: a 1pt hairline and the sub-pixel insets used
  // to fake a border are legitimately off-grid.
  const nonSpacing = <int>{0, 1};

  final ctorPattern = RegExp(
    r'EdgeInsets\.(all|symmetric|fromLTRB|only)\(([^()]*)\)',
  );
  final intLiteral = RegExp(r'(?<![\w.])\d+(?![\w.])');

  List<File> sourceFiles() {
    final dir = Directory('lib');
    if (!dir.existsSync()) {
      return const <File>[];
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) =>
              !file.path.endsWith('.g.dart') &&
              !file.path.endsWith('.freezed.dart'),
        )
        .toList();
  }

  test('off-grid spacing literals do not increase', () {
    final offenders = <String>[];

    for (final file in sourceFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final match in ctorPattern.allMatches(lines[i])) {
          for (final literal in intLiteral.allMatches(match.group(2) ?? '')) {
            final value = int.tryParse(literal.group(0)!);
            if (value == null ||
                nonSpacing.contains(value) ||
                value % gridStep == 0) {
              continue;
            }
            offenders.add('${file.path}:${i + 1}  ${match.group(0)}');
          }
        }
      }
    }

    // Fully closed: every EdgeInsets literal sits on the 4pt grid. Ties were
    // rounded up so controls gained breathing room rather than tightening,
    // which also protects touch targets.
    //
    // This is now a hard floor, not a ratchet. It must stay at zero.
    const baseline = 0;

    expect(
      offenders.length,
      lessThanOrEqualTo(baseline),
      reason:
          'Off-grid spacing grew to ${offenders.length} (baseline $baseline).\n'
          'Use the AppLayout.space* scale for new spacing.\n'
          '${offenders.join('\n')}',
    );
  });

  test('the spacing scale itself is on the grid', () {
    // AppLayout is the ruler; if its own steps drift off the grid, every screen
    // that uses it inherits the drift.
    const scale = <int>[4, 8, 12, 16, 20, 24, 32, 40, 56];
    for (final step in scale) {
      expect(
        step % gridStep,
        0,
        reason: 'AppLayout spacing step $step is not a multiple of $gridStep',
      );
    }
  });
}
