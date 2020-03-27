import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_provider/storage_caching_tile_provider/storage_caching_tile_provider.dart';
import 'package:latlong/latlong.dart';
import 'package:test/test.dart';

void main() {
  test('tile_calculator_test', () {
    final resultRange = StorageCachingTileProvider.approximateTileAmount(
        bounds: LatLngBounds.fromPoints(
            [LatLng(-33.5597, -70.77941), LatLng(-33.33282, -70.49102)]),
        minZoom: 10,
        maxZoom: 16);
    final tilesCount = resultRange;
    assert(tilesCount == 3580);
  });
}
