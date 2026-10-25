import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_cover.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_cover_calculator.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_range_calculator.dart';
import 'package:flutter_map/src/misc/extensions.dart';
import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';

void main() {
  const size = Size(400, 800);

  MapCamera camera({
    LatLng center = const LatLng(45.52, -122.68),
    double zoom = 14,
    double rotation = 0,
    double pitch = 0,
    Size nonRotatedSize = size,
  }) =>
      MapCamera(
        crs: const Epsg3857(),
        center: center,
        zoom: zoom,
        rotation: rotation,
        pitch: pitch,
        nonRotatedSize: nonRotatedSize,
      );

  TileCover cover(
    MapCamera camera, {
    int tileDimension = 256,
    int minNativeZoom = 0,
    int maxNativeZoom = 19,
    LatLng? center,
    double? viewingZoom,
  }) =>
      TileCoverCalculator(tileDimension: tileDimension).calculate(
        camera: camera,
        tileZoom: (viewingZoom ?? camera.zoom)
            .round()
            .clamp(minNativeZoom, maxNativeZoom),
        minNativeZoom: minNativeZoom,
        center: center,
        viewingZoom: viewingZoom,
      );

  /// For each screen position on a grid, the tile of [tiles] that contains the
  /// ground there, and the scale there.
  List<(Offset, TileCoordinates?, double)> sample(
    MapCamera camera,
    TileCover tiles, {
    int tileDimension = 256,
    double step = 5,
  }) {
    final zooms = tiles.coordinates.map((t) => t.z).toSet();
    final tileZoom = camera.zoom.round();
    final pixelCenter =
        camera.projectAtZoom(camera.center, tileZoom.toDouble()).floor();
    final result = <(Offset, TileCoordinates?, double)>[];
    for (var y = 0.0; y <= camera.nonRotatedSize.height; y += step) {
      for (var x = 0.0; x <= camera.nonRotatedSize.width; x += step) {
        final screen = Offset(x, y);
        final ground = camera.groundOffsetFromCenter(screen)!;
        TileCoordinates? found;
        for (final z in zooms) {
          final pixel = pixelCenter *
                  camera.getZoomScale(z.toDouble(), tileZoom.toDouble()) +
              ground / camera.getZoomScale(camera.zoom, z.toDouble());
          final tile = TileCoordinates(
            (pixel.dx / tileDimension).floor(),
            (pixel.dy / tileDimension).floor(),
            z,
          );
          if (tiles.contains(tile)) {
            expect(found, isNull, reason: 'tiles $found and $tile overlap');
            found = tile;
          }
        }
        result.add((screen, found, camera.groundScale(ground)));
      }
    }
    return result;
  }

  group('unpitched and unrotated', () {
    for (final (zoom, tileDimension) in [
      (14.0, 256),
      (14.45, 256),
      (13.6, 256),
      (14.0, 512),
      (3.2, 256),
      (17.5, 128),
    ]) {
      test('equals the range at zoom $zoom, tile size $tileDimension', () {
        for (final center in const [
          LatLng(45.52, -122.68),
          LatLng(-33.9, 151.2),
          LatLng(0, 179.99),
        ]) {
          final c = camera(center: center, zoom: zoom);
          final tileZoom = zoom.round();
          final range = TileRangeCalculator(tileDimension: tileDimension)
              .calculate(camera: c, tileZoom: tileZoom);
          expect(
            cover(c, tileDimension: tileDimension).coordinates.toSet(),
            range.coordinates.toSet(),
            reason: 'center $center',
          );
        }
      });
    }

    test('equals the range at an overridden center and zoom', () {
      final c = camera();
      const center = LatLng(45.6, -122.5);
      final range = const TileRangeCalculator(tileDimension: 256).calculate(
        camera: c,
        tileZoom: 15,
        center: center,
        viewingZoom: 15.3,
      );
      expect(
        cover(c, center: center, viewingZoom: 15.3).coordinates.toSet(),
        range.coordinates.toSet(),
      );
    });

    test('equals the range above the maximum native zoom', () {
      final c = camera(zoom: 16.3);
      final range = const TileRangeCalculator(tileDimension: 256)
          .calculate(camera: c, tileZoom: 14);
      expect(
        cover(c, maxNativeZoom: 14).coordinates.toSet(),
        range.coordinates.toSet(),
      );
    });

    test('of an empty viewport equals the range', () {
      final c = camera(nonRotatedSize: Size.zero);
      final range = const TileRangeCalculator(tileDimension: 256)
          .calculate(camera: c, tileZoom: 14);
      expect(cover(c).coordinates.toSet(), range.coordinates.toSet());
    });
  });

  test('rotated, contains only tiles that the viewport touches', () {
    final c = camera(rotation: 45);
    final range = const TileRangeCalculator(tileDimension: 256)
        .calculate(camera: c, tileZoom: 14);
    final tiles = cover(c);
    final touched = {
      for (final (screen, tile, _) in sample(c, tiles, step: 1))
        tile ?? fail('no tile at $screen'),
    };
    expect(tiles.coordinates.toSet(), touched);
    expect(range.coordinates.toSet().containsAll(touched), isTrue);
    expect(touched.length, lessThan(range.coordinates.length));
  });

  group('pitched', () {
    for (final (zoom, rotation) in [
      (14.0, 0.0),
      (14.45, 0.0),
      (14.0, 45.0),
      (14.45, 45.0),
      (14.7, 160.0),
    ]) {
      test('far tiles follow the zoom rule, zoom $zoom, rotation $rotation',
          () {
        final c = camera(zoom: zoom, rotation: rotation, pitch: 60);
        final tileZoom = zoom.round();
        final tiles = cover(c);
        final largestScale = <TileCoordinates, double>{};
        for (final (screen, tile, scale) in sample(c, tiles)) {
          expect(tile, isNotNull, reason: 'no tile at $screen');
          largestScale[tile!] = math.max(largestScale[tile] ?? 0, scale);
        }
        expect(
          tiles.coordinates.map((t) => t.z),
          everyElement(lessThanOrEqualTo(tileZoom)),
        );
        for (final tile in tiles.coordinates.where((t) => t.z < tileZoom)) {
          final scale = largestScale[tile];
          if (scale == null) continue;
          expect(
            scale * math.pow(2, zoom - tile.z),
            lessThanOrEqualTo(math.sqrt2),
            reason: '$tile',
          );
        }
      });
    }

    test('far tiles are coarser than the center, near tiles are not finer', () {
      final c = camera(zoom: 14.45, pitch: 60);
      final tiles = cover(c);
      final samples = sample(c, tiles);
      int zoomAt(double y) =>
          samples.firstWhere((s) => s.$1 == Offset(200, y)).$2!.z;
      expect(zoomAt(400), 14);
      expect(zoomAt(0), lessThan(14));
      expect(zoomAt(800), 14);
      expect(
        tiles.coordinates.map((t) => t.z),
        everyElement(lessThanOrEqualTo(14)),
      );
    });

    test('limits the zoom to the native zoom limits', () {
      final c = camera(zoom: 14.45, pitch: 60);
      expect(
        cover(c, maxNativeZoom: 13).coordinates.map((t) => t.z),
        everyElement(lessThanOrEqualTo(13)),
      );
      final low = camera(zoom: 2.2, pitch: 60);
      expect(
        cover(low, minNativeZoom: 2).coordinates.map((t) => t.z),
        everyElement(greaterThanOrEqualTo(2)),
      );
    });

    test('covers the far edge on both sides of the antimeridian', () {
      final c = camera(
        center: const LatLng(10, 179.95),
        zoom: 12,
        rotation: -90,
        pitch: 60,
      );
      final tiles = cover(c);
      for (final (screen, tile, _) in sample(c, tiles)) {
        expect(tile, isNotNull, reason: 'no tile at $screen');
      }
      final worldEdge = <bool>{
        for (final tile in tiles.coordinates) tile.x >= 1 << tile.z,
      };
      expect(worldEdge, {true, false});
    });

    test('the buffer adds neighbors outside the visible ground', () {
      final c = camera(rotation: 45, pitch: 60);
      final tiles = cover(c);
      final added =
          tiles.expand(1).coordinates.where((t) => !tiles.contains(t)).toSet();
      expect(added, isNotEmpty);
      for (final tile in added) {
        expect(
          tiles.coordinates.any((t) =>
              t.z == tile.z &&
              (t.x - tile.x).abs() <= 1 &&
              (t.y - tile.y).abs() <= 1),
          isTrue,
          reason: '$tile is not a neighbor',
        );
      }
      final touched = {
        for (final (_, tile, _) in sample(c, TileCover(added), step: 2))
          if (tile != null) tile,
      };
      expect(touched, isEmpty);
    });
  });
}
