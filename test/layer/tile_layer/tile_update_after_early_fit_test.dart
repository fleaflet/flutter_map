import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../test_utils/test_tile_image.dart';

/// Records the zoom of every tile whose image actually starts loading.
class _RecordingTileProvider extends TileProvider {
  final loadedZooms = <int>{};

  @override
  ImageProvider<Object> getImage(
          TileCoordinates coordinates, TileLayer options) =>
      _RecordingImage(() => loadedZooms.add(coordinates.z));
}

class _RecordingImage extends MemoryImage {
  _RecordingImage(this.onResolve) : super(testWhiteTileBytes);

  final VoidCallback onResolve;

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    onResolve();
    return super.obtainKey(configuration);
  }
}

void main() {
  testWidgets(
    'camera move scheduled before the first layout loads tiles at the new '
    'zoom with a debounced tileUpdateTransformer',
    (tester) async {
      final controller = MapController();
      final provider = _RecordingTileProvider();

      // Registered before `FlutterMap`'s own post-frame size change event.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.move(const LatLng(45, 5), 10);
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlutterMap(
            mapController: controller,
            options: const MapOptions(initialZoom: 3),
            children: [
              TileLayer(
                tileProvider: provider,
                tileUpdateTransformer: TileUpdateTransformers.debounce(
                  const Duration(milliseconds: 50),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.camera.zoom, 10);
      expect(provider.loadedZooms, contains(10));
    },
  );
}
