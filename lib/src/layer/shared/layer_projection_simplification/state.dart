import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/layer_projection_simplification/widget.dart';
import 'package:flutter_map/src/misc/simplify.dart';
import 'package:meta/meta.dart';

/// A mixin to be applied on the [State] of a
/// [ProjectionSimplificationManagementSupportedWidget], which provides
/// pre-projection and pre-simplification support for layers that paint elements
/// (particularly [PolylineLayer] and [PolygonLayer]), and updates them as
/// necessary
///
/// Subclasses must implement [build], and invoke `super.build()` (but ignore
/// the result) at the start. The `build` method should/can then use
/// [simplifiedElements].
mixin ProjectionSimplificationManagement<
    ProjectedElement extends Object,
    Element extends Object,
    W extends ProjectionSimplificationManagementSupportedWidget> on State<W> {
  /// Project [Element] to [ProjectedElement] using the specified [projection]
  ProjectedElement projectElement({
    required Projection projection,
    required Element element,
  });

  /// Simplify the points of [ProjectedElement] with the given [tolerance]
  ///
  /// Should not call [getEffectiveSimplificationTolerance]; [tolerance] has
  /// already been processed.
  ProjectedElement simplifyProjectedElement({
    required ProjectedElement projectedElement,
    required double tolerance,
  });

  /// Return the individual elements given the
  /// [ProjectionSimplificationManagementSupportedWidget]
  Iterable<Element> getElements(W widget);

  /// An iterable of simplified [ProjectedElement]s, which is always ready
  /// after the [build] method has been invoked, and should then be used in the
  /// next [build] stage (usually culling)
  ///
  /// Do not use before invoking [build]. Only necessarily up to date directly
  /// after [build] has been invoked.
  late Iterable<ProjectedElement> simplifiedElements;

  Iterable<ProjectedElement>? _cachedProjectedElements;
  final _cachedSimplifiedElements = <int, Iterable<ProjectedElement>>{};

  double? _devicePixelRatio;

  @mustCallSuper
  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);

    _cachedProjectedElements = null;
    _cachedSimplifiedElements.clear();
  }

  @mustBeOverridden
  @mustCallSuper
  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    final elements = getElements(widget);

    final projected = _cachedProjectedElements ??= List.generate(
      elements.length,
      (i) => projectElement(
        projection: camera.crs.projection,
        element: elements.elementAt(i),
      ),
      growable: false,
    );

    // The `build` method handles initial simplification, re-simplification only
    // when the DPR has changed, and re-simplification implicitly when the
    // tolerance is changed (and the cache is emptied by `didUpdateWidget`).
    if (widget.simplificationTolerance == 0) {
      simplifiedElements = projected;
    } else {
      // If the DPR has changed, invalidate the simplification cache
      final newDPR = MediaQuery.devicePixelRatioOf(context);
      if (newDPR != _devicePixelRatio) {
        _devicePixelRatio = newDPR;
        _cachedSimplifiedElements.clear();
      }

      simplifiedElements =
          (_cachedSimplifiedElements[camera.zoom.floor()] ??= _simplifyElements(
        camera: camera,
        projectedElements: projected,
        pixelTolerance: widget.simplificationTolerance,
        devicePixelRatio: newDPR,
      ));
    }

    return Builder(
      builder: (context) => throw UnimplementedError(
        'Widgets that mix ProjectionSimplificationManagement into their State '
        'must call super.build() but must ignore the return value of the '
        'superclass.',
      ),
    );
  }

  Iterable<ProjectedElement> _simplifyElements({
    required Iterable<ProjectedElement> projectedElements,
    required MapCamera camera,
    required double pixelTolerance,
    required double devicePixelRatio,
  }) sync* {
    final tolerance = getEffectiveSimplificationTolerance(
      crs: camera.crs,
      zoom: camera.zoom.floor(),
      pixelTolerance: pixelTolerance,
      devicePixelRatio: devicePixelRatio,
    );

    for (final projectedElement in projectedElements) {
      yield simplifyProjectedElement(
        projectedElement: projectedElement,
        tolerance: tolerance,
      );
    }
  }
}
