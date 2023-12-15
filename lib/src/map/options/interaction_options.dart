import 'package:flutter/services.dart';
import 'package:flutter_map/src/map/options/enabled_gestures.dart';
import 'package:meta/meta.dart';

/// Set interation options for input gestures.
/// Most commonly used is [InteractionOptions.enabledGestures].
@immutable
final class InteractionOptions {
  /// Enable or disable specific gestures. By default all gestures are enabled.
  /// If you want to disable all gestures or almost all gestures, use the
  /// [EnabledGestures.none] constructor.
  /// In case you want to disable only few gestures, use [EnabledGestures.all]
  /// and you can use the [EnabledGestures.noRotation] for an easy way to
  /// disable all rotation gestures.
  ///
  /// In addition you can specify your gestures via bitfield operations using
  /// the [EnabledGestures.bitfield] constructor together with the static
  /// fields in [InteractiveFlag].
  /// For more information see the documentation on [InteractiveFlag].
  final EnabledGestures enabledGestures;

  /// Rotation threshold in degree. Map starts to rotate when
  /// [rotationThreshold] has been achieved or another multi finger
  /// gesture wins.
  /// Default is 20.0
  final double rotationThreshold; // TODO

  /// Pinch Zoom threshold. Map starts to zoom when
  /// [pinchZoomThreshold] has been achieved or another multi finger gesture
  /// wins.
  /// Default is 0.5
  final double pinchZoomThreshold; // TODO

  /// Pinch Move threshold (note: this doesn't take any effect
  /// on drag) Map starts to move when [pinchMoveThreshold] has been achieved or
  /// another multi finger gesture wins.
  /// Default is 40.0
  final double pinchMoveThreshold; // TODO

  /// The velocity how fast the map should zoom when using the scroll wheel
  /// of the mouse.
  /// Defaults to 0.005.
  final double scrollWheelVelocity;

  /// Override this option if you want to use custom keys for the CTRL+drag
  /// rotate gesture. By default the left and right control key are used.
  final List<LogicalKeyboardKey> ctrlRotateKeys;

  const InteractionOptions({
    this.enabledGestures = const EnabledGestures.all(),
    this.rotationThreshold = 20.0,
    this.pinchZoomThreshold = 0.5,
    this.pinchMoveThreshold = 40.0,
    this.scrollWheelVelocity = 0.005,
    this.ctrlRotateKeys = const <LogicalKeyboardKey>[
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
    ],
  })  : assert(
          rotationThreshold >= 0.0,
          'rotationThreshold needs to be a positive value',
        ),
        assert(
          pinchZoomThreshold >= 0.0,
          'pinchZoomThreshold needs to be a positive value',
        ),
        assert(
          pinchMoveThreshold >= 0.0,
          'pinchMoveThreshold needs to be a positive value',
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InteractionOptions &&
          enabledGestures == other.enabledGestures &&
          rotationThreshold == other.rotationThreshold &&
          pinchZoomThreshold == other.pinchZoomThreshold &&
          pinchMoveThreshold == other.pinchMoveThreshold &&
          ctrlRotateKeys == other.ctrlRotateKeys &&
          scrollWheelVelocity == other.scrollWheelVelocity);

  @override
  int get hashCode => Object.hash(
        enabledGestures,
        rotationThreshold,
        pinchZoomThreshold,
        pinchMoveThreshold,
        ctrlRotateKeys,
        scrollWheelVelocity,
      );
}
