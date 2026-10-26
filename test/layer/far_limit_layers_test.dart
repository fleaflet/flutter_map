import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../test_utils/test_tile_provider.dart';

const _size = Size(400, 300);
const _center = LatLng(45.5, -122.6);
const _background = Color(0xFF0000FF);
const _red = Color(0xFFFF0000);

final _boundary = GlobalKey();

Future<MapController> _pump(
  WidgetTester tester, {
  double rotation = 0,
  required List<Widget> children,
}) async {
  final controller = MapController();
  await tester.pumpWidget(MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: _boundary,
        child: SizedBox.fromSize(
          size: _size,
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              initialRotation: rotation,
              initialPitch: 85,
              maxPitch: 85,
              backgroundColor: _background,
            ),
            children: children,
          ),
        ),
      ),
    ),
  ));
  return controller;
}

/// The rendered map, after letting tile images load.
Future<_Pixels> _render(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final data = await tester.runAsync(() async {
    final image = await boundary.toImage();
    return image.toByteData();
  });
  return _Pixels(data!);
}

class _Pixels {
  final ByteData data;

  const _Pixels(this.data);

  Color at(int x, int y) {
    final value = data.getUint32((y * _size.width.toInt() + x) * 4);
    return Color(((value & 0xFF) << 24) | (value >> 8));
  }
}

/// A polygon from far beyond the far limit to latitude [south], 2 degrees of
/// longitude wide. The default [south] is behind the camera.
Polygon<String> _band({double south = 40}) => Polygon(
      points: [
        const LatLng(65, -123.6),
        const LatLng(65, -121.6),
        LatLng(south, -121.6),
        LatLng(south, -123.6),
      ],
      color: _red,
      hitValue: 'band',
    );

bool _inBand(LatLng coordinate, {double south = 40}) =>
    coordinate.latitude > south &&
    coordinate.latitude < 65 &&
    coordinate.longitude > -123.6 &&
    coordinate.longitude < -121.6;

