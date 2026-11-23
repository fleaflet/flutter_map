import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_tile_image.dart';

/// A minimal [TileProvider] that forwards custom [TileProvider.headers].
class _HeaderTileProvider extends TileProvider {
  _HeaderTileProvider({super.headers});

  @override
  ImageProvider<Object> getImage(
          TileCoordinates coordinates, TileLayer options) =>
      testWhiteTileImage;
}

void main() {
  group('TileProvider.headers', () {
    test('are mutable even when a constant map is passed', () {
      final provider = _HeaderTileProvider(headers: const {'ABC': 'DEF'});

      // Regression test for https://github.com/fleaflet/flutter_map/issues/2306
      // `TileLayer` injects the 'User-Agent' by mutating `headers`, so the
      // stored map must never be the (unmodifiable) constant passed by the
      // caller.
      expect(
        () => provider.headers.putIfAbsent('User-Agent', () => 'flutter_map'),
        returnsNormally,
      );
      expect(provider.headers, {'ABC': 'DEF', 'User-Agent': 'flutter_map'});
    });

    test('do not mutate the constant map passed by the caller', () {
      const original = {'ABC': 'DEF'};
      _HeaderTileProvider(headers: original).headers['User-Agent'] = 'x';

      expect(original, const {'ABC': 'DEF'});
    });

    test('default to an empty mutable map when omitted', () {
      final provider = _HeaderTileProvider();

      expect(provider.headers, isEmpty);
      expect(
        () => provider.headers['User-Agent'] = 'flutter_map',
        returnsNormally,
      );
    });

    test(
      'a constant map passed to a tile provider does not crash TileLayer',
      () {
        // End-to-end reproduction of the reported crash
        // ('Cannot modify unmodifiable map').
        expect(
          () => TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
            tileProvider: _HeaderTileProvider(headers: const {'ABC': 'DEF'}),
          ),
          returnsNormally,
        );
      },
    );
  });
}
