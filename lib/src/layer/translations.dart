import 'dart:math';

import 'package:flutter/material.dart';

Offset applyRotationTranslation(
    {required double radians, required Offset point}) {
  final matrix = Matrix4.rotationZ(radians);
  return MatrixUtils.transformPoint(matrix, point);
}

Offset applyPitchTranslation(
    {required double height, required double radians, required Offset point}) {
  // cos(θ) = adjacent/hypotenuse
  final translation = Alignment.center.alongSize(Size(0, height));
  final matrix = Matrix4.identity();
  matrix.translate(translation.dx, translation.dy);
  matrix.multiply(Matrix4.rotationX(radians));
  matrix.translate(-translation.dx, -translation.dy);
  return MatrixUtils.transformPoint(matrix, point);
}
