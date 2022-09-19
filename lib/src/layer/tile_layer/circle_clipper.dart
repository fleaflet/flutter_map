import 'dart:ui';

import 'package:flutter/material.dart';
class CircleClipper extends CustomClipper<Path> {
  final double radius;
  final Offset positionOffset;

  CircleClipper(this.positionOffset, this.radius);

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: positionOffset, radius: radius));
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}