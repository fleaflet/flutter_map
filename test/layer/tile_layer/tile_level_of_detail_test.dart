import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../test_utils/test_tile_image.dart';

const _size = Size(400, 800);
const _center = LatLng(45.52, -122.68);

/// Records the tiles in the order they start loading. While [pending], new
/// tiles never finish loading.
class _RecordingTileProvider extends TileProvider {
  final loads = <TileCoordinates>[];
  bool pending = false;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _RecordingImage(coordinates, this);
}

class _RecordingImage extends ImageProvider<_RecordingImage> {
  final TileCoordinates coordinates;
  final _RecordingTileProvider provider;

  _RecordingImage(this.coordinates, this.provider);

  @override
  Future<_RecordingImage> obtainKey(ImageConfiguration configuration) {
    provider.loads.add(coordinates);
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _RecordingImage key,
    ImageDecoderCallback decode,
  ) =>
      provider.pending
          ? OneFrameImageStreamCompleter(Completer<ImageInfo>().future)
          : testWhiteTileImage.loadImage(testWhiteTileImage, decode);
}

Future<(MapController, _RecordingTileProvider)> _pump(
  WidgetTester tester, {
  required double pitch,
  double rotation = 0,
  double zoom = 14,
  int maxNativeZoom = 19,
}) async {
  tester.view
    ..physicalSize = _size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = MapController();
  final provider = _RecordingTileProvider();
  await tester.pumpWidget(MaterialApp(
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: _size,
        child: FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: zoom,
            initialRotation: rotation,
            initialPitch: pitch,
            maxPitch: 60,
          ),
          children: [
            TileLayer(
              tileProvider: provider,
              maxNativeZoom: maxNativeZoom,
              tileDisplay: const TileDisplay.instantaneous(),
            ),
          ],
        ),
      ),
    ),
  ));
  return (controller, provider);
}

Future<void> _decode(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump();
}

TileCoordinates _tileAt(MapCamera camera, Offset screen, int zoom) {
  final pixel = camera.projectAtZoom(
      camera.screenOffsetToLatLng(screen), zoom.toDouble());
  return TileCoordinates(
      (pixel.dx / 256).floor(), (pixel.dy / 256).floor(), zoom);
}

/// The tiles at [zooms] that the visible ground touches, from screen positions
/// [step] apart.
Set<TileCoordinates> _touched(
  MapCamera camera,
  Iterable<int> zooms, {
  double step = 2,
}) =>
    {
      for (var y = 0.0; y <= _size.height; y += step)
        for (var x = 0.0; x <= _size.width; x += step)
          for (final z in zooms) _tileAt(camera, Offset(x, y), z),
    };

bool _isNeighbor(TileCoordinates a, TileCoordinates b) =>
    a.z == b.z && (a.x - b.x).abs() <= 1 && (a.y - b.y).abs() <= 1;

/// Every loaded tile touches the visible ground, or is a neighbor of a loaded
/// tile that does.
void _expectTouchingOrNeighbors(MapCamera camera, Set<TileCoordinates> loads) {
  final touched = _touched(camera, loads.map((t) => t.z).toSet());
  final touching = loads.intersection(touched);
  for (final tile in loads.difference(touching)) {
    expect(touching.any((t) => _isNeighbor(t, tile)), isTrue, reason: '$tile');
  }
}

