import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// Screen positions of markers and polygon labels, recorded before pitch
// support was added, so that layer changes for pitch can be shown to draw at
// the same positions when the map is not pitched.

const _center = LatLng(45.5, -122.6);

Widget _map({
  required double rotation,
  required List<Widget> children,
  double zoom = 10,
  LatLng center = _center,
}) =>
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: 400,
          height: 300,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              initialRotation: rotation,
            ),
            children: children,
          ),
        ),
      ),
    );

const _markers = [
  Marker(
    point: _center,
    width: 40,
    height: 20,
    child: SizedBox.expand(key: ValueKey('center')),
  ),
  Marker(
    point: LatLng(45.52, -122.55),
    alignment: Alignment.topCenter,
    child: SizedBox.expand(key: ValueKey('topCenter')),
  ),
  Marker(
    point: LatLng(45.47, -122.66),
    width: 50,
    height: 16,
    alignment: Alignment.bottomRight,
    rotate: true,
    child: SizedBox.expand(key: ValueKey('bottomRightRotate')),
  ),
  Marker(
    point: LatLng(45.49, -122.58),
    width: 2000,
    height: 1000,
    useDimensionsInMeters: BoxConstraints(),
    child: SizedBox.expand(key: ValueKey('meters')),
  ),
];

double _round(double v) => (v * 100).round() / 100;

/// The screen corners (top left, top right, bottom right, bottom left) of each
/// widget with [key], as a flat list per widget.
List<List<double>> _corners(WidgetTester tester, String key) {
  final finder = find.byKey(ValueKey(key));
  return [
    for (int i = 0; i < finder.evaluate().length; i++)
      [
        for (final corner in [
          tester.getTopLeft(finder.at(i)),
          tester.getTopRight(finder.at(i)),
          tester.getBottomRight(finder.at(i)),
          tester.getBottomLeft(finder.at(i)),
        ]) ...[_round(corner.dx), _round(corner.dy)],
      ],
  ];
}

/// The order in which the polygon layer draws polygons (`P`) and labels
/// (`L`), and the screen position and angle of the center of each label.
({String order, List<List<double>> labels}) _polygonPaint(
  WidgetTester tester,
) {
  final box = tester.renderObject<RenderCustomPaint>(
    find.descendant(
      of: find.byType(PolygonLayer),
      matching: find.byType(CustomPaint),
    ),
  );
  final canvas = TestRecordingCanvas();
  box.painter!.paint(canvas, box.size);

  final toScreen = box.getTransformTo(null);
  final saved = <Matrix4>[];
  var transform = Matrix4.identity();
  final order = StringBuffer();
  final labels = <List<double>>[];
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
      case #transform:
        transform.multiply(Matrix4.fromFloat64List(args[0] as Float64List));
      case #drawPath || #drawVertices:
        order.write('P');
      case #drawParagraph:
        order.write('L');
        final paragraph = args[0] as ui.Paragraph;
        final offset = args[1] as Offset;
        final matrix = toScreen.multiplied(transform);
        final center = MatrixUtils.transformPoint(
          matrix,
          offset + Offset(paragraph.width / 2, paragraph.height / 2),
        );
        final right = MatrixUtils.transformPoint(
          matrix,
          offset + Offset(paragraph.width, paragraph.height / 2),
        );
        final direction = right - center;
        labels.add([
          _round(center.dx),
          _round(center.dy),
          _round(atan2(direction.dy, direction.dx)),
        ]);
    }
  }
  return (order: order.toString(), labels: labels);
}

List<Polygon> _polygons() => [
      Polygon(
        points: const [
          LatLng(45.56, -122.70),
          LatLng(45.56, -122.58),
          LatLng(45.50, -122.58),
          LatLng(45.50, -122.70),
        ],
        color: const Color(0xFFFF0000),
        label: 'A',
      ),
      Polygon(
        points: const [
          LatLng(45.53, -122.62),
          LatLng(45.53, -122.50),
          LatLng(45.46, -122.50),
          LatLng(45.46, -122.62),
        ],
        color: const Color(0xFF00FF00),
        label: 'B',
        rotateLabel: true,
      ),
      Polygon(
        points: const [
          LatLng(45.48, -122.72),
          LatLng(45.48, -122.60),
          LatLng(45.42, -122.60),
          LatLng(45.42, -122.72),
        ],
        color: const Color(0xFF0000FF),
        label: 'C',
      ),
    ];

