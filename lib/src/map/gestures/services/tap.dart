part of 'base_services.dart';

class TapGestureService extends DelayedGestureService {
  TapGestureService({required super.controller});

  /// A tap with a primary button has occurred.
  /// This triggers when the tap gesture wins.
  void submit() {
    controller.stopAnimationRaw();
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

class SecondaryTapGestureService extends DelayedGestureService {
  SecondaryTapGestureService({required super.controller});

  /// A tap with a secondary button has occurred.
  /// This triggers when the tap gesture wins.
  void submit() {
    controller.stopAnimationRaw();
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

class TertiaryTapGestureService extends DelayedGestureService {
  TertiaryTapGestureService({required super.controller});

  /// A tertiary tap gesture has happen (e.g. click on the mouse scroll wheel)
  void submit(TapUpDetails _) {
    controller.stopAnimationRaw();
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
