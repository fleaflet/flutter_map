import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:flutter_map/src/misc/deg_rad_conversions.dart';
import 'package:flutter_map/src/misc/extensions.dart';
import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Describes the view of a map. This includes the size/zoom/position/crs as
/// well as the minimum/maximum zoom. This class is mostly immutable but has
/// some fields that get calculated lazily, changes to the map view may occur
/// via the [MapController] or user interactions which will result in a
/// new [MapCamera] value.
class MapCamera {
  /// During Flutter startup the native platform resolution is not immediately
  /// available which can cause constraints to be zero before they are updated
  /// in a subsequent build to the actual constraints. We set the size to this
  /// impossible (negative) value initially and only change it once Flutter
  /// provides real constraints.
  static const kImpossibleSize =
      Size(double.negativeInfinity, double.negativeInfinity);

  /// The used coordinate reference system
  final Crs crs;

  /// The minimum allowed zoom level.
  final double? minZoom;

  /// The maximum allowed zoom level.
  final double? maxZoom;

  /// The [LatLng] which corresponds with the center of this camera.
  final LatLng center;

  /// How far zoomed this camera is.
  final double zoom;

  /// The rotation, in degrees, of the camera. See [rotationRad] for the same
  /// value in radians.
  final double rotation;

  /// The size of the map view ignoring rotation. This will be the size of the
  /// FlutterMap widget.
  final Size nonRotatedSize;

  /// The pitch, in degrees: the angle between the camera's view direction and
  /// straight down. See [pitchRad] for the same value in radians.
  ///
  /// [zoom] is the scale at [center], so a change of pitch doesn't change it.
  final double pitch;

  /// The vertical field of view of a pitched camera, in radians. This is
  /// MapLibre Native's default, so that a pitched map rendered by MapLibre and
  /// this camera's projection agree.
  static const fieldOfView = 0.6435011087932844;

  /// Lazily calculated field
  Matrix4? _pixelToScreenTransform;

  /// Lazily calculated field
  Rect? _footprintFromCenter;

  /// Lazily calculated field
  Size? _cameraSize;

  /// Lazily calculated field
  Rect? _pixelBounds;

  /// Lazily calculated field
  LatLngBounds? _bounds;

  /// Lazily calculated field
  Offset? _pixelOrigin;

  /// This is the [LatLngBounds] corresponding to four corners of this camera.
  /// This takes rotation into account.
  LatLngBounds get visibleBounds => _bounds ??= _computeVisibleBounds();

  LatLngBounds _computeVisibleBounds() {
    final bottomLeft = unprojectAtZoom(pixelBounds.bottomLeft, zoom);
    final topRight = unprojectAtZoom(pixelBounds.topRight, zoom);
    final worldWidth = getWorldWidthAtZoom(zoom);
    if (worldWidth == 0) {
      return LatLngBounds(bottomLeft, topRight);
    }
    final center = unprojectAtZoom(pixelBounds.center, zoom);
    return LatLngBounds.worldSafe(
      south: bottomLeft.latitude,
      north: topRight.latitude,
      longitudeWidth: pixelBounds.width * 360 / worldWidth,
      longitudeCenter: center.longitude,
    );
  }

  /// The size of bounding box of this camera taking in to account its
  /// rotation. When the rotation is zero this will equal [nonRotatedSize],
  /// otherwise it will be the size of the rectangle which contains this
  /// camera.
  ///
  /// When the map is pitched, this is the size of the rectangle, in projected
  /// pixels at [zoom], which contains the ground visible in the map view.
  Size get size => _cameraSize ??= pitch == 0
      ? calculateRotatedSize(rotation, nonRotatedSize)
      : _footprint.size;

