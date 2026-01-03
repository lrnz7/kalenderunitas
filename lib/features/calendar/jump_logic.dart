enum JumpBehavior { animateAdjacent, instant }

/// Return the jump behavior for a requested months difference.
/// - Adjacent months (abs(diff) == 1) -> animateAdjacent
/// - Otherwise -> instant
JumpBehavior jumpBehaviorForDiff(int monthsDiff) {
  return monthsDiff.abs() == 1
      ? JumpBehavior.animateAdjacent
      : JumpBehavior.instant;
}
