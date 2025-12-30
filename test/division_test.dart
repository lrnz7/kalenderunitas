import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalender_unitas/shared/utils/helpers.dart';

void main() {
  test('Division display name mapping and colors', () {
    expect(DivisionUtils.displayName('Unitas SI'), 'Unitas');
    expect(DivisionUtils.displayName('Unitas'), 'Unitas');
    expect(DivisionUtils.displayName('BPH'), 'BPH');

    final unitasColor = DivisionUtils.colorFor('Unitas SI');
    expect(unitasColor.value, const Color(0xFF00BCD4).value);

    final bphColor = DivisionUtils.colorFor('BPH');
    expect(bphColor.value, const Color(0xFF0066CC).value);
  });
}
