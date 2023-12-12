import 'dart:core';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/geo/latlng_bounds.dart';
import 'package:flutter_map/src/layer/general/mobile_layer_transformer.dart';
import 'package:flutter_map/src/map/camera/camera.dart';
import 'package:flutter_map/src/misc/offsets.dart';
import 'package:flutter_map/src/misc/point_extensions.dart';
import 'package:latlong2/latlong.dart';

class _LastHit<TapKeyType extends Object> {
  List<Polyline<TapKeyType>>? lines;
  LatLng? point;

  bool get toIgnore => lines == null || point == null;
}

typedef PolylineOnTap = void Function(LatLng point);
typedef PolylineLayerOnTap<TapKeyType extends Object> = void Function(
  List<Polyline<TapKeyType>> lines,
  LatLng point,
)?;

@optionalTypeArgs
class Polyline<TapKeyType extends Object> {
  final List<LatLng> points;
  final double strokeWidth;
  final Color color;
  final double borderStrokeWidth;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<double>? colorsStop;
  final bool isDotted;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final bool useStrokeWidthInMeter;

  /// Called when a tap is detected on this [Polyline]
  ///
  /// See [PolylineLayer.onTap], [PolylineLayer.onTapTolerance],
  /// [PolylineLayer.nonTappablesOcclude], and [PolylineLayer.tappablesOcclude]
  /// for more information.
  final PolylineOnTap? onTap;

  /// Called when a long press is detected on this [Polyline]
  ///
  /// See [PolylineLayer.onLongPress], [PolylineLayer.onTapTolerance],
  /// [PolylineLayer.nonTappablesOcclude], and [PolylineLayer.tappablesOcclude]
  /// for more information.
  final PolylineOnTap? onLongPress;

  /// Called when a secondary tap/alternative click is detected on this
  /// [Polyline]
  ///
  /// See [PolylineLayer.onSecondaryTap], [PolylineLayer.onTapTolerance],
  /// [PolylineLayer.nonTappablesOcclude], and [PolylineLayer.tappablesOcclude]
  /// for more information.
  final PolylineOnTap? onSecondaryTap;

  /// Custom value that identifies this particular [Polyline] when used with
  /// [PolylineLayer.onTap] (and variants) (either instead of or in addition to
  /// [onTap] (and variants))
  ///
  /// When non-null, also indicates this [Polyline] is "interactive" if [onTap]
  /// (and variants) is `null`. ("Tappable" means that either or both of [onTap]
  /// (and variants) and [tapKey] has been defined.)
  final TapKeyType? tapKey;

  LatLngBounds? _boundingBox;

  LatLngBounds get boundingBox =>
      _boundingBox ??= LatLngBounds.fromPoints(points);

  Polyline({
    required this.points,
    this.strokeWidth = 1.0,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
    this.gradientColors,
    this.colorsStop,
    this.isDotted = false,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.useStrokeWidthInMeter = false,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.tapKey,
  });

  /// Used to batch draw calls to the canvas.
  int get renderHashCode => Object.hash(
        strokeWidth,
        color,
        borderStrokeWidth,
        borderColor,
        gradientColors,
        colorsStop,
        isDotted,
        strokeCap,
        strokeJoin,
        useStrokeWidthInMeter,
      );
}

@immutable
@optionalTypeArgs
class PolylineLayer<TapKeyType extends Object> extends StatelessWidget {
  final List<Polyline<TapKeyType>> polylines;

  /// Called when a tap is detected on any [Polyline] with a defined
  /// [Polyline.tapKey]
  ///
  /// Individual [Polyline]s may have their own [Polyline.onTap] callback
  /// defined, regardless of whether this is defined.
  ///
  /// See [nonTappablesOcclude] and [tappablesOcclude] to set behaviour when a
  /// tap is over multiple overlapping [Polyline]s.
  final PolylineLayerOnTap<TapKeyType>? onTap;

  /// Called when a long press is detected on any [Polyline] with a defined
  /// [Polyline.tapKey]
  ///
  /// Individual [Polyline]s may have their own [Polyline.onLongPress] callback
  /// defined, regardless of whether this is defined.
  ///
  /// See [nonTappablesOcclude] and [tappablesOcclude] to set behaviour when a
  /// tap is over multiple overlapping [Polyline]s.
  final PolylineLayerOnTap<TapKeyType>? onLongPress;

