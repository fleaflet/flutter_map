import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

part 'visible_segment.dart';

/// Pixel hiker that lists the visible dots to display on the way.
@internal
class DottedPixelHiker extends _PixelHiker {
  /// Standard Dotted Pixel Hiker constructor.
  DottedPixelHiker({
    required super.offsets,
    required super.closePath,
    required super.canvasSize,
    required super.patternFit,
    required super.strokeWidth,
    required double stepLength,
  }) : super(segmentValues: [stepLength]);

  /// Returns all the visible dots.
  List<Offset> getAllVisibleDots() {
    final List<Offset> result = [];

    if (offsets.isEmpty) {
      return result;
    }

    void addVisibleOffset(final Offset offset) {
      if (VisibleSegment.isVisible(offset, canvasSize, strokeWidth)) {
        result.add(offset);
      }
    }

    // side-effect of the first dot
    addVisibleOffset(offsets.first);

    // normal dots
    for (int i = 0; i < offsets.length - 1; i++) {
      final List<Offset>? visibleDots =
          _getVisibleDotList(offsets[i], offsets[i + 1]);
      if (visibleDots != null) {
        result.addAll(visibleDots);
      }
    }
    if (closePath) {
      final List<Offset>? visibleDots =
          _getVisibleDotList(offsets.last, offsets.first);
      if (visibleDots != null) {
        result.addAll(visibleDots);
      }
    }

    // side-effect of the last dot
    if (!closePath) {
      if (patternFit != PatternFit.none) {
        if (result.isEmpty) {
          addVisibleOffset(offsets.last);
        } else {
          final last = result.last;
          if (last != offsets.last) {
            addVisibleOffset(offsets.last);
          }
        }
      }
    }
    return result;
  }

  /// Returns the visible dots between [offset0] and [offset1].
  ///
  /// Most important method of the class.
  List<Offset>? _getVisibleDotList(Offset offset0, Offset offset1) {
    final VisibleSegment? visibleSegment = VisibleSegment.getVisibleSegment(
        offset0, offset1, canvasSize, strokeWidth);
    if (visibleSegment == null) {
      addDistance(getDistance(offset0, offset1));
      return null;
    }
    if (offset0 != visibleSegment.begin) {
      addDistance(getDistance(offset0, visibleSegment.begin));
    }
    Offset start = visibleSegment.begin;
    List<Offset>? result;

    while (true) {
      final Offset offsetIntermediary =
          getIntermediateOffset(start, visibleSegment.end);
      addDistance(_used);
      if (_remaining == segmentValues.first) {
        result ??= [];
        result.add(offsetIntermediary);
        nextSegment();
      }
      if (offsetIntermediary == visibleSegment.end) {
        if (offset1 != visibleSegment.end) {
          addDistance(getDistance(visibleSegment.end, offset1));
        }
        return result;
      }
      start = offsetIntermediary;
    }
  }

  @override
  double getFactor() {
    if (patternFit != PatternFit.scaleDown &&
        patternFit != PatternFit.scaleUp) {
      return 1;
    }

    if (_polylinePixelDistance == 0) {
      return 0;
    }

    final double stepLength = segmentValues.first;
    final double factor = _polylinePixelDistance / stepLength;

    if (patternFit == PatternFit.scaleDown) {
      return (factor.ceil() * stepLength + stepLength) / _polylinePixelDistance;
    }
    return (factor.floor() * stepLength + stepLength) / _polylinePixelDistance;
  }
}

/// Pixel hiker that lists the visible dashed segments to display on the way.
@internal
class DashedPixelHiker extends _PixelHiker {
  /// Standard Dashed Pixel Hiker constructor.
  DashedPixelHiker({
    required super.offsets,
    required super.closePath,
    required super.canvasSize,
    required super.segmentValues,
    required super.patternFit,
    required super.strokeWidth,
  });

