/// Event sources which are used to identify different types of
/// [MapEvent] events
enum MapEventSource {
  mapController,
  tap,
  secondaryTap,
  longPress,
  doubleTap,
  doubleTapHold,
  dragStart,
  onDrag,
  dragEnd,
  multiFingerStart,
  onMultiFinger,
  multiFingerEnd,
  flingAnimationController,
  doubleTapZoomAnimationController,
  interactiveFlagsChanged,
  fitCamera,
  custom,
  scrollWheel,
  nonRotatedSizeChange,
  tertiaryTap,
  tertiaryLongPress,
  secondaryLongPressed,
  keyTriggerDragRotateStart,
  keyTriggerDragRotateEnd,
  keyTriggerDragRotate,
}