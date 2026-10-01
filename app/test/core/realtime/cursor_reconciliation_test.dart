import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/realtime/replay_cursor_recovery.dart';

void main() {
  test('snapshot recovery is attempted once for a resumable cursor', () {
    expect(
      shouldAttemptCursorSnapshot(lastSequence: 41, alreadyAttempted: false),
      true,
    );
    expect(
      shouldAttemptCursorSnapshot(lastSequence: 0, alreadyAttempted: false),
      false,
    );
    expect(
      shouldAttemptCursorSnapshot(lastSequence: 41, alreadyAttempted: true),
      false,
    );
  });
}
