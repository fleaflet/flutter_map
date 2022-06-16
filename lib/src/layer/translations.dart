import 'package:flutter/material.dart';

import 'package:flutter_map/src/core/point.dart';

Offset applyRotationTranslation(
    {required CustomPoint<num> size,
    required double radians,
    required Offset point}) {
  final fromCenter = point.translate(-size.x / 2, -size.y / 2);
  final matrix = Matrix4.identity()..multiply(Matrix4.rotationZ(radians));
  return MatrixUtils.transformPoint(matrix, fromCenter)
      .translate(size.x / 2, size.y / 2);
}

Offset applyPitchTranslation(
    {required CustomPoint<num> size,
    required double radians,
    required Offset point}) {
  final translation =
      Alignment.center.alongSize(Size(size.x.toDouble(), size.y.toDouble()));
  final matrix = Matrix4.identity()
    ..translate(translation.dx, translation.dy)
    ..multiply(Matrix4.identity()
      ..setEntry(3, 1, -0.002)
      ..rotateX(radians))
    ..translate(-translation.dx, -translation.dy);
  return MatrixUtils.transformPoint(matrix, point);
}
