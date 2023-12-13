import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

@immutable
class InteractiveFlags {
  const InteractiveFlags._({
    required this.drag,
    required this.flingAnimation,
    required this.pinchMove,
    required this.pinchZoom,
    required this.doubleTapZoom,
    required this.doubleTapDragZoom,
    required this.scrollWheelZoom,
    required this.rotate,
    required this.ctrlDragRotate,
  });

  const InteractiveFlags.all({
    this.drag = true,
    this.flingAnimation = true,
    this.pinchMove = true,
    this.pinchZoom = true,
    this.doubleTapZoom = true,
    this.doubleTapDragZoom = true,
    this.scrollWheelZoom = true,
    this.rotate = true,
    this.ctrlDragRotate = true,
  });

  const InteractiveFlags.none({
    this.drag = false,
    this.flingAnimation = false,
    this.pinchMove = false,
    this.pinchZoom = false,
    this.doubleTapZoom = false,
    this.doubleTapDragZoom = false,
    this.scrollWheelZoom = false,
    this.rotate = false,
    this.ctrlDragRotate = false,
  });

  factory InteractiveFlags.bitfield(int flags) {
    return InteractiveFlags._(
      drag: InteractiveFlag.hasFlag(flags, InteractiveFlag.drag),
      flingAnimation:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.flingAnimation),
      pinchMove: InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchMove),
      pinchZoom: InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom),
      doubleTapZoom:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapZoom),
      doubleTapDragZoom:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapDragZoom),
      scrollWheelZoom:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.scrollWheelZoom),
      rotate: InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate),
      ctrlDragRotate:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.ctrlDragRotate),
    );
  }

  /// Enable panning with a single finger or cursor
  final bool drag;

  /// Enable fling animation after panning if velocity is great enough.
  final bool flingAnimation;

  /// Enable panning with multiple fingers
  final bool pinchMove;

  /// Enable zooming with a multi-finger pinch gesture
  final bool pinchZoom;

  /// Enable zooming with a single-finger double tap gesture
  final bool doubleTapZoom;

  /// Enable zooming with a single-finger double-tap-drag gesture
  ///
  /// The associated [MapEventSource] is [MapEventSource.doubleTapHold].
  final bool doubleTapDragZoom;

  /// Enable zooming with a mouse scroll wheel
  final bool scrollWheelZoom;

  /// Enable rotation with two-finger twist gesture
  ///
  /// For controlling cursor/keyboard rotation, see
  /// [InteractionOptions.cursorKeyboardRotationOptions].
  final bool rotate;

  /// Enable rotation by pressing the CTRL key and dragging with the cursor
  /// or finger.
  final bool ctrlDragRotate;

  bool hasMultiFinger() => pinchMove || pinchZoom || rotate;

  /// This constructor gives wither functionality to the model
  InteractiveFlags withFlag({
    bool? pinchZoom,
    bool? drag,
    bool? flingAnimation,
    bool? pinchMove,
    bool? doubleTapZoom,
    bool? doubleTapDragZoom,
    bool? scrollWheelZoom,
    bool? rotate,
    bool? ctrlDragRotate,
  }) =>
      InteractiveFlags._(
        pinchZoom: pinchZoom ?? this.pinchZoom,
        drag: drag ?? this.drag,
        flingAnimation: flingAnimation ?? this.flingAnimation,
        pinchMove: pinchMove ?? this.pinchMove,
        doubleTapZoom: doubleTapZoom ?? this.doubleTapZoom,
        doubleTapDragZoom: doubleTapDragZoom ?? this.doubleTapDragZoom,
        scrollWheelZoom: scrollWheelZoom ?? this.scrollWheelZoom,
        rotate: rotate ?? this.rotate,
        ctrlDragRotate: rotate ?? this.ctrlDragRotate,
      );
}
