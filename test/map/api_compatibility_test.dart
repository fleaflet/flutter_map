import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

// Application code that must keep compiling as the public API grows: adding a
// MapEventSource value or an abstract member to CameraConstraint or CameraFit
// breaks it.

String _describe(MapEventSource source) => switch (source) {
      MapEventSource.mapController => 'mapController',
      MapEventSource.tap => 'tap',
      MapEventSource.secondaryTap => 'secondaryTap',
      MapEventSource.longPress => 'longPress',
      MapEventSource.doubleTap => 'doubleTap',
      MapEventSource.doubleTapHold => 'doubleTapHold',
      MapEventSource.dragStart => 'dragStart',
      MapEventSource.onDrag => 'onDrag',
      MapEventSource.dragEnd => 'dragEnd',
      MapEventSource.multiFingerGestureStart => 'multiFingerGestureStart',
      MapEventSource.onMultiFinger => 'onMultiFinger',
      MapEventSource.multiFingerEnd => 'multiFingerEnd',
      MapEventSource.flingAnimationController => 'flingAnimationController',
      MapEventSource.doubleTapZoomAnimationController =>
        'doubleTapZoomAnimationController',
      MapEventSource.interactiveFlagsChanged => 'interactiveFlagsChanged',
      MapEventSource.fitCamera => 'fitCamera',
      MapEventSource.custom => 'custom',
      MapEventSource.scrollWheel => 'scrollWheel',
      MapEventSource.nonRotatedSizeChange => 'nonRotatedSizeChange',
      MapEventSource.cursorKeyboardRotation => 'cursorKeyboardRotation',
      MapEventSource.keyboard => 'keyboard',
    };

class _CustomConstraint extends CameraConstraint {
  const _CustomConstraint();

  @override
  MapCamera? constrain(MapCamera camera) => camera;
}

class _CustomFit extends CameraFit {
  const _CustomFit();

  @override
  MapCamera fit(MapCamera camera) => camera;
}

void main() {
  test('exhaustive switch on MapEventSource', () {
    for (final source in MapEventSource.values) {
      expect(_describe(source), source.name);
    }
  });

  test('custom CameraConstraint and CameraFit', () {
    const options = MapOptions(
      cameraConstraint: _CustomConstraint(),
      initialCameraFit: _CustomFit(),
    );
    final camera = MapCamera.initialCamera(options);
    expect(options.cameraConstraint.constrain(camera), camera);
    expect(options.initialCameraFit!.fit(camera), camera);
  });
}
