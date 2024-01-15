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

  /// Map starts to rotate when [twoFingerRotateThreshold] has been achieved
  /// or another multi finger gesture wins.
  /// Default is 0.1
  final double twoFingerRotateThreshold;

  /// Map starts to zoom when [twoFingerZoomThreshold] has been achieved or
  /// another multi finger gesture wins.
  /// Default is 0.1
  final double twoFingerZoomThreshold;

  /// Map starts to move when [twoFingerMoveThreshold] has been achieved or
  /// another multi finger gesture wins. This doesn't take any effect on drag
  /// gestures by a single pointer like a single finger.
  ///
  /// This option gets superseded by [twoFingerZoomThreshold] if
  /// [EnabledGestures.twoFingerMove] and [EnabledGestures.twoFingerZoom] are
  /// both active and the [twoFingerZoomThreshold] is reached.
  ///
  /// Default is 3.0.
  final double twoFingerMoveThreshold;

  /// The velocity how fast the map should zoom when using the scroll wheel
  /// of the mouse.
  /// Defaults to 0.01.
  final double scrollWheelVelocity;

  /// Override this option if you want to use custom keys for the key trigger
  /// drag rotate gesture (aka CTRL+drag rotate gesture).
  /// By default the left and right control key are both used.
  final List<LogicalKeyboardKey> keyTriggerDragRotateKeys;

  /// Default keys for the key press and drag to rotate gesture.
  static const defaultKeyTriggerDragRotateKeys = <LogicalKeyboardKey>[
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
  ];

  const InteractionOptions({
    this.enabledGestures = const EnabledGestures.all(),
    this.twoFingerRotateThreshold = 0.1,
    this.twoFingerZoomThreshold = 0.01,
    this.twoFingerMoveThreshold = 3.0,
    this.scrollWheelVelocity = 0.01,
    this.keyTriggerDragRotateKeys = defaultKeyTriggerDragRotateKeys,
  })  : assert(
          twoFingerRotateThreshold >= 0.0,
          'rotationThreshold needs to be a positive value',
        ),
        assert(
          twoFingerZoomThreshold >= 0.0,
          'pinchZoomThreshold needs to be a positive value',
        ),
        assert(
          twoFingerMoveThreshold >= 0.0,
          'pinchMoveThreshold needs to be a positive value',
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InteractionOptions &&
          enabledGestures == other.enabledGestures &&
          twoFingerRotateThreshold == other.twoFingerRotateThreshold &&
          twoFingerZoomThreshold == other.twoFingerZoomThreshold &&
          twoFingerMoveThreshold == other.twoFingerMoveThreshold &&
          keyTriggerDragRotateKeys == other.keyTriggerDragRotateKeys &&
          scrollWheelVelocity == other.scrollWheelVelocity);

  @override
  int get hashCode => Object.hash(
        enabledGestures,
        twoFingerRotateThreshold,
        twoFingerZoomThreshold,
        twoFingerMoveThreshold,
        keyTriggerDragRotateKeys,
        scrollWheelVelocity,
      );
}
