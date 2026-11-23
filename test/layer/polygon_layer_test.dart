import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test polygon layer', (tester) async {
    final polygons = <Polygon>[
      for (int i = 0; i < 1; ++i)
        Polygon(
          color: Colors.purple,
          borderColor: Colors.purple,
          borderStrokeWidth: 4,
          label: '$i',
          points: const [
            LatLng(55.5, -0.09),
            LatLng(54.3498, -6.2603),
            LatLng(52.8566, 2.3522),
          ],
        ),
    ];

    await tester.pumpWidget(TestApp(polygons: polygons));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolygonLayer), findsOneWidget);

    // Assert that batching works and all polygons are drawn into the same
    // CustomPaint/Canvas, and their labels into a second one.
    expect(
        find.descendant(
            of: find.byType(PolygonLayer), matching: find.byType(CustomPaint)),
        findsNWidgets(2));
  });

  testWidgets('label is drawn over a later polygon that overlaps it',
      (tester) async {
    await tester.pumpWidget(TestApp(polygons: [
      Polygon(
        color: Colors.purple,
        label: 'A',
        points: const [
          LatLng(45.53, -122.69),
          LatLng(45.53, -122.66),
          LatLng(45.51, -122.66),
          LatLng(45.51, -122.69),
        ],
      ),
      Polygon(
        color: Colors.green,
        points: const [
          LatLng(45.526, -122.68),
          LatLng(45.526, -122.673),
          LatLng(45.52, -122.673),
          LatLng(45.52, -122.68),
        ],
      ),
    ]));

    final order = StringBuffer();
    for (final element in find
        .descendant(
          of: find.byType(PolygonLayer),
          matching: find.byType(CustomPaint),
        )
        .evaluate()) {
      final box = element.renderObject! as RenderCustomPaint;
      final canvas = TestRecordingCanvas();
      box.painter!.paint(canvas, box.size);
      for (final recorded in canvas.invocations) {
        switch (recorded.invocation.memberName) {
          case #drawPath || #drawVertices:
            order.write('P');
          case #drawParagraph:
            order.write('L');
        }
      }
    }
    expect(order.toString(), 'PPL');
  });

  test('polygon normal/rotation', () {
    const clockwise = [
      LatLng(30, 20),
      LatLng(30, 30),
      LatLng(20, 30),
      LatLng(20, 20),
    ];
    expect(Polygon.isClockwise(clockwise), isTrue);
    expect(Polygon.isClockwise(clockwise.reversed.toList()), isFalse);
  });
}