  /// The offset of the top-left corner of the bounding rectangle of this
  /// camera. This will not equal the offset of the top-left visible pixel when
  /// the map is rotated.
  /* (jaffaketchup) This is used for painters & hit testing extensively. We want
     to convert [position], which is in the canvas' coordinate space to a
     [coordinate]. See `screenOffsetToLatLng` - it uses `nonRotatedSize` then
     does more rotations after. We don't want to do this. So we copy the
     implementation, and replace/remove the necessary parts, resulting in the
     code below.

      final pointCenterDistance = camera.size.center(Offset.zero) - position;
      final a = camera.crs.latLngToOffset(camera.center, camera.zoom);
      final coordinate = camera.crs.offsetToLatLng(
        a - pointCenterDistance,
        camera.zoom,
      );
     
     `camera.crs.latLngToOffset` is longhand for `projectAtZoom`. So we have
     `a - (b - c)`, where `c` is [position]. This is equivalent to `(a - b) + c`.
     `(a - b)` is this.

     This was provided in [FeatureLayerUtils.origin] for a few versions. It has
     been removed, because this exists, so I'm not sure why it needed to be
     duplicated. See [HitDetectablePainter.hitTest] for an easy usage example.
  */
  ///
  /// When the map is pitched, this is the top-left corner of the rectangle
  /// described by [size], which is not centered on [center].
  Offset get pixelOrigin => _pixelOrigin ??= pitch == 0
      ? projectAtZoom(center, zoom) - size.center(Offset.zero)
      : _footprint.topLeft;

  /// The camera of the closest [FlutterMap] ancestor. If this is called from a
  /// context with no [FlutterMap] ancestor null, is returned.
  static MapCamera? maybeOf(BuildContext context) =>
      MapInheritedModel.maybeCameraOf(context);

  /// The camera of the closest [FlutterMap] ancestor. If this is called from a
  /// context with no [FlutterMap] ancestor a [StateError] will be thrown.
  static MapCamera of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`MapCamera.of()` should not be called outside a `FlutterMap` and its descendants'));

  /// Create an instance of [MapCamera]. The [pixelOrigin], [bounds], and
  /// [pixelBounds] may be set if they are known already. Otherwise if left
  /// null they will be calculated lazily when they are used.
  MapCamera({
    required this.crs,
    required this.center,
    required this.zoom,
    required this.rotation,
    required this.nonRotatedSize,
    this.pitch = 0,
    this.minZoom,
    this.maxZoom,
    Size? size,
    Rect? pixelBounds,
    LatLngBounds? bounds,
    Offset? pixelOrigin,
  })  : _cameraSize = size,
        _pixelBounds = pixelBounds,
        _bounds = bounds,
        _pixelOrigin = pixelOrigin,
        assert(
          zoom.isFinite,
          'Camera `zoom` must be finite (and usually positive).\n'
          '(This may occur if the map tried to fit to a zero-area bounds, such '
          'as a bounds defined by only a single point.)',
        );

  /// Initializes [MapCamera] from the given [options] and with the
  /// [nonRotatedSize] set to [kImpossibleSize].
  MapCamera.initialCamera(MapOptions options)
      : this(
          crs: options.crs,
          minZoom: options.minZoom,
          maxZoom: options.maxZoom,
          center: options.initialCenter,
          zoom: options.initialZoom,
          rotation: options.initialRotation,
          pitch: options.clampPitch(options.initialPitch),
          nonRotatedSize: kImpossibleSize,
        );