void main() {
  for (final rotation in [0.0, 45.0]) {
    testWidgets(
        'tiles cover the viewport below the far limit and nothing above, '
        'rotation $rotation', (tester) async {
      final controller = await _pump(
        tester,
        rotation: rotation,
        children: [
          TileLayer(
            tileProvider: TestTileProvider(),
            tileDisplay: const TileDisplay.instantaneous(),
          ),
        ],
      );
      final pixels = await _render(tester);
      final farLimit = controller.camera.farLimit;
      expect(farLimit, inExclusiveRange(10, 290));
      for (var y = 0; y < 300; y += 3) {
        if ((y - farLimit).abs() < 2) continue;
        for (var x = 0; x < 400; x += 7) {
          expect(
            pixels.at(x, y),
            y < farLimit ? _background : const Color(0xFFFFFFFF),
            reason: '($x, $y)',
          );
        }
      }
    });
  }

  testWidgets('polygon beyond the far limit', (tester) async {
    // In front of the camera: Flutter 3.27 draws nothing of a polygon with a
    // vertex behind it.
    const south = 45.45;
    final controller = await _pump(
      tester,
      rotation: 30,
      children: [
        PolygonLayer(polygons: [_band(south: south)]),
      ],
    );
    final pixels = await _render(tester);
    final camera = controller.camera;
    final farLimit = camera.farLimit;
    var inside = 0;
    for (var y = 0; y < 300; y += 3) {
      if ((y - farLimit).abs() < 2) continue;
      for (var x = 0; x < 400; x += 2) {
        final Color expected;
        if (y < farLimit) {
          expected = _background;
        } else {
          final neighbors = [
            for (final dx in const [-3, 0, 3])
              for (final dy in const [-3, 0, 3])
                _inBand(
                  camera
                      .screenOffsetToLatLng(Offset(x + 0.5 + dx, y + 0.5 + dy)),
                  south: south,
                ),
          ];
          if (neighbors.toSet().length > 1) continue;
          expected = neighbors.first ? _red : _background;
          if (neighbors.first) inside++;
        }
        expect(pixels.at(x, y), expected, reason: '($x, $y)');
      }
    }
    expect(inside, greaterThan(100));
  });

  testWidgets('polygon near the far limit is drawn', (tester) async {
    final controller = await _pump(tester, children: []);
    final camera = controller.camera;
    final farLimit = camera.farLimit;
    final near = camera.screenOffsetToLatLng(Offset(150, farLimit + 6));
    final far = camera.screenOffsetToLatLng(Offset(250, farLimit + 1));
    await _pump(tester, children: [
      PolygonLayer(polygons: [
        Polygon(
          points: [
            LatLng(far.latitude, near.longitude),
            LatLng(far.latitude, far.longitude),
            LatLng(near.latitude, far.longitude),
            LatLng(near.latitude, near.longitude),
          ],
          color: _red,
        ),
      ]),
    ]);
    final pixels = await _render(tester);
    final y = (farLimit + 3).round();
    expect(pixels.at(200, y), _red);
  });

  testWidgets('tap above the far limit hits nothing', (tester) async {
    final hitNotifier = LayerHitNotifier<String>(null);
    final hits = <LayerHitResult<String>?>[];
    final controller = await _pump(
      tester,
      children: [
        GestureDetector(
          onTap: () => hits.add(hitNotifier.value),
          child: PolygonLayer(hitNotifier: hitNotifier, polygons: [_band()]),
        ),
      ],
    );
    final farLimit = controller.camera.farLimit;
    for (final (position, hit) in [
      (Offset(200, farLimit - 20), false),
      (const Offset(200, 5), false),
      (Offset(200, farLimit + 20), true),
      (const Offset(200, 290), true),
    ]) {
      hits.clear();
      await tester.tapAt(position);
      await tester.pump(const Duration(milliseconds: 500));
      expect(hits.isNotEmpty && hits.last != null, hit, reason: '$position');
      if (hit) expect(hits.last!.hitValues, ['band']);
    }
  });

  testWidgets('markers beyond the far limit and in other worlds are not built',
      (tester) async {
    // With rotation 90, the copies of a marker in the worlds to the east
    // converge to the middle of the horizon, which is in the viewport.
    await _pump(
      tester,
      rotation: 90,
      children: [
        MarkerLayer(
          markers: [
            for (final (key, point) in const [
              ('near', _center),
              ('far', LatLng(60, -122.6)),
            ])
              Marker(
                point: point,
                width: 20,
                height: 20,
                child: SizedBox.expand(key: ValueKey(key)),
              ),
          ],
        ),
      ],
    );
    expect(find.byKey(const ValueKey('near')), findsOneWidget);
    expect(find.byKey(const ValueKey('far')), findsNothing);
  });

  testWidgets('polygon labels are drawn only below the far limit',
      (tester) async {
    Polygon square(double lat, String label) => Polygon(
          points: [
            LatLng(lat + 0.05, -122.65),
            LatLng(lat + 0.05, -122.55),
            LatLng(lat - 0.05, -122.55),
            LatLng(lat - 0.05, -122.65),
          ],
          label: label,
        );
    final near = square(45.5, 'near');
    // As for markers, the copies to the east converge to the middle of the
    // horizon at rotation 90.
    final controller = await _pump(
      tester,
      rotation: 90,
      children: [
        PolygonLayer(polygons: [near, square(60, 'far')]),
      ],
    );
    final centers = _paragraphCenters(
      tester,
      find.descendant(
        of: find.byType(BillboardLayerTransformer),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(centers, hasLength(1));
    final expected = controller.camera.latLngToScreenOffset(near.labelPosition);
    expect((centers.single - expected).distance, lessThan(0.01));
  });
}

/// The screen centers of the paragraphs that the [CustomPaint] [paint] draws.
List<Offset> _paragraphCenters(WidgetTester tester, Finder paint) {
  final box = tester.renderObject<RenderCustomPaint>(paint);
  final canvas = TestRecordingCanvas();
  box.painter!.paint(canvas, box.size);
  final saved = <Matrix4>[];
  var transform = box.getTransformTo(null);
  final centers = <Offset>[];
  for (final recorded in canvas.invocations) {
    final args = recorded.invocation.positionalArguments;
    switch (recorded.invocation.memberName) {
      case #save || #saveLayer:
        saved.add(transform.clone());
      case #restore:
        transform = saved.removeLast();
      case #translate:
        transform.multiply(
            Matrix4.translationValues(args[0] as double, args[1] as double, 0));
      case #rotate:
        transform.rotateZ(args[0] as double);
      case #drawParagraph:
        final paragraph = args[0] as ui.Paragraph;
        final offset = args[1] as Offset;
        centers.add(MatrixUtils.transformPoint(transform,
            offset + Offset(paragraph.width / 2, paragraph.height / 2)));
    }
  }
  return centers;
}