void _expectClose(List<List<double>> actual, List<List<double>> expected) {
  expect(actual.length, expected.length);
  for (int i = 0; i < actual.length; i++) {
    expect(actual[i].length, expected[i].length);
    for (int j = 0; j < actual[i].length; j++) {
      expect(actual[i][j], closeTo(expected[i][j], 0.01), reason: '[$i][$j]');
    }
  }
}

const _uprightMarkers = {
  'center': [
    [380.0, 290.0, 420.0, 290.0, 420.0, 310.0, 380.0, 310.0],
  ],
  'topCenter': [
    [421.41, 249.22, 451.41, 249.22, 451.41, 279.22, 421.41, 279.22],
  ],
  'bottomRightRotate': [
    [356.31, 331.16, 406.31, 331.16, 406.31, 347.16, 356.31, 347.16],
  ],
  'meters': [
    [405.25, 305.72, 423.88, 305.72, 423.88, 315.06, 405.25, 315.06],
  ],
};

final _expectedMarkers = {
  (0.0, false): _uprightMarkers,
  (0.0, true): _uprightMarkers,
  (30.0, false): {
    'center': [
      [387.68, 281.34, 422.32, 301.34, 412.32, 318.66, 377.68, 298.66],
    ],
    'topCenter': [
      [443.93, 266.73, 469.91, 281.73, 454.91, 307.71, 428.93, 292.71],
    ],
    'bottomRightRotate': [
      [346.58, 305.14, 396.58, 305.14, 396.58, 321.14, 346.58, 321.14],
    ],
    'meters': [
      [401.69, 307.57, 417.82, 316.89, 413.15, 324.98, 397.01, 315.67],
    ],
  },
  (30.0, true): {
    'center': [
      [380.0, 290.0, 420.0, 290.0, 420.0, 310.0, 380.0, 310.0],
    ],
    'topCenter': [
      [426.92, 270.21, 456.92, 270.21, 456.92, 300.21, 426.92, 300.21],
    ],
    'bottomRightRotate': [
      [346.58, 305.14, 396.58, 305.14, 396.58, 321.14, 346.58, 321.14],
    ],
    'meters': [
      [398.1, 311.61, 416.73, 311.61, 416.73, 320.95, 398.1, 320.95],
    ],
  },
};

final _expectedLabels = {
  0.0: [
    [370.87, 268.82, 0.0],
    [429.13, 305.19, 0.0],
    [356.31, 351.92, 0.0],
  ],
  30.0: [
    [390.36, 258.44, 0.52],
    [422.63, 319.06, 0.0],
    [336.2, 323.12, 0.52],
  ],
};

void main() {
  for (final MapEntry(key: (rotation, layerRotate), value: expected)
      in _expectedMarkers.entries) {
    testWidgets('marker corners, rotation $rotation, layer rotate $layerRotate',
        (tester) async {
      await tester.pumpWidget(_map(
        rotation: rotation,
        children: [MarkerLayer(markers: _markers, rotate: layerRotate)],
      ));
      for (final MapEntry(:key, :value) in expected.entries) {
        _expectClose(_corners(tester, key), value);
      }
    });
  }

  testWidgets('marker corners in repeated worlds', (tester) async {
    await tester.pumpWidget(_map(
      rotation: 0,
      zoom: 0,
      center: const LatLng(0, 0),
      children: const [
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(10, -170),
              width: 20,
              height: 10,
              child: SizedBox.expand(key: ValueKey('wrapped')),
            ),
          ],
        ),
      ],
    ));
    _expectClose(_corners(tester, 'wrapped'), [
      [269.11, 287.85, 289.11, 287.85, 289.11, 297.85, 269.11, 297.85],
      [525.11, 287.85, 545.11, 287.85, 545.11, 297.85, 525.11, 297.85],
    ]);
  });

  for (final MapEntry(key: rotation, value: expected)
      in _expectedLabels.entries) {
    for (final (drawLabelsLast, order) in [
      (false, 'PLPLPL'),
      (true, 'PPPLLL')
    ]) {
      testWidgets(
          'polygon labels, rotation $rotation, drawLabelsLast $drawLabelsLast',
          (tester) async {
        await tester.pumpWidget(_map(
          rotation: rotation,
          children: [
            PolygonLayer(polygons: _polygons(), drawLabelsLast: drawLabelsLast),
          ],
        ));
        final actual = _polygonPaint(tester);
        expect(actual.order, order);
        _expectClose(actual.labels, expected);
      });
    }
  }
}
