import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/features/calendar/jump_logic.dart';

void main() {
  test('adjacent months -> animate', () {
    expect(jumpBehaviorForDiff(1), JumpBehavior.animateAdjacent);
    expect(jumpBehaviorForDiff(-1), JumpBehavior.animateAdjacent);
  });

  test('non-adjacent months -> instant', () {
    expect(jumpBehaviorForDiff(0), JumpBehavior.instant);
    expect(jumpBehaviorForDiff(2), JumpBehavior.instant);
    expect(jumpBehaviorForDiff(-12), JumpBehavior.instant);
  });
}
