import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets(
    'MapEventWithMove.fromSource produces a move event for gesture zooms',
    (tester) async {
      final controller = MapController();
      await tester.pumpWidget(TestApp(controller: controller));
      final camera = controller.camera;

      MapEventWithMove? eventFor(MapEventSource source) =>
          MapEventWithMove.fromSource(
            oldCamera: camera,
            camera: camera,
            hasGesture: true,
            source: source,
          );

      expect(eventFor(MapEventSource.doubleTapHold), isA<MapEventMove>());
    },
  );
}
