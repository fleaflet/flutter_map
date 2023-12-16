part of 'base_services.dart';

class CtrlDragRotateGestureService extends BaseGestureService {
  bool isActive = false;
  final List<LogicalKeyboardKey> keys;

  CtrlDragRotateGestureService({
    required super.controller,
    required this.keys,
  });

  void start() {
    controller.stopAnimationRaw();
    controller.emitMapEvent(
      MapEventRotateStart(
        camera: _camera,
        source: MapEventSource.ctrlDragRotateStart,
      ),
    );
  }

  void update(ScaleUpdateDetails details) {
    controller.rotateRaw(
      _camera.rotation - (details.focalPointDelta.dy * 0.5),
      hasGesture: true,
      source: MapEventSource.ctrlDragRotate,
    );
  }

  void end() {
    controller.emitMapEvent(
      MapEventRotateEnd(
        camera: _camera,
        source: MapEventSource.ctrlDragRotateEnd,
      ),
    );
  }

  bool get keyPressed => RawKeyboard.instance.keysPressed
      .where((key) => keys.contains(key))
      .isNotEmpty;
}