  /// Returns all visible segments.
  List<VisibleSegment> getAllVisibleSegments() {
    final List<VisibleSegment> result = [];

    if (offsets.length < 2 ||
        segmentValues.length < 2 ||
        segmentValues.length.isOdd) {
      return result;
    }

    for (int i = 0; i < offsets.length - 1 + (closePath ? 1 : 0); i++) {
      final List<VisibleSegment>? visibleSegments =
          _getVisibleSegmentList(offsets[i], offsets[(i + 1) % offsets.length]);
      if (visibleSegments != null) {
        result.addAll(visibleSegments);
      }
    }

    // last point side-effect, problematic if we're on a space and not a dash
    if (_segmentIndex.isOdd) {
      if (patternFit == PatternFit.appendDot) {
        if (!closePath) {
          if (VisibleSegment.isVisible(offsets.last, canvasSize, strokeWidth)) {
            result.add(VisibleSegment(offsets.last, offsets.last));
          }
        }
      } else if (patternFit == PatternFit.extendFinalDash) {
        final lastOffset = closePath ? offsets.first : offsets.last;
        if (result.isEmpty) {
          if (offsets.length >= 2) {
            final beforeLastOffset =
                offsets[closePath ? offsets.length - 1 : offsets.length - 2];
            result.add(VisibleSegment(beforeLastOffset, lastOffset));
          }
        } else {
          final lastVisible = result.last.end;
          if (lastOffset != lastVisible) {
            result.add(VisibleSegment(lastVisible, lastOffset));
          }
        }
      }
    }

    return result;
  }

  /// Returns the visible segments between [offset0] and [offset1].
  ///
  /// Most important method of the class.
  List<VisibleSegment>? _getVisibleSegmentList(
    final Offset offset0,
    final Offset offset1,
  ) {
    final VisibleSegment? visibleSegment = VisibleSegment.getVisibleSegment(
        offset0, offset1, canvasSize, strokeWidth);
    if (visibleSegment == null) {
      addDistance(getDistance(offset0, offset1));
      return null;
    }
    if (offset0 != visibleSegment.begin) {
      addDistance(getDistance(offset0, visibleSegment.begin));
    }
    Offset start = visibleSegment.begin;
    List<VisibleSegment>? result;

    while (true) {
      final Offset offsetIntermediary =
          getIntermediateOffset(start, visibleSegment.end);
      if (_segmentIndex.isEven) {
        result ??= [];
        result.add(VisibleSegment(start, offsetIntermediary));
      }
      addDistance(_used);
      if (_remaining == 0) {
        nextSegment();
      }
      if (offsetIntermediary == visibleSegment.end) {
        if (offset1 != visibleSegment.end) {
          addDistance(getDistance(visibleSegment.end, offset1));
        }
        return result;
      }
      start = offsetIntermediary;
    }
  }

  /// Returns the factor for offset distances so that the dash pattern fits.
  ///
  /// The idea is that we need to be able to display the dash pattern completely
  /// n times (at least once), plus once the initial dash segment. That's the
  /// way we deal with the "ending" side-effect.
  @override
  double getFactor() {
    if (patternFit != PatternFit.scaleDown &&
        patternFit != PatternFit.scaleUp) {
      return 1;
    }

    if (_polylinePixelDistance == 0) {
      return 0;
    }

    final double firstDashDistance = segmentValues.first;
    final double factor = _polylinePixelDistance / _totalSegmentDistance;
    if (patternFit == PatternFit.scaleDown) {
      return (factor.ceil() * _totalSegmentDistance + firstDashDistance) /
          _polylinePixelDistance;
    }
    return (factor.floor() * _totalSegmentDistance + firstDashDistance) /
        _polylinePixelDistance;
  }
}

/// Pixel hiker that lists the visible solid segments to display on the way.
@internal
class SolidPixelHiker extends _PixelHiker {
  /// Standard Solid Pixel Hiker constructor.
  SolidPixelHiker({
    required super.offsets,
    required super.closePath,
    required super.canvasSize,
    required super.strokeWidth,
  }) : super(
          segmentValues: [],
          patternFit: PatternFit.none,
        );

