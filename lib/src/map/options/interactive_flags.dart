import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

@immutable
class InteractiveFlags {
  /// Private constructor, use the constructors [InteractiveFlags.all] or
  /// [InteractiveFlags.none] instead to enable or disable all gestures by default.
  /// If you want to define your enabled gestures using bitfield operations,
  /// use [InteractiveFlags.bitfield] instead.
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

  /// Shortcut constructor to allow all gestures that don't rotate the map.
  const InteractiveFlags.noRotation()
      : this.all(
          rotate: false,
          ctrlDragRotate: false,
        );

  /// This constructor enables all gestures by default. Use this constructor if
  /// you want have all gestures enabled or disable some gestures only.
  ///
  /// In case you want have no or only few gestures enabled use the
  /// [InteractiveFlags.none] constructor instead.
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

  /// This constructor has no enabled gestures by default. Use this constructor
  /// if you want have no gestures enabled or only some specific gestures.
  ///
  /// In case you want have most or all of the gestures enabled use the
  /// [InteractiveFlags.all] constructor instead.
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

  /// This constructor supports bitfield operations on the static fields
  /// from [InteractiveFlag].
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

  /// Returns true of any gesture with more than one finger is enabled.
  bool hasMultiFinger() => pinchMove || pinchZoom || rotate;

  /// Wither to change the value of some gestures. Returns a new
  /// [InteractiveFlags] object.
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveFlags &&
          runtimeType == other.runtimeType &&
          drag == other.drag &&
          flingAnimation == other.flingAnimation &&
          pinchMove == other.pinchMove &&
          pinchZoom == other.pinchZoom &&
          doubleTapZoom == other.doubleTapZoom &&
          doubleTapDragZoom == other.doubleTapDragZoom &&
          scrollWheelZoom == other.scrollWheelZoom &&
          rotate == other.rotate &&
          ctrlDragRotate == other.ctrlDragRotate;

  @override
  int get hashCode => Object.hash(
        drag,
        flingAnimation,
        pinchMove,
        pinchZoom,
        doubleTapZoom,
        doubleTapDragZoom,
        scrollWheelZoom,
        rotate,
        ctrlDragRotate,
      );
}

/// Use [InteractiveFlag] to disable / enable certain events Use
/// [InteractiveFlag.all] to enable all events, use [InteractiveFlag.none] to
/// disable all events
///
/// If you want mix interactions for example drag and rotate interactions then
/// you have two options:
///   a. Add your own flags: [InteractiveFlag.drag] | [InteractiveFlag.rotate]
///   b. Remove unnecessary flags from all:
///     [InteractiveFlag.all] &
///       ~[InteractiveFlag.flingAnimation] &
///       ~[InteractiveFlag.pinchMove] &
///       ~[InteractiveFlag.pinchZoom] &
///       ~[InteractiveFlag.doubleTapZoom]
abstract class InteractiveFlag {
  const InteractiveFlag._();

  static const int all = drag |
      flingAnimation |
      pinchMove |
      pinchZoom |
      doubleTapZoom |
      doubleTapDragZoom |
      scrollWheelZoom |
      rotate |
      ctrlDragRotate;

  static const int none = 0;

  /// Enable panning with a single finger or cursor
  static const int drag = 1 << 0;

  /// Enable fling animation after panning if velocity is great enough.
  static const int flingAnimation = 1 << 1;

  /// Enable panning with multiple fingers
  static const int pinchMove = 1 << 2;

  /// Enable zooming with a multi-finger pinch gesture
  static const int pinchZoom = 1 << 3;

  /// Enable zooming with a single-finger double tap gesture
  static const int doubleTapZoom = 1 << 4;

  /// Enable zooming with a single-finger double-tap-drag gesture
  ///
  /// The associated [MapEventSource] is [MapEventSource.doubleTapHold].
  static const int doubleTapDragZoom = 1 << 5;

  /// Enable zooming with a mouse scroll wheel
  static const int scrollWheelZoom = 1 << 6;

  /// Enable rotation with two-finger twist gesture
  ///
  /// For controlling cursor/keyboard rotation, see
  /// [InteractionOptions.cursorKeyboardRotationOptions].
  static const int rotate = 1 << 7;

  /// Enable rotation by pressing the CTRL Key and drag the map with the cursor.
  /// To change the key see [InteractionOptions.cursorKeyboardRotationOptions].
  static const int ctrlDragRotate = 1 << 8;

  /// Returns `true` if [leftFlags] has at least one member in [rightFlags]
  /// (intersection) for example [leftFlags]= [InteractiveFlag.drag] |
  /// [InteractiveFlag.rotate] and [rightFlags]= [InteractiveFlag.rotate] |
  /// [InteractiveFlag.flingAnimation] returns true because both have
  /// [InteractiveFlag.rotate] flag
  static bool hasFlag(int leftFlags, int rightFlags) {
    return leftFlags & rightFlags != 0;
  }
}