  /// Called when a secondary tap/alternative click is detected on any [Polyline]
  /// with a defined [Polyline.tapKey]
  ///
  /// Individual [Polyline]s may have their own [Polyline.onSecondaryTap]
  /// callback defined, regardless of whether this is defined.
  ///
  /// See [nonTappablesOcclude] and [tappablesOcclude] to set behaviour when a
  /// tap is over multiple overlapping [Polyline]s.
  final PolylineLayerOnTap<TapKeyType>? onSecondaryTap;

  /// The number of pixels away from the visual line (including any width and
  /// outline) in which a tap should still register as a tap on the line
  ///
  /// Applies to both [onTap] and every [Polyline.onTap] (and variants).
  ///
  /// Defaults to 3.
  final double onTapTolerance;

  /// Whether a non-tappable [Polyline] should prevent taps from being handled
  /// on all [Polyline]s beneath it, at overlaps
  ///
  /// "Tappable" means that either or both of [Polyline.onTap] (and variants) and
  /// [Polyline.tapKey] has been defined.
  ///
  /// Applies to both [onTap] and every [Polyline.onTap] (and variants).
  ///
  /// Defaults to `true`.
  final bool nonTappablesOcclude;

  /// Whether a tappable [Polyline] should prevent taps from being handled
  /// on all [Polyline]s beneath it, at overlaps
  ///
  /// "Tappable" means that either or both of [Polyline.onTap] (and variants) and
  /// [Polyline.tapKey] has been defined.
  ///
  /// If `true`, then [onTap] becomes redundant to [Polyline.onTap]
  /// (and variants).
  ///
  /// Defaults to `false`.
  final bool tappablesOcclude;

  const PolylineLayer({
    super.key,
    required this.polylines,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onTapTolerance = 3,
    this.tappablesOcclude = false,
    this.nonTappablesOcclude = true,
    // TODO: Remove once PR #1704 is merged
    bool polylineCulling = true,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    bool interactive =
        onTap != null || onLongPress != null || onSecondaryTap != null;
    final lastHit = _LastHit<TapKeyType>();

    final culledPolylines = <Polyline<TapKeyType>>[];
    for (final line in polylines) {
      if (!line.boundingBox.isOverlapping(camera.visibleBounds)) continue;
      if (!interactive && line.onTap != null) interactive = true;
      culledPolylines.add(line);
    }

    final paint = CustomPaint(
      painter: _PolylinePainter<TapKeyType>(
        polylines: culledPolylines,
        camera: camera,
        lastHit: interactive ? lastHit : null,
        onTapTolerance: onTapTolerance,
        tappablesOcclude: tappablesOcclude,
        nonTappablesOcclude: nonTappablesOcclude,
      ),
      size: Size(camera.size.x, camera.size.y),
      isComplex: true,
    );

    return MobileLayerTransformer(
      child: interactive
          ? MouseRegion(
              hitTestBehavior: HitTestBehavior.deferToChild,
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (lastHit.toIgnore) return;

                  for (final polyline in lastHit.lines!) {
                    polyline.onTap?.call(lastHit.point!);
                  }
                  onTap?.call(lastHit.lines!, lastHit.point!);
                },
                onLongPress: () {
                  if (lastHit.toIgnore) return;

                  for (final polyline in lastHit.lines!) {
                    polyline.onLongPress?.call(lastHit.point!);
                  }
                  onLongPress?.call(lastHit.lines!, lastHit.point!);
                },
                onSecondaryTap: () {
                  if (lastHit.toIgnore) return;

                  for (final polyline in lastHit.lines!) {
                    polyline.onSecondaryTap?.call(lastHit.point!);
                  }
                  onSecondaryTap?.call(lastHit.lines!, lastHit.point!);
                },
                child: paint,
              ),
            )
          : paint,
    );
  }
}

class _PolylinePainter<TapKeyType extends Object> extends CustomPainter {
  final List<Polyline<TapKeyType>> polylines;
  final MapCamera camera;
  final LatLngBounds bounds;
  final _LastHit? lastHit;
  final double onTapTolerance;
  final bool tappablesOcclude;
  final bool nonTappablesOcclude;

  _PolylinePainter({
    required this.polylines,
    required this.camera,
    required this.lastHit,
    required this.onTapTolerance,
    required this.tappablesOcclude,
    required this.nonTappablesOcclude,
  }) : bounds = camera.visibleBounds;

