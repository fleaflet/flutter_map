import 'dart:ui';

import 'package:meta/meta.dart';

@immutable
class TapPosition {
  const TapPosition(this.global, this.relative);

  final Offset global;
  final Offset? relative;

  @override
  bool operator ==(dynamic other) {
    if (other is! TapPosition) return false;
    final typedOther = other;
    return global == typedOther.global && relative == other.relative;
  }

  @override
  int get hashCode => Object.hash(global, relative);
}
