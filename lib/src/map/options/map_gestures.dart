import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// The available map gestures to move, zoom or rotate the map.
@immutable
class MapGestures {
  /// Use this constructor if you want to set all gestures manually.
  ///
  /// Prefer to use the constructors [InteractiveFlags.all] or
  /// [InteractiveFlags.none] to enable or disable all gestures by default.
  ///
  /// If you want to define your enabled gestures using bitfield operations,
  /// use [InteractiveFlags.bitfield] instead.
  const MapGestures({
    required this.drag,
    required this.twoFingerMove,
    required this.twoFingerZoom,
    required this.doubleTapZoomIn,
    required this.doubleTapDragZoom,
    required this.scrollWheelZoom,
    required this.twoFingerRotate,
    required this.keyTriggerDragRotate,
    required this.trackpadZoom,
  });

  /// This constructor enables all gestures by default. Use this constructor if
  /// you want have all gestures enabled or disable some gestures only.
  ///
  /// In case you want have no or only few gestures enabled use the
  /// [InteractiveFlags.none] constructor instead.
  const MapGestures.all({
    this.drag = true,
    this.twoFingerMove = true,
    this.twoFingerZoom = true,
    this.doubleTapZoomIn = true,
    this.doubleTapDragZoom = true,
    this.scrollWheelZoom = true,
    this.twoFingerRotate = true,
    this.keyTriggerDragRotate = true,
    this.trackpadZoom = true,
  });

  /// This constructor has no enabled gestures by default. Use this constructor
  /// if you want have no gestures enabled or only some specific gestures.
  ///
  /// In case you want have most or all of the gestures enabled use the
  /// [InteractiveFlags.all] constructor instead.
  const MapGestures.none({
    this.drag = false,
    this.twoFingerMove = false,
    this.twoFingerZoom = false,
    this.doubleTapZoomIn = false,
    this.doubleTapDragZoom = false,
    this.scrollWheelZoom = false,
    this.twoFingerRotate = false,
    this.keyTriggerDragRotate = false,
    this.trackpadZoom = false,
  });

  /// Enable or disable gestures by groups.
  /// - [move] includes all gestures that alter [MapCamera.center].
  /// - [zoom] includes all gestures that alter [MapCamera.zoom].
  /// - [rotate] includes all gestures that alter [MapCamera.rotation].
  ///
  /// - Use [MapGestures.allByGroup] to follow an blacklist approach.
  /// - Use [MapGestures.noneByGroup] to follow an whitelist approach.
  const MapGestures.byGroup({
    required bool move,
    required bool zoom,
    required bool rotate,
  }) : this(
          drag: move,
          twoFingerMove: move,
          doubleTapDragZoom: zoom,
          doubleTapZoomIn: zoom,
          scrollWheelZoom: zoom,
          twoFingerZoom: zoom,
          twoFingerRotate: rotate,
          keyTriggerDragRotate: rotate,
          trackpadZoom: zoom,
        );

  /// Enable gestures by groups.
  /// - [move] includes all gestures that alter [MapCamera.center].
  /// - [zoom] includes all gestures that alter [MapCamera.zoom].
  /// - [rotate] includes all gestures that alter [MapCamera.rotation].
  ///
  /// Every group is enabled by defaults when using this
  /// constructor (blacklist approach). If you want to allow only certain
  /// groups, use [MapGestures.noneByGroup] instead.
  const MapGestures.allByGroup({
    bool move = true,
    bool zoom = true,
    bool rotate = true,
  }) : this.byGroup(move: move, zoom: zoom, rotate: rotate);

  /// Disable gestures by groups.
  /// - [move] includes all gestures that alter [MapCamera.center].
  /// - [zoom] includes all gestures that alter [MapCamera.zoom].
  /// - [rotate] includes all gestures that alter [MapCamera.rotation].
  ///
  /// Every group is disabled by default when using this
  /// constructor (whitelist approach). If you want to allow only certain
  /// groups, use [MapGestures.allByGroup] instead.
  const MapGestures.noneByGroup({
    bool move = false,
    bool zoom = false,
    bool rotate = false,
  }) : this.byGroup(move: move, zoom: zoom, rotate: rotate);

