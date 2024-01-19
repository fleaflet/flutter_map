part of 'base_services.dart';

/// Service to handle long press gestures for the
/// [MapOptions.onLongPress] callback.
class LongPressGestureService extends _BaseGestureService
    implements _BaseLongPressGestureService {
  LongPressGestureService({required super.controller});

  /// Called when a long press gesture with a primary button has been
  /// recognized. A pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  @override
  void submit(LongPressStartDetails details) {
    final position = _camera.offsetToCrs(details.localPosition);
    _options.onLongPress?.call(details, position);
    controller.emitMapEvent(
      MapEventLongPress(
        tapPosition: position,
        camera: _camera,
        source: MapEventSource.longPress,
      ),
    );
  }
}

/// Service to handle secondary long press gestures for the
/// [MapOptions.onSecondaryLongPress] callback.
class SecondaryLongPressGestureService extends _BaseGestureService
    implements _BaseLongPressGestureService {
  SecondaryLongPressGestureService({required super.controller});

  /// Called when a long press gesture with a primary button has been
  /// recognized. A pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  @override
  void submit(LongPressStartDetails details) {
    final position = _camera.offsetToCrs(details.localPosition);
    _options.onSecondaryLongPress?.call(details, position);
    controller.emitMapEvent(
      MapEventSecondaryLongPress(
        tapPosition: position,
        camera: _camera,
        source: MapEventSource.secondaryLongPressed,
      ),
    );
  }
}

/// Service to handle tertiary long press gestures for the
/// [MapOptions.onTertiaryLongPress] callback.
class TertiaryLongPressGestureService extends _BaseGestureService
    implements _BaseLongPressGestureService {
  TertiaryLongPressGestureService({required super.controller});

  /// A long press on the tertiary button has happen (e.g. click and hold on
  /// the mouse scroll wheel)
  @override
  void submit(LongPressStartDetails details) {
    final point = _camera.offsetToCrs(details.localPosition);
    _options.onTertiaryLongPress?.call(details, point);
    controller.emitMapEvent(
      MapEventTertiaryLongPress(
        tapPosition: point,
        camera: _camera,
        source: MapEventSource.tertiaryLongPress,
      ),
    );
  }
}
