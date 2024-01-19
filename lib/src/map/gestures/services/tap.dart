part of 'base_services.dart';

/// Service to handle tap gestures for the [MapOptions.onTap] callback.
class TapGestureService extends _SingleShotGestureService {
  TapGestureService({required super.controller});

  /// A tap with a primary button has occurred.
  /// This triggers when the tap gesture wins.
  @override
  void submit() {
    if (details == null) return;

    final point = _camera.offsetToCrs(details!.localPosition);
    _options.onTap?.call(details!, point);
    controller.emitMapEvent(
      MapEventTap(
        tapPosition: point,
        camera: _camera,
        source: MapEventSource.tap,
      ),
    );

    reset();
  }
}

/// Service to handle secondary tap gestures for the
/// [MapOptions.onSecondaryTap] callback.
class SecondaryTapGestureService extends _SingleShotGestureService {
  SecondaryTapGestureService({required super.controller});

  /// A tap with a secondary button has occurred.
  /// This triggers when the tap gesture wins.
  @override
  void submit() {
    if (details == null) return;

    final position = _camera.offsetToCrs(details!.localPosition);
    _options.onSecondaryTap?.call(details!, position);
    controller.emitMapEvent(
      MapEventSecondaryTap(
        tapPosition: position,
        camera: _camera,
        source: MapEventSource.secondaryTap,
      ),
    );

    reset();
  }
}

/// Service to handle tertiary tap gestures for the
/// [MapOptions.onTertiaryTap] callback.
class TertiaryTapGestureService extends _SingleShotGestureService {
  TertiaryTapGestureService({required super.controller});

  /// A tertiary tap gesture has happen (e.g. click on the mouse scroll wheel)
  @override
  void submit() {
    if (details == null) return;

    final point = _camera.offsetToCrs(details!.localPosition);
    _options.onTertiaryTap?.call(details!, point);
    controller.emitMapEvent(
      MapEventTertiaryTap(
        tapPosition: point,
        camera: _camera,
        source: MapEventSource.tertiaryTap,
      ),
    );

    reset();
  }
}