  int get hash => _hash ??= Object.hashAll(polylines);

  int? _hash;

  @override
  bool? hitTest(Offset position) {
    if (lastHit == null) return null;

    final hits = <Polyline<TapKeyType>>[];
    final origin =
        camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

    outer:
    for (final p in polylines.reversed) {
      // TODO: For efficiency we'd ideally filter by bounding box here. However
      // we'd need to compute an extended bounding box that accounts account for
      // the stroke width.
      // if (!p.boundingBox.contains(touch)) {
      //   continue;
      // }

      final offsets = getOffsets(camera, origin, p.points);
      final strokeWidth = p.useStrokeWidthInMeter
          ? _metersToStrokeWidth(
              origin,
              p.points.first,
              offsets.first,
              p.strokeWidth,
            )
          : p.strokeWidth;
      final maxDistance =
          (strokeWidth / 2 + p.borderStrokeWidth / 2) + onTapTolerance;

      for (int i = 0; i < offsets.length - 1; i++) {
        final o1 = offsets[i];
        final o2 = offsets[i + 1];

        final distance = math.sqrt(_distToSegmentSquared(
          position.dx,
          position.dy,
          o1.dx,
          o1.dy,
          o2.dx,
          o2.dy,
        ));

        if (distance < maxDistance) {
          if (nonTappablesOcclude &&
              p.onTap == null &&
              p.onLongPress == null &&
              p.onSecondaryTap == null &&
              p.tapKey == null) {
            break outer;
          }
          hits.add(p);
          if (tappablesOcclude) break outer;
          break;
        }
      }
    }

    if (hits.isEmpty) return false;

    lastHit!
      ..lines = hits
      ..point = camera.pointToLatLng(math.Point(position.dx, position.dy));

    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    var path = ui.Path();
    var borderPath = ui.Path();
    var filterPath = ui.Path();
    var paint = Paint();
    var needsLayerSaving = false;

    Paint? borderPaint;
    Paint? filterPaint;
    int? lastHash;

    void drawPaths() {
      final hasBorder = borderPaint != null && filterPaint != null;
      if (hasBorder) {
        if (needsLayerSaving) {
          canvas.saveLayer(rect, Paint());
        }

        canvas.drawPath(borderPath, borderPaint!);
        borderPath = ui.Path();
        borderPaint = null;

        if (needsLayerSaving) {
          canvas.drawPath(filterPath, filterPaint!);
          filterPath = ui.Path();
          filterPaint = null;

          canvas.restore();
        }
      }

      canvas.drawPath(path, paint);
      path = ui.Path();
      paint = Paint();
    }

    final origin =
        camera.project(camera.center).toOffset() - camera.size.toOffset() / 2;

    for (final polyline in polylines) {
      final offsets = getOffsets(camera, origin, polyline.points);
      if (offsets.isEmpty) {
        continue;
      }

      final hash = polyline.renderHashCode;
      if (needsLayerSaving || (lastHash != null && lastHash != hash)) {
        drawPaths();
      }
      lastHash = hash;
      needsLayerSaving = polyline.color.opacity < 1.0 ||
          (polyline.gradientColors?.any((c) => c.opacity < 1.0) ?? false);

      late final double strokeWidth;
      if (polyline.useStrokeWidthInMeter) {
        strokeWidth = _metersToStrokeWidth(
          origin,
          polyline.points.first,
          offsets.first,
          polyline.strokeWidth,
        );
      } else {
        strokeWidth = polyline.strokeWidth;
      }

      final isDotted = polyline.isDotted;
      paint = Paint()
        ..strokeWidth = strokeWidth
        ..strokeCap = polyline.strokeCap
        ..strokeJoin = polyline.strokeJoin
        ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver;

      if (polyline.gradientColors == null) {
        paint.color = polyline.color;
      } else {
        polyline.gradientColors!.isNotEmpty
            ? paint.shader = _paintGradient(polyline, offsets)
            : paint.color = polyline.color;
      }

      if (polyline.borderColor != null && polyline.borderStrokeWidth > 0.0) {
        // Outlined lines are drawn by drawing a thicker path underneath, then
        // stenciling the middle (in case the line fill is transparent), and
        // finally drawing the line fill.
        borderPaint = Paint()
          ..color = polyline.borderColor ?? const Color(0x00000000)
          ..strokeWidth = strokeWidth + polyline.borderStrokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
          ..blendMode = BlendMode.srcOver;

        filterPaint = Paint()
          ..color = polyline.borderColor!.withAlpha(255)
          ..strokeWidth = strokeWidth
          ..strokeCap = polyline.strokeCap
          ..strokeJoin = polyline.strokeJoin
          ..style = isDotted ? PaintingStyle.fill : PaintingStyle.stroke
          ..blendMode = BlendMode.dstOut;
      }

      final radius = paint.strokeWidth / 2;
      final borderRadius = (borderPaint?.strokeWidth ?? 0) / 2;

      if (isDotted) {
        final spacing = strokeWidth * 1.5;
        if (borderPaint != null && filterPaint != null) {
          _paintDottedLine(borderPath, offsets, borderRadius, spacing);
          _paintDottedLine(filterPath, offsets, radius, spacing);
        }
        _paintDottedLine(path, offsets, radius, spacing);
      } else {
        if (borderPaint != null && filterPaint != null) {
          _paintLine(borderPath, offsets);
          _paintLine(filterPath, offsets);
        }
        _paintLine(path, offsets);
      }
    }

    drawPaths();
  }

