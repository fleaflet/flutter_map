/// Event sources which are used to identify different types of
/// [MapEvent] events
enum MapEventSource {
  /// The [MapEvent] is caused programmatically by the [MapController].
  mapController,

  /// The [MapEvent] is caused by a tap gesture.
  /// (e.g. a click on the left mouse button or a tap on the touchscreen)
  tap,

  /// The [MapEvent] is caused by a secondary tap gesture.
  /// (e.g. a click on the right mouse button)
  secondaryTap,

  /// The [MapEvent] is caused by a tertiary tap gesture
  /// (e.g. click on the mouse scroll wheel).
  tertiaryTap,

  /// The [MapEvent] is caused by a long press gesture.
  longPress,

  /// The [MapEvent] is caused by a long press gesture on the secondary button
  /// (e.g. the right mouse button).
  secondaryLongPressed,

  /// The [MapEvent] is caused by a long press gesture on the tertiary button
  /// (e.g. the mouse scroll wheel).
  tertiaryLongPress,

  /// The [MapEvent] is caused by a double tap gesture.
  doubleTap,

  /// The [MapEvent] is caused by a double tap and hold gesture.
  doubleTapHold,

  /// The [MapEvent] is caused by the start of a drag gesture.
  dragStart,

  /// The [MapEvent] is caused by a drag update gesture.
  onDrag,

  /// The [MapEvent] is caused by the end of a drag gesture.
  dragEnd,

  /// The [MapEvent] is caused by the start of a two finger gesture.
  twoFingerStart,

  /// The [MapEvent] is caused by a two finger gesture update.
  onTwoFinger,

  /// The [MapEvent] is caused by a the end of a two finger gesture.
  twoFingerEnd,

  /// The [MapEvent] is caused by the [AnimationController] while performing
  /// the fling gesture.
  flingAnimationController,

  /// The [MapEvent] is caused by the [AnimationController] while performing
  /// the double tap zoom in animation.
  doubleTapZoomAnimationController,

  /// The [MapEvent] is caused by a change of the interactive flags.
  interactiveFlagsChanged,

  /// The [MapEvent] is caused by calling fitCamera.
  fitCamera,

  /// The [MapEvent] is caused by a custom source.
  custom,

  /// The [MapEvent] is caused by a scroll wheel zoom gesture.
  scrollWheel,

  /// The [MapEvent] is caused by a size change of the [FlutterMap] constraints.
  nonRotatedSizeChange,

  /// The [MapEvent] is caused by the start of a key-press and drag gesture
  /// (e.g. CTRL + drag to rotate the map).
  keyTriggerDragRotateStart,

  /// The [MapEvent] is caused by a key-press and drag gesture
  /// (e.g. CTRL + drag to rotate the map).
  keyTriggerDragRotate,

  /// The [MapEvent] is caused by the end of a key-press and drag gesture
  /// (e.g. CTRL + drag to rotate the map).
  keyTriggerDragRotateEnd,

  /// The [MapEvent] is caused by the trackpad / touchpad of the device.
  trackpad,
}
