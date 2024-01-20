part of 'base_services.dart';

/// Service to handle the trackpad (aka. touchpad) zoom gesture to zoom
/// the map in or out.
///
/// Trackpad pinch gesture, in case the pointerPanZoom event
/// callbacks can't be used and trackpad scrolling must still use
/// this old PointerScrollSignal system.
///
/// This is the case if not enough data is
/// provided to the Flutter engine by platform APIs:
/// - On **Windows**, where trackpad gesture support is dependent on
/// the trackpad’s driver,
/// - On **Web**, where not enough data is provided by browser APIs.
///
/// https://docs.flutter.dev/release/breaking-changes/trackpad-gestures#description-of-change
class TrackpadLegacyZoomGestureService extends _BaseGestureService {
  static const _velocityAdjustment = 4.5;

  TrackpadLegacyZoomGestureService({required super.controller});

  double get _velocity => _options.interactionOptions.trackpadZoomVelocity;

  void submit(PointerScaleEvent details) {
    if (details.scale == 1) return;

    final tmpZoom = _camera.zoom +
        (math.log(details.scale) / math.ln2) * _velocity * _velocityAdjustment;
    final newZoom = _camera.clampZoom(tmpZoom);

    // TODO: calculate new center

    controller.moveRaw(
      _camera.center,
      newZoom,
      hasGesture: true,
      source: MapEventSource.trackpad,
    );
  }
}