  void _paintDottedLine(
      ui.Path path, List<Offset> offsets, double radius, double stepLength) {
    var startDistance = 0.0;
    for (var i = 0; i < offsets.length - 1; i++) {
      final o0 = offsets[i];
      final o1 = offsets[i + 1];
      final totalDistance = (o0 - o1).distance;
      var distance = startDistance;
      while (distance < totalDistance) {
        final f1 = distance / totalDistance;
        final f0 = 1.0 - f1;
        final offset = Offset(o0.dx * f0 + o1.dx * f1, o0.dy * f0 + o1.dy * f1);
        path.addOval(Rect.fromCircle(center: offset, radius: radius));
        distance += stepLength;
      }
      startDistance = distance < totalDistance
          ? stepLength - (totalDistance - distance)
          : distance - totalDistance;
    }
    path.addOval(Rect.fromCircle(center: offsets.last, radius: radius));
  }

  void _paintLine(ui.Path path, List<Offset> offsets) {
    if (offsets.isEmpty) {
      return;
    }
    path.addPolygon(offsets, false);
  }

  ui.Gradient _paintGradient(Polyline polyline, List<Offset> offsets) =>
      ui.Gradient.linear(offsets.first, offsets.last, polyline.gradientColors!,
          _getColorsStop(polyline));

  List<double>? _getColorsStop(Polyline polyline) =>
      (polyline.colorsStop != null &&
              polyline.colorsStop!.length == polyline.gradientColors!.length)
          ? polyline.colorsStop
          : _calculateColorsStop(polyline);

  List<double> _calculateColorsStop(Polyline polyline) {
    final colorsStopInterval = 1.0 / polyline.gradientColors!.length;
    return polyline.gradientColors!
        .map((gradientColor) =>
            polyline.gradientColors!.indexOf(gradientColor) *
            colorsStopInterval)
        .toList();
  }

  double _metersToStrokeWidth(
    Offset origin,
    LatLng p0,
    Offset o0,
    double strokeWidthInMeters,
  ) {
    final r = _distance.offset(p0, strokeWidthInMeters, 180);
    final delta = o0 - getOffset(camera, origin, r);
    return delta.distance;
  }

  @override
  bool shouldRepaint(_PolylinePainter oldDelegate) {
    return oldDelegate.bounds != bounds ||
        oldDelegate.polylines.length != polylines.length ||
        oldDelegate.hash != hash;
  }
}

double _distanceSq(double x0, double y0, double x1, double y1) {
  final dx = x0 - x1;
  final dy = y0 - y1;
  return dx * dx + dy * dy;
}

double _distToSegmentSquared(
  double px,
  double py,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  final dx = x1 - x0;
  final dy = y1 - y0;
  final distanceSq = dx * dx + dy * dy;
  if (distanceSq == 0) {
    return _distanceSq(px, py, x0, y0);
  }

  final t = (((px - x0) * dx + (py - y0) * dy) / distanceSq).clamp(0, 1);
  return _distanceSq(px, py, x0 + t * dx, y0 + t * dy);
}

const _distance = Distance();
