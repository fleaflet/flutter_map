import 'package:flutter/services.dart';
import 'package:flutter_map/src/map/options/enabled_gestures.dart';
import 'package:meta/meta.dart';

@immutable
final class InteractionOptions {
  /// See [EnabledGestures] for custom settings
  final EnabledGestures enabledGestures;

  /// Rotation threshold in degree default is 20.0 Map starts to rotate when
  /// [rotationThreshold] has been achieved or another multi finger gesture wins
  /// which allows [MultiFingerGesture.rotate] Note: if [interactiveFlags]
  /// doesn't contain [InteractiveFlag.rotate] or [enableMultiFingerGestureRace]
  /// is false then rotate cannot win
  final double rotationThreshold;

  /// Pinch Zoom threshold default is 0.5 Map starts to zoom when
  /// [pinchZoomThreshold] has been achieved or another multi finger gesture
  /// wins which allows [MultiFingerGesture.pinchZoom] Note: if
  /// [interactiveFlags] doesn't contain [InteractiveFlag.pinchZoom] or
  /// [enableMultiFingerGestureRace] is false then zoom cannot win
  final double pinchZoomThreshold;

  /// Pinch Move threshold default is 40.0 (note: this doesn't take any effect
  /// on drag) Map starts to move when [pinchMoveThreshold] has been achieved or
  /// another multi finger gesture wins which allows
  /// [MultiFingerGesture.pinchMove] Note: if [interactiveFlags] doesn't contain
  /// [InteractiveFlag.pinchMove] or [enableMultiFingerGestureRace] is false
  /// then pinch move cannot win
  final double pinchMoveThreshold;

  final double scrollWheelVelocity;

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
          scrollWheelVelocity == other.scrollWheelVelocity);

  @override
  int get hashCode => Object.hash(
        enabledGestures,
        rotationThreshold,
        pinchZoomThreshold,
        pinchMoveThreshold,
        scrollWheelVelocity,
      );
}
