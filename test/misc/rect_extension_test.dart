import 'dart:ui';

import 'package:flutter_map/src/misc/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes a line segment wholly inside a viewport', () {
    const viewport = Rect.fromLTWH(0, 0, 100, 100);

    expect(viewport.aabbContainsLine(20, 20, 80, 80), isTrue);
  });
}
