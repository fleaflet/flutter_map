import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_tile_provider.dart';

Future<MapController> _pump(
  WidgetTester tester, {
  required double pitch,
  required double rotation,
  required List<Widget> children,
  LatLng center = const LatLng(45.5, -122.6),
  double zoom = 12,
  TapCallback? onTap,
}) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400,
        height: 300,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            initialRotation: rotation,
            initialPitch: pitch,
            maxPitch: 60,
            onTap: onTap,
          ),
          children: children,
        ),
      ),
    ),
  ));
  return controller;
}

/// The screen positions of the start and end of each path that the
/// [CustomPaint] under [layer] draws.
List<(Offset, Offset)> _pathEnds(WidgetTester tester, Finder layer) {
  final box = tester.renderObject<RenderCustomPaint>(
    find.descendant(of: layer, matching: find.byType(CustomPaint)),
  );
  final canvas = TestRecordingCanvas();
  box.painter!.paint(canvas, box.size);
  final toScreen = box.getTransformTo(null);
  final saved = <Matrix4>[];
  var transform = Matrix4.identity();
  final ends = <(Offset, Offset)>[];
  for (final recorded in canvas.invocations) {
    final args = recorded.invocation.positionalArguments;
    switch (recorded.invocation.memberName) {
      case #save || #saveLayer:
        saved.add(transform.clone());
      case #restore:
        transform = saved.removeLast();
      case #translate:
        transform.translateByDouble(args[0] as double, args[1] as double, 0, 1);
      case #transform:
        transform.multiply(Matrix4.fromFloat64List(args[0] as Float64List));
      case #drawPath:
        final matrix = toScreen.multiplied(transform);
        for (final metric in (args[0] as ui.Path).computeMetrics()) {
          ends.add((
            MatrixUtils.transformPoint(
                matrix, metric.getTangentForOffset(0)!.position),
            MatrixUtils.transformPoint(
                matrix, metric.getTangentForOffset(metric.length)!.position),
          ));
        }
    }
  }
  return ends;
}

/// The screen corners of each [Tile] that the map shows, with its tile
/// coordinates.
Future<List<(TileCoordinates, List<Offset>)>> _tileQuads(
    WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 100),
      ));
  await tester.pumpAndSettle();
  return [
    for (final element in find.byType(Tile).evaluate())
      (
        (element.widget as Tile).tileImage.coordinates,
        () {
          final box = tester.renderObject<RenderBox>(find.descendant(
            of: find.byWidget(element.widget),
            matching: find.byType(RawImage),
          ));
          final toScreen = box.getTransformTo(null);
          return [
            Offset.zero,
            Offset(box.size.width, 0),
            Offset(box.size.width, box.size.height),
            Offset(0, box.size.height),
          ].map((c) => MatrixUtils.transformPoint(toScreen, c)).toList();
        }(),
      ),
  ];
}

/// The screen center, angle and screen width, and the width, of each
/// paragraph that the [CustomPaint] [paint] draws.
List<(Offset, double, double, double)> _paragraphs(
    WidgetTester tester, Finder paint) {
  final box = tester.renderObject<RenderCustomPaint>(paint);
  final canvas = TestRecordingCanvas();
  box.painter!.paint(canvas, box.size);
  final toScreen = box.getTransformTo(null);
  final saved = <Matrix4>[];
  var transform = Matrix4.identity();
  final paragraphs = <(Offset, double, double, double)>[];
  for (final recorded in canvas.invocations) {
    final args = recorded.invocation.positionalArguments;
    switch (recorded.invocation.memberName) {
      case #save || #saveLayer:
        saved.add(transform.clone());
      case #restore:
        transform = saved.removeLast();
      case #translate:
        transform.translateByDouble(args[0] as double, args[1] as double, 0, 1);
      case #rotate:
        transform.rotateZ(args[0] as double);
      case #drawParagraph:
        final paragraph = args[0] as ui.Paragraph;
        final offset = args[1] as Offset;
        final matrix = toScreen.multiplied(transform);
        final center = MatrixUtils.transformPoint(
            matrix, offset + Offset(paragraph.width / 2, paragraph.height / 2));
        final right = MatrixUtils.transformPoint(
            matrix, offset + Offset(paragraph.width, paragraph.height / 2));
        final half = right - center;
        paragraphs.add((
          center,
          atan2(half.dy, half.dx),
          2 * half.distance,
          paragraph.width,
        ));
    }
  }
  return paragraphs;
}

bool _insideConvex(List<Offset> quad, Offset point) {
  var sign = 0;
  for (int i = 0; i < quad.length; i++) {
    final a = quad[i];
    final b = quad[(i + 1) % quad.length];
    final cross =
        (b.dx - a.dx) * (point.dy - a.dy) - (b.dy - a.dy) * (point.dx - a.dx);
    if (cross == 0) continue;
    final s = cross.sign.toInt();
    if (sign == 0) {
      sign = s;
    } else if (s != sign) {
      return false;
    }
  }
  return true;
}

