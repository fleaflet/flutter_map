import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_app.dart';

void main() {
  test('polyline equality is symmetric across rendering subtypes', () {
    const points = [LatLng(0, 0), LatLng(0, 1)];
    final plain = Polyline(points: points);
    final colored = MulticolorPolyline(points: points);
    expect(plain == colored, isFalse);
    expect(colored == plain, isFalse);
    final equalColored = MulticolorPolyline(points: points);
    expect(colored, equals(equalColored));
    expect(colored.hashCode, equalColored.hashCode);
  });

  testWidgets('simplified colors survive separate culled fragments',
      (tester) async {
    final controller = MapController();
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
        _RenderingTestApp(boundaryKey: boundaryKey, controller: controller));
    final points = [
      for (final offset in const [
        Offset(-400, 50),
        Offset(-300, 50),
        Offset(0, 50),
        Offset(100, 50),
        Offset(300, 50),
        Offset(400, 50),
        Offset(400, 100),
        Offset(400, 150),
        Offset(300, 150),
        Offset(200, 150),
        Offset(100, 150),
        Offset(0, 150),
        Offset(-400, 150),
      ])
        controller.camera.screenOffsetToLatLng(offset),
    ];
    final colors = [
      for (var i = 0; i < points.length; i++)
        Color.lerp(Colors.red, Colors.blue, i / (points.length - 1))!,
    ];
    final lines = [
      MulticolorPolyline(points: points, vertexColors: colors, strokeWidth: 12)
    ];
    final initialZoom = controller.camera.zoom;
    for (final zoomDelta in [0.0, 0.5, 0.75, 0.0]) {
      final zoom = initialZoom + zoomDelta;
      controller.move(controller.camera.center, zoom);
      await tester.pumpWidget(_RenderingTestApp(
        boundaryKey: boundaryKey,
        controller: controller,
        polylines: lines,
        simplificationTolerance: 0,
        cullingMargin: 10,
      ));
      final expected = await _capturePixels(tester, boundaryKey);
      await tester.pumpWidget(_RenderingTestApp(
        boundaryKey: boundaryKey,
        controller: controller,
        polylines: lines,
        simplificationTolerance: 2,
        cullingMargin: 10,
      ));
      final actual = await _capturePixels(tester, boundaryKey);
      var visibleSamples = 0;
      for (var y = 10; y < 190; y += 10) {
        final reference = expected.colorAt(100, y);
        if (reference.g < 0.5) visibleSamples++;
        final result = actual.colorAt(100, y);
        expect(result.r, closeTo(reference.r, 0.04));
        expect(result.g, closeTo(reference.g, 0.04));
        expect(result.b, closeTo(reference.b, 0.04));
      }
      expect(visibleSamples, greaterThan(0));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
  for (final cap in StrokeCap.values) {
    for (final vertical in [false, true]) {
      testWidgets('gradient segments preserve samples $cap vertical=$vertical',
          (tester) async {
        final controller = MapController();
        final boundaryKey = GlobalKey();
        Offset position(double distance) =>
            vertical ? Offset(100, distance) : Offset(distance, 100);
        await tester.pumpWidget(_RenderingTestApp(
            boundaryKey: boundaryKey, controller: controller));
        await tester.pumpWidget(_RenderingTestApp(
          boundaryKey: boundaryKey,
          controller: controller,
          polylines: [
            MulticolorPolyline(
              points: [
                for (final distance in [40.0, 100.0, 100.0, 160.0])
                  controller.camera.screenOffsetToLatLng(position(distance)),
              ],
              vertexColors: const [
                Colors.red,
                Colors.green,
                Colors.green,
                Colors.blue,
              ],
              strokeWidth: 20,
              strokeCap: cap,
            ),
          ],
        ));
        final pixels = await _capturePixels(tester, boundaryKey);
        Color sample(int distance) => vertical
            ? pixels.colorAt(100, distance)
            : pixels.colorAt(distance, 100);
        for (final (distance, expected) in [
          (70, Color.lerp(Colors.red, Colors.green, 0.5)!),
          (100, Colors.green),
          (130, Color.lerp(Colors.green, Colors.blue, 0.5)!),
          (35, cap == StrokeCap.butt ? Colors.white : Colors.red),
          (165, cap == StrokeCap.butt ? Colors.white : Colors.blue),
        ]) {
          final actual = sample(distance);
          expect(actual.r, closeTo(expected.r, 0.03));
          expect(actual.g, closeTo(expected.g, 0.03));
          expect(actual.b, closeTo(expected.b, 0.03));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
  for (final cap in StrokeCap.values) {
    for (final explicitColors in [false, true]) {
      testWidgets(
          'solid multicolor matches plain simplification $cap explicit=$explicitColors',
          (tester) async {
        final controller = MapController();
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(_RenderingTestApp(
            boundaryKey: boundaryKey, controller: controller));
        final points = [
          for (final point in const [
            Offset(-30, 50),
            Offset(40, 70),
            Offset(40, 70),
            Offset(60, 64),
            Offset(90, 130),
            Offset(170, 90),
            Offset(230, 120)
          ])
            controller.camera.screenOffsetToLatLng(point),
        ];
        await tester.pumpWidget(_RenderingTestApp(
          boundaryKey: boundaryKey,
          controller: controller,
          simplificationTolerance: 50,
          polylines: [
            Polyline(
                points: points,
                color: Colors.red,
                strokeWidth: 8,
                strokeCap: cap,
                borderStrokeWidth: 3,
                borderColor: Colors.black)
          ],
        ));
        final expected = await _capturePixels(tester, boundaryKey);
        await tester.pumpWidget(_RenderingTestApp(
          boundaryKey: boundaryKey,
          controller: controller,
          simplificationTolerance: 50,
          polylines: [
            MulticolorPolyline(
                points: points,
                defaultColor: Colors.red,
                vertexColors: explicitColors
                    ? List.filled(points.length, Colors.red)
                    : null,
                strokeWidth: 8,
                strokeCap: cap,
                borderStrokeWidth: 3,
                borderColor: Colors.black)
          ],
        ));
        final actual = await _capturePixels(tester, boundaryKey);
        expect(actual.bytes.buffer.asUint8List(),
            orderedEquals(expected.bytes.buffer.asUint8List()));
        expect(tester.takeException(), isNull);
      });
    }
  }
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
    this.simplificationTolerance = 0.4,
    this.cullingMargin,
  });

  final GlobalKey boundaryKey;
  final MapController controller;
  final List<Polyline> polylines;
  final double simplificationTolerance;
  final double? cullingMargin;

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
                        cullingMargin: cullingMargin,
                        simplificationTolerance: simplificationTolerance,
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
