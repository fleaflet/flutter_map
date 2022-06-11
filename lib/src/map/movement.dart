
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong2/latlong.dart';

class Movement {

  static bool alreadyFlying = false;

  // Converted from leaflet.js map.js
  static void flyTo(MapState mapState, LatLng targetCenter,
      { double? zoom,  double? duration }) {

    if(alreadyFlying) return;

    alreadyFlying = true;
    final CustomPoint from = mapState.project(mapState.getCenter());
    final CustomPoint to = mapState.project(targetCenter);
    final CustomPoint size = mapState.size;
    final double startZoom = mapState.zoom;

    final targetZoom = zoom ?? startZoom;

    final w0 = math.max(size.x, size.y);
    final w1 = w0 *
        mapState.getZoomScale(startZoom, targetZoom); // was other way around
    var u1 = to.distanceTo(from);

    if (u1 == 0) {
      u1 = 1;
    }
    const double rho = 1.42;
    const double rho2 = rho * rho;

    double r(int i) {
      final int s1 = i == 1 ? -1 : 1;
      final double s2 = i == 1 ? w1.toDouble() : w0.toDouble();
      final double t1 = w1 * w1 - w0 * w0 + s1 * rho2 * rho2 * u1 * u1;
      final double b1 = 2 * s2 * rho2 * u1;
      final double b = t1 / b1;
      final double sq = math.sqrt(b * b + 1) - b;

      // workaround for floating point precision bug when sq = 0, log = -Infinite,
      // thus triggering an infinite loop in flyTo
      final double log = sq < 0.000000001 ? -18 : math.log(sq);

      return log;
    }

    double sinh(double n) {
      return (math.exp(n) - math.exp(-n)) / 2;
    }
    double cosh(double n) {
      return (math.exp(n) + math.exp(-n)) / 2;
    }
    double tanh(double n) {
      return sinh(n) / cosh(n);
    }

    final double r0 = r(0);

    double w(double s) {
      return w0 * (cosh(r0) / cosh(r0 + rho * s));
    }
    double u(double s) {
      return w0 * (cosh(r0) * tanh(r0 + rho * s) - sinh(r0)) / rho2;
    }

    double easeOut(double t) {
      return 1 - math.pow(1.0 - t, 1.5).toDouble();
    }

    final DateTime start = DateTime.now();
    final double S = (r(1) - r0) / rho;

    duration = duration != null ? 1000 * duration : 1000 * S * 0.8;

    void frame() async {
      final t = DateTime
          .now()
          .difference(start)
          .inMilliseconds / duration!;
      final s = easeOut(t) * S;

      if (t <= 1) {
        final newPos = mapState.unproject(
            from + ((to - from).multiplyBy(u(s) / u1)),
            startZoom); // double check brackets
        final newZoom = mapState.getScaleZoom(w0 / w(s), startZoom);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          mapState.move(
              newPos, newZoom, source: MapEventSource.flingAnimationController);
          frame();
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      } else {
        mapState.move(targetCenter, targetZoom,
            source: MapEventSource.flingAnimationController);
        alreadyFlying = false;
      }
    }

    frame();
  }
}