void main() {
  for (final (pitch, rotation) in [(50.0, 20.0), (0.0, 20.0)]) {
    testWidgets('polyline vertices, pitch $pitch, rotation $rotation',
        (tester) async {
      const points = [
        LatLng(45.53, -122.64),
        LatLng(45.50, -122.60),
        LatLng(45.47, -122.55),
      ];
      final controller = await _pump(
        tester,
        pitch: pitch,
        rotation: rotation,
        children: [
          PolylineLayer(polylines: [
            Polyline(points: points, strokeWidth: 2, color: Colors.red),
          ]),
        ],
      );
      final ends = _pathEnds(tester, find.byType(PolylineLayer));
      expect(ends, hasLength(1));
      final (start, end) = ends.single;
      final camera = controller.camera;
      expect(
        (start - camera.latLngToScreenOffset(points.first)).distance,
        lessThan(0.01),
      );
      expect(
        (end - camera.latLngToScreenOffset(points.last)).distance,
        lessThan(0.01),
      );
    });
  }

  for (final rotation in [0.0, 45.0]) {
    testWidgets('tiles cover the viewport, rotation $rotation', (tester) async {
      await _pump(
        tester,
        pitch: 60,
        rotation: rotation,
        children: [
          TileLayer(
            tileProvider: TestTileProvider(),
            tileDisplay: const TileDisplay.instantaneous(),
          ),
        ],
      );
      final quads = await _tileQuads(tester);
      expect(quads, isNotEmpty);
      for (double x = 0.5; x <= 400; x += 399 / 8) {
        for (double y = 0.5; y <= 300; y += 299 / 6) {
          expect(
            quads.any((q) => _insideConvex(q.$2, Offset(x, y))),
            isTrue,
            reason: 'no tile at ($x, $y)',
          );
        }
      }
    });
  }

  testWidgets('tile under the top edge is loaded', (tester) async {
    final controller = await _pump(
      tester,
      pitch: 60,
      rotation: 0,
      children: [
        TileLayer(
          tileProvider: TestTileProvider(),
          tileDisplay: const TileDisplay.instantaneous(),
        ),
      ],
    );
    final camera = controller.camera;
    final top = camera.projectAtZoom(
        camera.screenOffsetToLatLng(const Offset(200, 1)), 12);
    final expected =
        TileCoordinates((top.dx / 256).floor(), (top.dy / 256).floor(), 12);
    final quads = await _tileQuads(tester);
    expect(quads.map((q) => q.$1), contains(expected));
  });

  for (final rotate in [true, false]) {
    testWidgets('marker position, size and rotation, rotate $rotate',
        (tester) async {
      const point = LatLng(45.535, -122.6);
      final controller = await _pump(
        tester,
        pitch: 60,
        rotation: 30,
        children: [
          MarkerLayer(
            rotate: rotate,
            markers: const [
              Marker(
                point: point,
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,
                child: SizedBox.expand(key: ValueKey('marker')),
              ),
            ],
          ),
        ],
      );
      final camera = controller.camera;
      final anchor = camera.latLngToScreenOffset(point);
      expect(anchor.dy, lessThan(100), reason: 'near the top of the view');

      // With topCenter alignment, the point is at the middle of the bottom
      // edge, and the marker rotates with the map about it unless upright.
      final angle = rotate ? 0.0 : camera.rotationRad;
      Offset corner(double x, double y) =>
          anchor +
          Offset(
              x * cos(angle) - y * sin(angle), x * sin(angle) + y * cos(angle));
      final marker = find.byKey(const ValueKey('marker'));
      for (final (actual, expected) in [
        (tester.getTopLeft(marker), corner(-24, -48)),
        (tester.getTopRight(marker), corner(24, -48)),
        (tester.getBottomRight(marker), corner(24, 0)),
        (tester.getBottomLeft(marker), corner(-24, 0)),
      ]) {
        expect((actual - expected).distance, lessThan(0.01));
      }
    });
  }

  testWidgets('marker behind the camera is not built', (tester) async {
    // In a 300 px high view at pitch 60, ground points more than 520 px south
    // of the center are behind the camera. Projected anyway, a point far
    // behind lands just above the view, where a tall marker reaches into it.
    const center = LatLng(45.5, -122.6);
    const crs = Epsg3857();
    final behind = crs.offsetToLatLng(
        crs.latLngToOffset(center, 12) + const Offset(0, 10000), 12);
    await _pump(
      tester,
      pitch: 60,
      rotation: 0,
      children: [
        MarkerLayer(
          markers: [
            Marker(
              point: behind,
              width: 20,
              height: 400,
              child: const SizedBox.expand(key: ValueKey('behind')),
            ),
          ],
        ),
      ],
    );
    expect(find.byKey(const ValueKey('behind')), findsNothing);
  });

  testWidgets('polygon labels face the viewer', (tester) async {
    Polygon square(double lat, double lng, String label, bool rotateLabel) =>
        Polygon(
          points: [
            LatLng(lat + 0.02, lng - 0.03),
            LatLng(lat + 0.02, lng + 0.03),
            LatLng(lat - 0.02, lng + 0.03),
            LatLng(lat - 0.02, lng - 0.03),
          ],
          color: Colors.green,
          label: label,
          rotateLabel: rotateLabel,
        );
    final polygons = [
      square(45.51, -122.62, 'A', false),
      square(45.49, -122.57, 'B', true),
    ];
    final controller = await _pump(
      tester,
      pitch: 45,
      rotation: 30,
      children: [PolygonLayer(polygons: polygons)],
    );
    final camera = controller.camera;
    final paints = find.descendant(
        of: find.byType(PolygonLayer), matching: find.byType(CustomPaint));
    final ground = find.descendant(
        of: find.byType(MobileLayerTransformer), matching: paints);
    final billboard = find.descendant(
        of: find.byType(BillboardLayerTransformer), matching: paints);
    expect(_paragraphs(tester, ground), isEmpty);

    final labels = _paragraphs(tester, billboard);
    expect(labels, hasLength(2));
    for (final (i, (center, angle, screenWidth, width)) in labels.indexed) {
      final expected = camera.latLngToScreenOffset(polygons[i].labelPosition);
      expect((center - expected).distance, lessThan(0.01));
      expect(screenWidth, closeTo(width, 0.01));
      expect(angle,
          closeTo(polygons[i].rotateLabel ? 0 : camera.rotationRad, 1e-9));
    }
  });

  testWidgets('tiles on both sides of the antimeridian', (tester) async {
    // With rotation -90, the far edge of the view is east of the center,
    // across the antimeridian.
    await _pump(
      tester,
      pitch: 60,
      rotation: -90,
      center: const LatLng(0, 179),
      zoom: 9,
      children: [
        TileLayer(
          tileProvider: TestTileProvider(),
          tileDisplay: const TileDisplay.instantaneous(),
        ),
      ],
    );
    final quads = await _tileQuads(tester);
    final columns = quads.map((q) => q.$1.x).toSet();
    expect(columns, contains(511), reason: 'west of the antimeridian');
    expect(columns.any((x) => x > 511 || x <= 1), isTrue,
        reason: 'east of the antimeridian');
    for (double x = 0.5; x <= 400; x += 399 / 8) {
      for (double y = 0.5; y <= 300; y += 299 / 6) {
        expect(
          quads.any((q) => _insideConvex(q.$2, Offset(x, y))),
          isTrue,
          reason: 'no tile at ($x, $y)',
        );
      }
    }
  });

  testWidgets('tap coordinate', (tester) async {
    final taps = <LatLng>[];
    final controller = await _pump(
      tester,
      pitch: 60,
      rotation: 30,
      children: const [],
      onTap: (_, point) => taps.add(point),
    );
    for (final position in const [Offset(350, 10), Offset(40, 280)]) {
      await tester.tapAt(position);
      await tester.pump(const Duration(milliseconds: 500));
      final expected = controller.camera.screenOffsetToLatLng(position);
      expect(taps.last.latitude, closeTo(expected.latitude, 1e-9));
      expect(taps.last.longitude, closeTo(expected.longitude, 1e-9));
    }
  });

  testWidgets('polygon hit near the top of the view', (tester) async {
    final hitNotifier = LayerHitNotifier<String>(null);
    final hits = <LayerHitResult<String>?>[];
    final controller = await _pump(
      tester,
      pitch: 60,
      rotation: 30,
      children: [
        GestureDetector(
          onTap: () => hits.add(hitNotifier.value),
          child: PolygonLayer(
            hitNotifier: hitNotifier,
            polygons: [
              for (final (value, lng) in [('west', -122.63), ('east', -122.6)])
                Polygon(
                  points: [
                    LatLng(45.552, lng - 0.012),
                    LatLng(45.552, lng + 0.012),
                    LatLng(45.544, lng + 0.012),
                    LatLng(45.544, lng - 0.012),
                  ],
                  label: value,
                  hitValue: value,
                ),
            ],
          ),
        ),
      ],
    );
    for (final (value, lng) in [('west', -122.63), ('east', -122.6)]) {
      final position =
          controller.camera.latLngToScreenOffset(LatLng(45.548, lng));
      expect(position.dy, lessThan(100), reason: 'near the top of the view');
      await tester.tapAt(position);
      await tester.pump(const Duration(milliseconds: 500));
      expect(hits.last?.hitValues, [value]);
      expect(hits.last!.coordinate.latitude, closeTo(45.548, 1e-7));
      expect(hits.last!.coordinate.longitude, closeTo(lng, 1e-7));
    }
  });
}
