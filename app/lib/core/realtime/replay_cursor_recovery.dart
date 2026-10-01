bool shouldAttemptCursorSnapshot({
  required int lastSequence,
  required bool alreadyAttempted,
}) => lastSequence > 0 && !alreadyAttempted;
