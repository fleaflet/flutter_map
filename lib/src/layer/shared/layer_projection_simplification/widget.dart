import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/layer_projection_simplification/state.dart';

/// A [StatefulWidget] that includes the properties used by the [State] component
/// which mixes [ProjectionSimplificationManagement] in
@immutable
abstract base class ProjectionSimplificationManagementSupportedWidget
    extends StatefulWidget {
  /// Whether to apply the auto-update algorithm to re-paint the necessary
  /// [Polygon]s when they change
  ///
  /// It is recommended to leave this `true`, as default, otherwise changes to
  /// child polygons may not update. It will detect which polygons have changed,
  /// and only 'update' (re-project and re-simplify) those that are necessary.
  ///
  /// However, where there are a large number of polygons, the majority (or more)
  /// of which change at the same time, then it is recommended to set this
  /// `false`. This will avoid a large unnecessary loop to detect changes, and
  /// is likely to improve performance on state changes. If `false`, then the
  /// layer will need to be manually rebuilt from scratch using new [Key]s
  /// whenever necessary. Do not use a [UniqueKey] : this will cause the entire
  /// widget to reset and rebuild every time the map camera changes.
  final bool useDynamicUpdate;

  /// Distance between two neighboring polyline points, in logical pixels scaled
  /// to floored zoom
  ///
  /// Increasing this value results in points further apart being collapsed and
  /// thus more simplified polylines. Higher values improve performance at the
  /// cost of visual fidelity and vice versa.
  ///
  /// Defaults to 0.3. Set to 0 to disable simplification.
  final double simplificationTolerance;

  /// A [StatefulWidget] that includes the properties used by the [State]
  /// component which mixes [ProjectionSimplificationManagement] in
  ///
  /// Constructors should call `super()` (the super constructor) to ensure the
  /// necessary assertions are made.
  const ProjectionSimplificationManagementSupportedWidget({
    super.key,
    this.useDynamicUpdate = true,
    this.simplificationTolerance = 0.3,
  }) : assert(
          simplificationTolerance >= 0,
          'simplificationTolerance cannot be negative: $simplificationTolerance',
        );
}