  /// Adds all visible segments to [paths].
  void addAllVisibleSegments(final List<Path> paths) {
    if (offsets.length < 2) {
      return;
    }

    double? latestX;
    double? latestY;
    List<Offset> polygons = [];

    void addPolygons() {
      if (polygons.isEmpty) {
        return;
      }
      for (final path in paths) {
        path.addPolygon(polygons, false);
      }
      polygons = [];
    }

    for (int i = 0; i < offsets.length - 1 + (closePath ? 1 : 0); i++) {
      final VisibleSegment? visibleSegment = VisibleSegment.getVisibleSegment(
        offsets[i],
        offsets[(i + 1) % offsets.length],
        canvasSize,
        strokeWidth,
      );
      if (visibleSegment == null) {
        continue;
      }
      if (latestX != visibleSegment.begin.dx ||
          latestY != visibleSegment.begin.dy) {
        addPolygons();
        polygons.add(visibleSegment.begin);
      }
      polygons.add(visibleSegment.end);
      latestX = visibleSegment.end.dx;
      latestY = visibleSegment.end.dy;
    }
    addPolygons();
  }

  @override
  double getFactor() => 1;
}

/// Pixel hiker that lists the visible items on the way.
sealed class _PixelHiker {
  _PixelHiker({
    required this.offsets,
    required this.segmentValues,
    required this.closePath,
    required this.canvasSize,
    required this.patternFit,
    required this.strokeWidth,
  }) {
    _polylinePixelDistance = _getPolylinePixelDistance();
    _init();
    _factor = getFactor();
  }

  final List<Offset> offsets;
  final bool closePath;

  /// List of segments' lengths.
  ///
  /// Expected number of items:
  /// * empty for "solid"
  /// * > 0 and even for "dashed": (dash size _ space size) * n
  /// * only 1 item for "dotted": the size of the space
  final List<double> segmentValues;
  final Size canvasSize;
  final PatternFit patternFit;
  final double strokeWidth;

  /// Factor to be used on offset distances.
  late final double _factor;

  late final double _polylinePixelDistance;

  late double _remaining;
  late int _segmentIndex;
  late final double _totalSegmentDistance;
  late double _used;

  /// Returns the factor to apply to offset distances.
  @protected
  double getFactor();

  @protected
  double getDistance(final Offset offset0, final Offset offset1) =>
      _factor * (offset0 - offset1).distance;

  @protected
  void addDistance(double distance) {
    double modulus = distance % _totalSegmentDistance;
    if (modulus == 0) {
      return;
    }
    while (modulus >= _remaining) {
      modulus -= _remaining;
      nextSegment();
    }
    _remaining -= modulus;
  }

  @protected
  void nextSegment() {
    if (segmentValues.isEmpty) {
      return;
    }
    _segmentIndex = (_segmentIndex + 1) % segmentValues.length;
    _remaining = segmentValues[_segmentIndex];
  }

  void _init() {
    _totalSegmentDistance = _getTotalSegmentDistance(segmentValues);
    _segmentIndex = segmentValues.length - 1;
    _remaining = 0;
    nextSegment();
  }

  /// Returns the offset on segment [A,B] that matches the remaining distance.
  @protected
  Offset getIntermediateOffset(final Offset offsetA, final Offset offsetB) {
    final segmentDistance = getDistance(offsetA, offsetB);
    if (segmentValues.isEmpty || _remaining >= segmentDistance) {
      _used = segmentDistance;
      return offsetB;
    }
    final fB = _remaining / segmentDistance;
    final fA = 1.0 - fB;
    _used = _remaining;
    return Offset(
      offsetA.dx * fA + offsetB.dx * fB,
      offsetA.dy * fA + offsetB.dy * fB,
    );
  }

  double _getPolylinePixelDistance() {
    if (offsets.length < 2) {
      return 0;
    }
    double result = 0;
    for (int i = 1; i < offsets.length; i++) {
      final Offset offsetA = offsets[i - 1];
      final Offset offsetB = offsets[i];
      result += (offsetA - offsetB).distance;
    }
    if (closePath) {
      result += (offsets.last - offsets.first).distance;
    }
    return result;
  }

  double _getTotalSegmentDistance(List<double> segmentValues) {
    double result = 0;
    for (final double value in segmentValues) {
      result += value;
    }
    return result;
  }
}