void main() {
  testWidgets('coarser tiles far away', (tester) async {
    final (controller, provider) = await _pump(tester, pitch: 60);
    final camera = controller.camera;
    final loads = provider.loads.toSet();
    expect(loads, contains(_tileAt(camera, _size.center(Offset.zero), 14)));
    final top = Offset(_size.width / 2, 1);
    expect(
      loads.where((t) => t.z < 14 && t == _tileAt(camera, top, t.z)),
      isNotEmpty,
    );
  });

  testWidgets('no finer tiles near the camera', (tester) async {
    final (controller, provider) = await _pump(tester, pitch: 60, zoom: 14.45);
    final bottom = Offset(_size.width / 2, _size.height - 1);
    expect(provider.loads.map((t) => t.z), everyElement(lessThanOrEqualTo(14)));
    expect(provider.loads, contains(_tileAt(controller.camera, bottom, 14)));
  });

  testWidgets('maximum native zoom', (tester) async {
    final (_, provider) =
        await _pump(tester, pitch: 60, zoom: 14.45, maxNativeZoom: 13);
    expect(provider.loads, isNotEmpty);
    expect(provider.loads.map((t) => t.z), everyElement(lessThanOrEqualTo(13)));
  });

  testWidgets('rotated map', (tester) async {
    final (controller, provider) = await _pump(tester, pitch: 0, rotation: 45);
    final loads = provider.loads.toSet();
    expect(loads.map((t) => t.z).toSet(), {14});
    _expectTouchingOrNeighbors(controller.camera, loads);

    final touched = _touched(controller.camera, const [14]);
    int extent(Iterable<int> values) =>
        values.reduce(max) - values.reduce(min) + 1;
    final boundingBoxWithBuffer = (extent(touched.map((t) => t.x)) + 2) *
        (extent(touched.map((t) => t.y)) + 2);
    expect(loads.length, lessThan(boundingBoxWithBuffer));
  });

  testWidgets('pitched and rotated map', (tester) async {
    final (controller, provider) = await _pump(tester, pitch: 60, rotation: 45);
    final loads = provider.loads.toSet();
    expect(loads.map((t) => t.z).toSet().length, greaterThan(1));
    _expectTouchingOrNeighbors(controller.camera, loads);
  });

  testWidgets('every position shows a tile at pitch 60 while tiles load',
      (tester) async {
    final (controller, provider) = await _pump(tester, pitch: 60);
    await _decode(tester);
    provider.pending = true;
    final loaded = provider.loads.length;

    controller.moveAndRotate(_center, 14.45, 10);
    await tester.pump();
    await _decode(tester);
    expect(provider.loads.length, greaterThan(loaded));

    final quads = [
      for (final element in find.byType(Tile).evaluate())
        if ((element.widget as Tile).tileImage.readyToDisplay)
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
    ];
    for (var y = 0.5; y < _size.height; y += 25) {
      for (var x = 0.5; x < _size.width; x += 25) {
        expect(
          quads.any((q) => _insideConvex(q, Offset(x, y))),
          isTrue,
          reason: 'no tile at ($x, $y)',
        );
      }
    }
  });

  testWidgets('pitched load order', (tester) async {
    final (controller, provider) = await _pump(tester, pitch: 60);
    final loaded = provider.loads.length;

    controller.move(const LatLng(45.6, -122.4), 14);
    await tester.pump();
    final camera = controller.camera;
    final newLoads = provider.loads.sublist(loaded);
    expect(newLoads.length, greaterThan(10));
    final distances = [
      for (final t in newLoads)
        (camera.latLngToScreenOffset(camera.unprojectAtZoom(
                  Offset(t.x + 0.5, t.y + 0.5) * 256,
                  t.z.toDouble(),
                )) -
                _size.center(Offset.zero))
            .distance,
    ];
    for (var i = 1; i < distances.length; i++) {
      expect(distances[i], greaterThanOrEqualTo(distances[i - 1] - 1e-6),
          reason: '${newLoads[i]} after ${newLoads[i - 1]}');
    }
  });
}

bool _insideConvex(List<Offset> quad, Offset point) {
  var sign = 0.0;
  for (var i = 0; i < quad.length; i++) {
    final a = quad[i];
    final b = quad[(i + 1) % quad.length];
    final cross =
        (b.dx - a.dx) * (point.dy - a.dy) - (b.dy - a.dy) * (point.dx - a.dx);
    if (cross == 0) continue;
    if (sign == 0) {
      sign = cross.sign;
    } else if (cross.sign != sign) {
      return false;
    }
  }
  return true;
}
