import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Wraps [child] in a box that reports [Size.zero] to the [LayoutBuilder]
/// constraints for the first build, then switches to [realSize] once
/// `reveal()` is called - while [MediaQuery] (from the ambient test binding)
/// stays at its real, non-zero size throughout.
///
/// This reproduces the situation described in
/// `_FlutterMapStateContainer._parentConstraintsAreSet`'s doc comment:
/// zero `LayoutBuilder` constraints while the platform/`MediaQuery` size is
/// already known - which can happen any time a `FlutterMap` is nested under
/// a widget that doesn't have its final size on the first layout pass (e.g.
/// `Expanded`/`Flexible` inside a not-yet-measured parent, `AnimatedSize`,
/// a lazily-revealed tab, etc.), not just during platform startup.
class _DelayedSizeBox extends StatefulWidget {
  const _DelayedSizeBox({
    super.key,
    required this.realSize,
    required this.child,
  });

  final Size realSize;
  final Widget child;

  @override
  State<_DelayedSizeBox> createState() => _DelayedSizeBoxState();
}

class _DelayedSizeBoxState extends State<_DelayedSizeBox> {
  bool _revealed = false;

  void reveal() => setState(() => _revealed = true);

  @override
  Widget build(BuildContext context) {
    final size = _revealed ? widget.realSize : Size.zero;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: widget.child,
    );
  }
}

void main() {
  testWidgets(
    'initialCameraFit is still applied normally when the real size is '
    'available from the very first frame (no zero-size race)',
    (tester) async {
      final controller = MapController();
      const realSize = Size(390, 500);
      final bounds = LatLngBounds(
        const LatLng(47.5, 7.5),
        const LatLng(52.5, 14.5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: realSize.width,
              height: realSize.height,
              child: FlutterMap(
                mapController: controller,
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(50),
                  ),
                ),
                children: const [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final camera = controller.camera;
      final expectedCamera = CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ).fit(camera.withNonRotatedSize(realSize));

      expect(camera.nonRotatedSize, realSize);
      expect(camera.zoom, closeTo(expectedCamera.zoom, 0.001));
    },
  );

  testWidgets(
    'initialCameraFit applied while nested in a zero-then-real-size parent '
    'produces the correctly fitted zoom, not a degenerate one',
    (tester) async {
      final controller = MapController();
      final key = GlobalKey<_DelayedSizeBoxState>();
      // Kept within the default flutter_test surface size (800x600) so it
      // isn't clipped by the ambient window and `nonRotatedSize` ends up
      // exactly matching what was requested.
      const realSize = Size(390, 500);
      final bounds = LatLngBounds(
        const LatLng(47.5, 7.5),
        const LatLng(52.5, 14.5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: _DelayedSizeBox(
              key: key,
              realSize: realSize,
              child: FlutterMap(
                mapController: controller,
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(50),
                  ),
                ),
                children: const [],
              ),
            ),
          ),
        ),
      );

      // First frame: FlutterMap is constrained to Size.zero, while
      // MediaQuery already reports the real (non-zero) test window size.
      await tester.pump();

      // Reveal the real size, as would happen once the parent's layout
      // pass completes.
      key.currentState!.reveal();
      await tester.pumpAndSettle();

      final camera = controller.camera;
      // ignore: avoid_print
      print('camera.zoom=${camera.zoom} camera.center=${camera.center} '
          'nonRotatedSize=${camera.nonRotatedSize}');

      expect(
        camera.nonRotatedSize,
        realSize,
        reason: 'sanity check: the widget should have settled at the '
            'requested real size, not have it clipped by the test window',
      );

      // Compute what the correct fit *should* be, applied directly against
      // the real, final size - this is what a correctly-behaving
      // initialCameraFit should have converged to.
      final expectedCamera = CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ).fit(camera.withNonRotatedSize(realSize));

      expect(
        camera.zoom,
        closeTo(expectedCamera.zoom, 0.001),
        reason: 'initialCameraFit should fit against the real widget size, '
            'not the transient zero size seen on the first frame',
      );
    },
  );
}
