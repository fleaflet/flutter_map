part of 'base_services.dart';

class LongPressGestureService extends BaseGestureService {
  LongPressGestureService({required super.controller});

  /// Called when a long press gesture with a primary button has been
  /// recognized. A pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  void submit(LongPressStartDetails details) {
    controller.stopAnimationRaw();
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

class SecondaryLongPressGestureService extends BaseGestureService {
  SecondaryLongPressGestureService({required super.controller});

  /// Called when a long press gesture with a primary button has been
  /// recognized. A pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  void submit(LongPressStartDetails details) {
    controller.stopAnimationRaw();
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

class TertiaryLongPressGestureService extends DelayedGestureService {
  TertiaryLongPressGestureService({required super.controller});

  /// A long press on the tertiary button has happen (e.g. click and hold on
  /// the mouse scroll wheel)
  void submit(LongPressStartDetails details) {
    controller.stopAnimationRaw();
    final point = _camera.offsetToCrs(details.localPosition);
    _options.onTertiaryLongPress?.call(details, point);
    controller.emitMapEvent(
      MapEventTertiaryLongPress(
        tapPosition: point,
        camera: _camera,
        source: MapEventSource.tertiaryLongPress,
      ),
    );

    reset();
  }
}
