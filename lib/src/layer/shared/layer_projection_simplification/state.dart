import 'dart:collection';

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

  final _cachedProjectedElements = SplayTreeMap<int, ProjectedElement>();
  final _cachedSimplifiedElements =
      <int, SplayTreeMap<int, ProjectedElement>>{};

  double? _devicePixelRatio;

  @mustCallSuper
  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.useDynamicUpdate) return;

    final camera = MapCamera.of(context);

    // If the simplification tolerance has changed, then clear all
    // simplifications to allow `build` to re-simplify.
    final hasSimplficationToleranceChanged =
        oldWidget.simplificationTolerance != widget.simplificationTolerance;
    if (hasSimplficationToleranceChanged) _cachedSimplifiedElements.clear();

    final elements = getElements(widget);

    // We specifically only use basic equality here, and not deep, since deep
    // will always be equal.
    if (getElements(oldWidget) == elements) return;

    // Loop through all polygons in the new widget
    // If not in the projection cache, then re-project. Also, do the same for
    // the simplification cache, across all zoom levels for each polygon.
    // Then, remove all polygons no longer in the new widget from each cache.
    //
    // This is an O(n^3) operation, assuming n is the number of polygons
    // (assuming they are all similar, otherwise exact runtime will depend on
    // existing cache lengths, etc.). However, compared to previous versions, it
    // takes approximately the same duration, as it relieves the work from the
    // `build` method.
    for (final element in getElements(widget)) {
      final existingProjection = _cachedProjectedElements[element.hashCode];

      if (existingProjection == null) {
        _cachedProjectedElements[element.hashCode] =
            projectElement(projection: camera.crs.projection, element: element);

        if (hasSimplficationToleranceChanged) continue;

        for (final MapEntry(key: zoomLvl, value: simplifiedElements)
            in _cachedSimplifiedElements.entries) {
          final simplificationTolerance = getEffectiveSimplificationTolerance(
            crs: camera.crs,
            zoom: zoomLvl,
            // When the tolerance changes, this method handles resetting and filling
            pixelTolerance: widget.simplificationTolerance,
            // When the DPR changes, the `build` method handles resetting and filling
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          );

          final existingSimplification = simplifiedElements[element.hashCode];

          if (existingSimplification == null) {
            _cachedSimplifiedElements[zoomLvl]![element.hashCode] =
                simplifyProjectedElement(
              projectedElement: _cachedProjectedElements[element.hashCode]!,
              tolerance: simplificationTolerance,
            );
          }
        }
      }
    }

    _cachedProjectedElements
        .removeWhere((k, v) => !elements.map((p) => p.hashCode).contains(k));

    for (final simplifiedElement in _cachedSimplifiedElements.values) {
      simplifiedElement
          .removeWhere((k, v) => !elements.map((p) => p.hashCode).contains(k));
    }
  }

  @mustCallSuper
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Performed once only, at load - projects all initial polygons
    if (_cachedProjectedElements.isEmpty) {
      final camera = MapCamera.of(context);

      for (final element in getElements(widget)) {
        _cachedProjectedElements[element.hashCode] =
            projectElement(projection: camera.crs.projection, element: element);
      }
    }
  }

  @mustBeOverridden
  @mustCallSuper
  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);

    // The `build` method handles initial simplification, re-simplification only
    // when the DPR has changed, and re-simplification implicitly when the
    // tolerance is changed (and the cache is emptied by `didUpdateWidget`).
    if (widget.simplificationTolerance == 0) {
      simplifiedElements = _cachedProjectedElements.values;
    } else {
      // If the DPR has changed, invalidate the simplification cache
      final newDPR = MediaQuery.devicePixelRatioOf(context);
      if (newDPR != _devicePixelRatio) {
        _devicePixelRatio = newDPR;
        _cachedSimplifiedElements.clear();
      }

      simplifiedElements = (_cachedSimplifiedElements[camera.zoom.floor()] ??=
              SplayTreeMap.fromIterables(
        _cachedProjectedElements.keys,
        _simplifyElements(
          camera: camera,
          projectedElements: _cachedProjectedElements.values,
          pixelTolerance: widget.simplificationTolerance,
          devicePixelRatio: newDPR,
        ),
      ))
          .values;
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