  /// Returns a new instance of [MapCamera] with the given [nonRotatedSize].
  MapCamera withNonRotatedSize(Size nonRotatedSize) {
    if (nonRotatedSize == this.nonRotatedSize) return this;

    return MapCamera(
      crs: crs,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
      pitch: pitch,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// Returns a new instance of [MapCamera] with the given [rotation].
  MapCamera withRotation(double rotation) {
    if (rotation == this.rotation) return this;

    return MapCamera(
      crs: crs,
      center: center,
      zoom: zoom,
      nonRotatedSize: nonRotatedSize,
      rotation: rotation,
      pitch: pitch,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// Returns a new instance of [MapCamera] with the given [pitch].
  MapCamera withPitch(double pitch) {
    if (pitch == this.pitch) return this;

    return MapCamera(
      crs: crs,
      center: center,
      zoom: zoom,
      nonRotatedSize: nonRotatedSize,
      rotation: rotation,
      pitch: pitch,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// Returns a new instance of [MapCamera] with the given [options].
  MapCamera withOptions(MapOptions options) {
    final pitch = options.clampPitch(this.pitch);
    if (options.crs == crs &&
        options.minZoom == minZoom &&
        options.maxZoom == maxZoom &&
        pitch == this.pitch) {
      return this;
    }

    return MapCamera(
      crs: options.crs,
      minZoom: options.minZoom,
      maxZoom: options.maxZoom,
      center: center,
      zoom: zoom,
      rotation: rotation,
      nonRotatedSize: nonRotatedSize,
      pitch: pitch,
      size: pitch == this.pitch ? _cameraSize : null,
    );
  }

  /// Returns a new instance of [MapCamera] with the given [center]/[zoom].
  MapCamera withPosition({
    LatLng? center,
    double? zoom,
  }) =>
      MapCamera(
        crs: crs,
        minZoom: minZoom,
        maxZoom: maxZoom,
        center: _adjustPositionForSeamlessScrolling(center),
        zoom: zoom ?? this.zoom,
        rotation: rotation,
        nonRotatedSize: nonRotatedSize,
        pitch: pitch,
        size: _cameraSize,
      );

  /// Jumps camera to opposite side of the world to enable seamless scrolling
  /// between 180 and -180 longitude.
  LatLng _adjustPositionForSeamlessScrolling(LatLng? position) {
    if (!crs.replicatesWorldLongitude) {
      return position ?? center;
    }
    if (position == null) {
      return center;
    }
    double adjustedLongitude = position.longitude;
    if (adjustedLongitude >= 180.0) {
      adjustedLongitude -= 360.0;
    } else if (adjustedLongitude <= -180.0) {
      adjustedLongitude += 360.0;
    }
    return adjustedLongitude == position.longitude
        ? position
        : LatLng(position.latitude, adjustedLongitude);
  }

  /// Calculates the size of a bounding box which surrounds a box of size
  /// [nonRotatedSize] which is rotated by [rotation].
  static Size calculateRotatedSize(
    double rotation,
    Size nonRotatedSize,
  ) {
    if (rotation == 0.0) return nonRotatedSize;

    final rotationRad = degrees2Radians * rotation;
    final cosAngle = math.cos(rotationRad).abs();
    final sinAngle = math.sin(rotationRad).abs();
    final width =
        (nonRotatedSize.width * cosAngle) + (nonRotatedSize.height * sinAngle);
    final height =
        (nonRotatedSize.height * cosAngle) + (nonRotatedSize.width * sinAngle);

    return Size(width, height);
  }

  /// The current rotation value in radians
  double get rotationRad => rotation * degrees2Radians;

  /// The current pitch value in radians
  double get pitchRad => pitch * degrees2Radians;

  /// The distance, in pixels, from the camera to [center].
  double get _cameraDistance =>
      0.5 * nonRotatedSize.height / math.tan(fieldOfView / 2);

  /// The transform from projected pixels at [zoom] (see [projectAtZoom]) to
  /// positions in the map view, including rotation and pitch.
  ///
  /// The translation of a point projected at high zoom is large, so combine
  /// this with other transforms in 64-bit arithmetic before passing it to a
  /// widget, which may use 32-bit floats.
  Matrix4 get pixelToScreenTransform => _pixelToScreen.clone();

  Matrix4 get _pixelToScreen =>
      _pixelToScreenTransform ??= _computePixelToScreenTransform();

  Matrix4 _computePixelToScreenTransform() {
    final projectedCenter = projectAtZoom(center);
    return Matrix4.identity()
      ..multiply(Matrix4.translationValues(
          nonRotatedSize.width / 2, nonRotatedSize.height / 2, 0))
      ..multiply(Matrix4.identity()..setEntry(3, 2, -1 / _cameraDistance))
      ..rotateX(pitchRad)
      ..rotateZ(rotationRad)
      ..multiply(Matrix4.translationValues(
          -projectedCenter.dx, -projectedCenter.dy, 0));
  }

  /// Calculates point value for the given [latlng] using this camera's
  /// [crs] and [zoom] (or the provided [zoom]).
  Offset projectAtZoom(LatLng latlng, [double? zoom]) =>
      crs.latLngToOffset(latlng, zoom ?? this.zoom);

  /// Calculates the [LatLng] for the given [point] using this camera's
  /// [crs] and [zoom] (or the provided [zoom]).
  LatLng unprojectAtZoom(Offset point, [double? zoom]) =>
      crs.offsetToLatLng(point, zoom ?? this.zoom);

  /// Returns the width of the world at the current zoom, or 0 if irrelevant.
  double getWorldWidthAtZoom([double? zoom]) {
    if (!crs.replicatesWorldLongitude) {
      return 0;
    }
    final offset0 = projectAtZoom(const LatLng(0, 0), zoom ?? this.zoom);
    final offset180 = projectAtZoom(const LatLng(0, 180), zoom ?? this.zoom);
    return 2 * (offset180.dx - offset0.dx).abs();
  }

  /// Calculates the scale for a zoom from [fromZoom] to [toZoom] using this
  /// camera\s [crs].
  double getZoomScale(double toZoom, double fromZoom) =>
      crs.scale(toZoom) / crs.scale(fromZoom);

  /// Calculates the scale for this camera's [zoom].
  double getScaleZoom(double scale) => crs.zoom(scale * crs.scale(zoom));

  /// Calculates the pixel bounds of this camera's [crs].
  Rect? getPixelWorldBounds(double? zoom) =>
      crs.getProjectedBounds(zoom ?? this.zoom);

  /// Calculates the [Offset] from the [pos] to this camera's [pixelOrigin].
  Offset getOffsetFromOrigin(LatLng pos) => projectAtZoom(pos) - pixelOrigin;

  /// Calculates the pixel origin of this [MapCamera] at the given
  /// [center]/[zoom].
  Offset getNewPixelOrigin(LatLng center, [double? zoom]) {
    if (pitch == 0) {
      return (projectAtZoom(center, zoom) - size.center(Offset.zero)).round();
    }
    return (projectAtZoom(center, zoom) + _visibleGroundFromCenter.topLeft)
        .round();
  }

  /// Calculates the pixel bounds of this [MapCamera]. This value is cached.
  Rect get pixelBounds =>
      _pixelBounds ?? (_pixelBounds = pixelBoundsAtZoom(zoom));

  /// Calculates the pixel bounds of this [MapCamera] at the given [zoom].
  Rect pixelBoundsAtZoom(double zoom) {
    if (pitch != 0) {
      final scale = getZoomScale(zoom, this.zoom);
      final fromCenter = _visibleGroundFromCenter;
      return Rect.fromPoints(
              fromCenter.topLeft * scale, fromCenter.bottomRight * scale)
          .shift(projectAtZoom(center, zoom));
    }
    Size cameraSize = size;
    if (zoom != this.zoom) {
      final scale = getZoomScale(this.zoom, zoom);
      cameraSize = size / (scale * 2);
    }
    final pixelCenter = projectAtZoom(center, zoom).floor();

    return Rect.fromCenter(
        center: pixelCenter,
        width: cameraSize.width,
        height: cameraSize.height);
  }

  /// This will convert a latLng to a position that we could use with a widget
  /// outside of FlutterMap layer space. Eg using a Positioned Widget.
  Offset latLngToScreenOffset(LatLng latLng) =>
      MatrixUtils.transformPoint(_pixelToScreen, projectAtZoom(latLng));

  /// Calculate the [LatLng] coordinates for a [offset].
  ///
  /// When the map is pitched and [offset] is above the far limit of the
  /// visible ground, there is no visible ground at [offset]; this returns the
  /// coordinate on the far limit directly below [offset] instead.
  /// [maybeScreenOffsetToLatLng] returns null there.
  LatLng screenOffsetToLatLng(Offset offset) =>
      unprojectAtZoom(_screenToPixel(offset, clampToFarLimit: true)!);

  /// Calculate the [LatLng] coordinates for a [offset], or null when the map
  /// is pitched and [offset] is above the far limit of the visible ground.
  /// The far limit is where the view ray is 89.25 degrees from straight down,
  /// just below the horizon.
  LatLng? maybeScreenOffsetToLatLng(Offset offset) {
    final pixel = _screenToPixel(offset, clampToFarLimit: false);
    return pixel == null ? null : unprojectAtZoom(pixel);
  }

  /// The rectangle, in projected pixels at [zoom], which contains the ground
  /// visible in the map view.
  Rect get _footprint =>
      _visibleGroundFromCenter.shift(projectAtZoom(center, zoom));

  /// [_footprint] relative to the projected [center]. It depends only on
  /// [nonRotatedSize], [rotation] and [pitch], because [zoom] is the scale at
  /// [center].
  Rect get _visibleGroundFromCenter => _footprintFromCenter ??= () {
        final corners = visibleGroundFromCenter;
        return Rect.fromLTRB(
          corners.map((c) => c.dx).reduce(math.min),
          corners.map((c) => c.dy).reduce(math.min),
          corners.map((c) => c.dx).reduce(math.max),
          corners.map((c) => c.dy).reduce(math.max),
        );
      }();

  /// The angle from straight down of the view ray at the far limit of the
  /// visible ground, as in MapLibre Native.
  static const _farLimitAngle = 89.25 * degrees2Radians;

  /// The y position in the map view, before rotation, of the far limit of the
  /// visible ground: ground points whose view ray is [_farLimitAngle] from
  /// straight down. It is above the map view, and may be negative infinity,
  /// unless [pitch] is above about 70.8 degrees.
  @internal
  double get farLimit => pitch == 0
      ? double.negativeInfinity
      : nonRotatedSize.height / 2 -
          _cameraDistance * math.tan(_farLimitAngle - pitchRad);

  /// The part of the map view, before rotation, that shows ground: the map
  /// view, with its top moved down to [farLimit] when [farLimit] is in it.
  @internal
  Rect get groundViewport => Rect.fromLTRB(
        0,
        math.max(0, farLimit),
        nonRotatedSize.width,
        nonRotatedSize.height,
      );

  /// The ground under the corners of [groundViewport], clockwise from the
  /// top-left, as offsets in projected pixels at [zoom] from [center].
  @internal
  List<Offset> get visibleGroundFromCenter {
    final viewport = groundViewport;
    return [
      viewport.topLeft,
      viewport.topRight,
      viewport.bottomRight,
      viewport.bottomLeft,
    ].map(clampedGroundOffsetFromCenter).toList();
  }

  /// The projected pixel at [zoom] of the ground point under the screen
  /// position [offset]. See [_groundFromCenter].
  Offset? _screenToPixel(Offset offset, {required bool clampToFarLimit}) {
    final fromCenter =
        _groundFromCenter(offset, clampToFarLimit: clampToFarLimit);
    return fromCenter == null ? null : projectAtZoom(center) + fromCenter;
  }

  /// The offset, in projected pixels at [zoom], from [center] to the ground
  /// point under the screen position [offset], or null above [farLimit].
  @internal
  Offset? groundOffsetFromCenter(Offset offset) =>
      _groundFromCenter(offset, clampToFarLimit: false);

  /// As [groundOffsetFromCenter], but above [farLimit] uses the position on
  /// [farLimit] directly below [offset].
  @internal
  Offset clampedGroundOffsetFromCenter(Offset offset) =>
      _groundFromCenter(offset, clampToFarLimit: true)!;

  /// The size on screen of one projected pixel at the ground point [offset]
  /// from [center], where [offset] is in projected pixels at [zoom]. It is 1 at
  /// [center] and on an unpitched map.
  @internal
  double groundScale(Offset offset) {
    if (pitch == 0) return 1;
    final depth =
        _cameraDistance - offset.rotate(-rotationRad).dy * math.sin(pitchRad);
    return _cameraDistance / depth;
  }

  /// The offset, in projected pixels at [zoom], from [center] to the ground
  /// point under the screen position [offset], found by casting the view ray
  /// to the ground. Above [farLimit], uses the position on [farLimit] directly
  /// below [offset] if [clampToFarLimit], or returns null otherwise.
  ///
  /// The result doesn't depend on [center] or [zoom], because [zoom] is the
  /// scale at [center].
  Offset? _groundFromCenter(Offset offset, {required bool clampToFarLimit}) {
    final farLimit = this.farLimit;
    final belowFarLimit = offset.dy >= farLimit
        ? offset
        : clampToFarLimit
            ? Offset(offset.dx, farLimit)
            : null;
    if (belowFarLimit == null) return null;
    final fromCenter = belowFarLimit - nonRotatedSize.center(Offset.zero);
    final sinPitch = math.sin(pitchRad);
    final divisor =
        math.cos(pitchRad) + fromCenter.dy * sinPitch / _cameraDistance;
    final y = fromCenter.dy / divisor;
    final x = fromCenter.dx * (1 - y * sinPitch / _cameraDistance);
    return Offset(x, y).rotate(rotationRad);
  }

  /// Sometimes we need to make allowances that a rotation already exists, so
  /// it needs to be reversed (pointToLatLng), and sometimes we want to use
  /// the same rotation to create a new position (latLngToScreenpoint).
  /// counterRotation just makes allowances this for this.
  ///
  /// This ignores [pitch]; [latLngToScreenOffset] and [screenOffsetToLatLng]
  /// convert positions on a pitched map.
  Offset rotatePoint(
    Offset mapCenter,
    Offset point, {
    bool counterRotation = true,
  }) {
    //TODO what is the difference between this and the extension method on Offset.rotate?????!?!?!
    final counterRotationFactor = counterRotation ? -1 : 1;

    final m = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(mapCenter.dx, mapCenter.dy)
      ..rotateZ(rotationRad * counterRotationFactor)
      // ignore: deprecated_member_use
      ..translate(-mapCenter.dx, -mapCenter.dy);

    return MatrixUtils.transformPoint(m, point);
  }

  /// Clamps the provided [zoom] to the range specified by [minZoom] and
  /// [maxZoom], if set.
  double clampZoom(double zoom) => zoom.clamp(
        minZoom ?? double.negativeInfinity,
        maxZoom ?? double.infinity,
      );

  /// Calculate the [LatLng] coordinates for a given [Offset] and an optional
  /// zoom level. If [zoom] is not provided the current zoom level of the
  /// [MapCamera] gets used.
  ///
  /// When the map is pitched and [offset] is above the far limit of the
  /// visible ground, this returns the coordinate on the far limit directly
  /// below [offset].
  LatLng offsetToCrs(Offset offset, [double? zoom]) {
    final focalStartPt = projectAtZoom(center, zoom ?? this.zoom);
    final point = _groundFromCenter(offset, clampToFarLimit: true)!;

    final newCenterPt = focalStartPt + point;
    final worldWidth = getWorldWidthAtZoom(zoom ?? this.zoom);
    double bestX = newCenterPt.dx;
    if (worldWidth != 0) {
      while (bestX > worldWidth) {
        bestX -= worldWidth;
      }
      while (bestX < 0) {
        bestX += worldWidth;
      }
    }
    return unprojectAtZoom(Offset(bestX, newCenterPt.dy), zoom ?? this.zoom);
  }

  /// Calculate the center point which would keep the same point of the map
  /// visible at the given [cursorPos] with the zoom set to [zoom].
  ///
  /// When the map is pitched and [cursorPos] is above the far limit of the
  /// visible ground, this keeps the point on the far limit directly below
  /// [cursorPos] instead.
  LatLng focusedZoomCenter(Offset cursorPos, double zoom) {
    final offset = clampedGroundOffsetFromCenter(cursorPos);
    // Match new center coordinate to mouse cursor position
    final scale = getZoomScale(zoom, this.zoom);
    final newOffset = offset * (1.0 - 1.0 / scale);
    final mapCenter = projectAtZoom(center);
    final newCenter = unprojectAtZoom(mapCenter + newOffset);
    return newCenter;
  }

  @override
  int get hashCode => Object.hash(
      crs, minZoom, maxZoom, center, zoom, rotation, nonRotatedSize, pitch);

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      (other is MapCamera &&
          other.crs == crs &&
          other.minZoom == minZoom &&
          other.maxZoom == maxZoom &&
          other.center == center &&
          other.zoom == zoom &&
          other.rotation == rotation &&
          other.nonRotatedSize == nonRotatedSize &&
          other.pitch == pitch);
}