  /// This constructor supports bitfield operations on the static fields
  /// from [InteractiveFlag].
  factory MapGestures.bitfield(int flags) {
    return MapGestures(
      drag: InteractiveFlag.hasFlag(flags, InteractiveFlag.drag),
      twoFingerMove:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.twoFingerMove),
      twoFingerZoom:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.twoFingerZoom),
      doubleTapZoomIn:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapZoomIn),
      doubleTapDragZoom:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapDragZoom),
      scrollWheelZoom:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.scrollWheelZoom),
      twoFingerRotate:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.twoFingerRotate),
      keyTriggerDragRotate:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.keyTriggerDragRotate),
      trackpadZoom:
          InteractiveFlag.hasFlag(flags, InteractiveFlag.trackpadZoom),
    );
  }

  /// Enable panning with a single finger or cursor
  final bool drag;

  /// Enable panning with multiple fingers
  final bool twoFingerMove;

  /// Enable zooming with a multi-finger pinch gesture
  final bool twoFingerZoom;

  /// Enable rotation with two-finger twist gesture
  final bool twoFingerRotate;

  /// Enable zooming with a single-finger double tap gesture
  final bool doubleTapZoomIn;

  /// Enable zooming with a single-finger double-tap-drag gesture
  ///
  /// The associated [MapEventSource] is [MapEventSource.doubleTapHold].
  final bool doubleTapDragZoom;

  /// Enable zooming with a mouse scroll wheel
  final bool scrollWheelZoom;

  /// Enable zooming with the device trackpad / touchpad
  final bool trackpadZoom;

  /// Enable rotation by pressing the defined keyboard key (by default CTRL key)
  /// and dragging with the cursor
  /// or finger.
  final bool keyTriggerDragRotate;

  /// Wither to change the value of some gestures. Returns a new
  /// [MapGestures] object.
  MapGestures copyWith({
    bool? drag,
    bool? flingAnimation,
    bool? twoFingerZoom,
    bool? twoFingerMove,
    bool? doubleTapZoomIn,
    bool? doubleTapDragZoom,
    bool? scrollWheelZoom,
    bool? twoFingerRotate,
    bool? keyTriggerDragRotate,
    bool? trackpadZoom,
  }) =>
      MapGestures(
        drag: drag ?? this.drag,
        twoFingerZoom: twoFingerZoom ?? this.twoFingerZoom,
        twoFingerMove: twoFingerMove ?? this.twoFingerMove,
        doubleTapZoomIn: doubleTapZoomIn ?? this.doubleTapZoomIn,
        doubleTapDragZoom: doubleTapDragZoom ?? this.doubleTapDragZoom,
        scrollWheelZoom: scrollWheelZoom ?? this.scrollWheelZoom,
        twoFingerRotate: twoFingerRotate ?? this.twoFingerRotate,
        keyTriggerDragRotate: keyTriggerDragRotate ?? this.keyTriggerDragRotate,
        trackpadZoom: trackpadZoom ?? this.trackpadZoom,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapGestures &&
          runtimeType == other.runtimeType &&
          drag == other.drag &&
          twoFingerMove == other.twoFingerMove &&
          twoFingerZoom == other.twoFingerZoom &&
          doubleTapZoomIn == other.doubleTapZoomIn &&
          doubleTapDragZoom == other.doubleTapDragZoom &&
          scrollWheelZoom == other.scrollWheelZoom &&
          twoFingerRotate == other.twoFingerRotate &&
          keyTriggerDragRotate == other.keyTriggerDragRotate;

  @override
  int get hashCode => Object.hash(
        drag,
        twoFingerMove,
        twoFingerZoom,
        doubleTapZoomIn,
        doubleTapDragZoom,
        scrollWheelZoom,
        twoFingerRotate,
        keyTriggerDragRotate,
      );
}

/// Use [InteractiveFlag] to disable / enable certain events Use
/// [InteractiveFlag.all] to enable all events, use [InteractiveFlag.none] to
/// disable all events
///
/// If you want mix interactions for example drag and rotate interactions then
/// you have two options:
///   a. Add your own flags:
///      [InteractiveFlag.drag] | [InteractiveFlag.twoFingerRotate]
///   b. Remove unnecessary flags from all:
///     [InteractiveFlag.all] &
///       ~[InteractiveFlag.flingAnimation] &
///       ~[InteractiveFlag.twoFingerMove] &
///       ~[InteractiveFlag.twoFingerZoom] &
///       ~[InteractiveFlag.doubleTapZoomIn]
abstract class InteractiveFlag {
  const InteractiveFlag._();

  /// All available interactive flags, use as `flags: InteractiveFlag.all` to
  /// enable all gestures.
  static const int all = drag |
      twoFingerMove |
      twoFingerZoom |
      doubleTapZoomIn |
      doubleTapDragZoom |
      scrollWheelZoom |
      twoFingerRotate |
      trackpadZoom |
      keyTriggerDragRotate;

  /// No enabled interactive flags, use as `flags: InteractiveFlag.none` to
  /// have a non interactive map.
  static const int none = 0;

  /// Enable panning with a single finger or cursor
  static const int drag = 1 << 0;

  /// Enable panning with multiple fingers
  static const int twoFingerMove = 1 << 2;

  /// Enable panning with multiple fingers
  @Deprecated('Renamed to twoFingerMove')
  static const int pinchMove = twoFingerMove;

  /// Enable zooming with a multi-finger pinch gesture
  static const int twoFingerZoom = 1 << 3;

  /// Enable zooming with a multi-finger pinch gesture
  @Deprecated('Renamed to twoFingerZoom')
  static const int pinchZoom = twoFingerZoom;

  /// Enable zooming with a single-finger double tap gesture
  static const int doubleTapZoomIn = 1 << 4;

  /// Enable zooming with a single-finger double tap gesture
  @Deprecated('Renamed to doubleTapZoomIn')
  static const int doubleTapZoom = doubleTapZoomIn;

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
  static const int twoFingerRotate = 1 << 7;

  /// Enable rotation with two-finger twist gesture.
  @Deprecated('Renamed to twoFingerRotate')
  static const int rotate = twoFingerRotate;

  /// Enable rotation by pressing the defined keyboard keys
  /// (by default CTRL Key) and drag the map with the cursor.
  /// To change the key see [InteractionOptions.cursorKeyboardRotationOptions].
  static const int keyTriggerDragRotate = 1 << 8;

  /// Enable zooming by using the trackpad / touchpad of a device.
  static const int trackpadZoom = 1 << 9;

  /// Returns `true` if [leftFlags] has at least one member in [rightFlags]
  /// (intersection) for example
  /// [leftFlags] = [InteractiveFlag.drag] | [InteractiveFlag.twoFingerRotate]
  /// and
  /// [rightFlags] = [InteractiveFlag.twoFingerRotate]
  ///                | [InteractiveFlag.flingAnimation]
  /// returns true because both have the [InteractiveFlag.twoFingerRotate] flag.
  static bool hasFlag(int leftFlags, int rightFlags) {
    return leftFlags & rightFlags != 0;
  }
}
