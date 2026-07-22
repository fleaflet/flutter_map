import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('test polyline layer', (tester) async {
    final polylines = <Polyline>[
      for (int i = 0; i < 10; i++)
        Polyline(
          points: [
            LatLng(50.5 + i, -0.09),
            LatLng(51.3498 + i, -6.2603),
            LatLng(53.8566 + i, 2.3522),
          ],
          strokeWidth: 4,
          color: Colors.amber,
        ),
    ];

    await tester.pumpWidget(TestApp(polylines: polylines));
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsWidgets);

    // Assert that batching works and all Polylines are drawn into the same
    // CustomPaint/Canvas.
    expect(
        find.descendant(
            of: find.byType(PolylineLayer), matching: find.byType(CustomPaint)),
        findsOneWidget);
  });

  testWidgets('multicolor polyline renders without errors', (tester) async {
    final polylines = <Polyline>[
      MulticolorPolyline(
        points: const [
          LatLng(50.5, -0.09),
          LatLng(51.3498, -6.2603),
          LatLng(53.8566, 2.3522),
        ],
        vertexColors: const [
          Colors.red,
          Colors.orange,
          Colors.blue,
        ],
        strokeWidth: 6,
      ),
    ];

    await tester.pumpWidget(TestApp(polylines: polylines));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multicolor polyline falls back to defaultColor', (tester) async {
    final polylines = <Polyline>[
      MulticolorPolyline(
        points: const [
          LatLng(52.5, -0.09),
          LatLng(53.3498, -6.2603),
          LatLng(55.8566, 2.3522),
        ],
        defaultColor: Colors.purple,
        strokeWidth: 5,
      ),
    ];

    await tester.pumpWidget(TestApp(polylines: polylines));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(tester.takeException(), isNull);

    final polyline = polylines.first as MulticolorPolyline;
    expect(polyline.vertexColors, isNull);
    expect(polyline.color, equals(Colors.purple));
  });

  test('multicolor polyline validates point and color counts', () {
    expect(
      () => MulticolorPolyline(points: const [LatLng(0, 0)]),
      throwsArgumentError,
    );
    expect(
      () => MulticolorPolyline(
        points: const [LatLng(0, 0), LatLng(0, 1)],
        vertexColors: const [Colors.red],
      ),
      throwsArgumentError,
    );
  });

  testWidgets('multicolor polyline interpolates vertex colors', (tester) async {
    final controller = MapController();
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      _RenderingTestApp(
        boundaryKey: boundaryKey,
        controller: controller,
      ),
    );

    final camera = controller.camera;
    final points = [
      camera.screenOffsetToLatLng(const Offset(40, 100)),
      camera.screenOffsetToLatLng(const Offset(100, 100)),
      camera.screenOffsetToLatLng(const Offset(160, 100)),
    ];

    await tester.pumpWidget(
      _RenderingTestApp(
        boundaryKey: boundaryKey,
        controller: controller,
        polylines: [
          MulticolorPolyline(
            points: points,
            vertexColors: const [
              Color(0xFFFF0000),
              Color(0xFF00FF00),
              Color(0xFF0000FF),
            ],
            strokeWidth: 20,
            strokeCap: StrokeCap.butt,
          ),
        ],
      ),
    );

    final pixels = await _capturePixels(tester, boundaryKey);
    final firstSegmentMiddle = pixels.colorAt(70, 100);
    final vertex = pixels.colorAt(100, 100);

    expect(firstSegmentMiddle.r, inInclusiveRange(0.4, 0.65));
    expect(firstSegmentMiddle.g, inInclusiveRange(0.4, 0.65));
    expect(firstSegmentMiddle.b, lessThan(0.08));
    expect(vertex.r, lessThan(0.08));
    expect(vertex.g, greaterThan(0.94));
    expect(vertex.b, lessThan(0.08));
  });

  testWidgets('transparent joins do not accumulate opacity', (tester) async {
    final controller = MapController();
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      _RenderingTestApp(
        boundaryKey: boundaryKey,
        controller: controller,
      ),
    );

    final camera = controller.camera;
    final points = [
      camera.screenOffsetToLatLng(const Offset(40, 100)),
      camera.screenOffsetToLatLng(const Offset(100, 100)),
      camera.screenOffsetToLatLng(const Offset(160, 60)),
    ];
    const translucentGreen = Color(0x8000FF00);

    await tester.pumpWidget(
      _RenderingTestApp(
        boundaryKey: boundaryKey,
        controller: controller,
        polylines: [
          MulticolorPolyline(
            points: points,
            vertexColors: const [
              translucentGreen,
              translucentGreen,
              translucentGreen,
            ],
            strokeWidth: 20,
          ),
        ],
      ),
    );

    final pixels = await _capturePixels(tester, boundaryKey);
    final vertex = pixels.colorAt(100, 100);

    expect(vertex.r, inInclusiveRange(0.47, 0.53));
    expect(vertex.g, greaterThan(0.96));
    expect(vertex.b, inInclusiveRange(0.47, 0.53));
  });

  testWidgets('stroke margin keeps an off-screen centerline visible',
      (tester) async {
    final controller = MapController();
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      _RenderingTestApp(
        boundaryKey: boundaryKey,
        controller: controller,
      ),
    );

    final camera = controller.camera;
    final points = [
      camera.screenOffsetToLatLng(const Offset(40, -5)),
      camera.screenOffsetToLatLng(const Offset(160, -5)),
    ];

    await tester.pumpWidget(
      _RenderingTestApp(
        boundaryKey: boundaryKey,
        controller: controller,
        polylines: [
          Polyline(
            points: points,
            color: const Color(0xFFFF0000),
            strokeWidth: 20,
            strokeCap: StrokeCap.butt,
          ),
        ],
      ),
    );

    final pixels = await _capturePixels(tester, boundaryKey);
    final visibleStroke = pixels.colorAt(100, 1);

    expect(visibleStroke.r, greaterThan(0.94));
    expect(visibleStroke.g, lessThan(0.08));
    expect(visibleStroke.b, lessThan(0.08));
  });
}

class _RenderingTestApp extends StatelessWidget {
  const _RenderingTestApp({
    required this.boundaryKey,
    required this.controller,
    this.polylines = const [],
  });

  final GlobalKey boundaryKey;
  final MapController controller;
  final List<Polyline> polylines;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox.square(
                dimension: 200,
                child: FlutterMap(
                  mapController: controller,
                  options: const MapOptions(
                    initialCenter: LatLng(0, 0),
                    initialZoom: 8,
                    backgroundColor: Colors.white,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    if (polylines.isNotEmpty)
                      PolylineLayer(
                        polylines: polylines,
                        cullingMargin: null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _CapturedPixels {
  const _CapturedPixels(this.bytes, this.width);

  final ByteData bytes;
  final int width;

  Color colorAt(int x, int y) {
    final offset = (x + y * width) * 4;
    return Color.fromARGB(
      bytes.getUint8(offset + 3),
      bytes.getUint8(offset),
      bytes.getUint8(offset + 1),
      bytes.getUint8(offset + 2),
    );
  }
}

Future<_CapturedPixels> _capturePixels(
  WidgetTester tester,
  GlobalKey boundaryKey,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await tester.runAsync(boundary.toImage);
  if (image == null) throw StateError('Failed to capture map image');
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
  );
  if (bytes == null) throw StateError('Failed to read map image pixels');
  final pixels = _CapturedPixels(bytes, image.width);
  image.dispose();
  return pixels;
}
