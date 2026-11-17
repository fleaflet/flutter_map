import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/shared/feature_layer_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _TestPainter extends CustomPainter with FeatureLayerUtils {
  _TestPainter(this.camera);

  @override
  final MapCamera camera;

  @override
  // Required by `@mustBeOverridden`.
  // ignore: unnecessary_overrides
  void paint(Canvas canvas, Size size) => super.paint(canvas, size);

  @override
  bool shouldRepaint(_TestPainter oldDelegate) => false;
}

_TestPainter _painter({Crs crs = const Epsg3857()}) => _TestPainter(
      MapCamera(
        crs: crs,
        center: const LatLng(0, 0),
        zoom: 3,
        rotation: 0,
        nonRotatedSize: const Size(200, 200),
      ),
    );

void main() {
  group('FeatureLayerUtils.workAcrossWorlds', () {
    test('stops in each direction at the first invisible world', () {
      final painter = _painter();
      final worldWidth = painter.worldWidth;
      final shifts = <double>[];

      final result = painter.workAcrossWorlds((shift) {
        shifts.add(shift);
        return shift == 0
            ? WorldWorkControl.visible
            : WorldWorkControl.invisible;
      });

      expect(result, isFalse);
      expect(shifts, [0, -worldWidth, worldWidth]);
    });

    test('keeps going in each direction while worlds are visible', () {
      final painter = _painter();
      final worldWidth = painter.worldWidth;
      final shifts = <double>[];

      final result = painter.workAcrossWorlds((shift) {
        shifts.add(shift);
        return shift.abs() <= worldWidth
            ? WorldWorkControl.visible
            : WorldWorkControl.invisible;
      });

      expect(result, isFalse);
      expect(
        shifts,
        [0, -worldWidth, -2 * worldWidth, worldWidth, 2 * worldWidth],
      );
    });

    test('returns true as soon as a world is hit', () {
      final painter = _painter();
      final worldWidth = painter.worldWidth;

      for (final hitShift in [0.0, -worldWidth, worldWidth]) {
        final shifts = <double>[];

        final result = painter.workAcrossWorlds((shift) {
          shifts.add(shift);
          if (shift == hitShift) return WorldWorkControl.hit;
          return shift == 0
              ? WorldWorkControl.visible
              : WorldWorkControl.invisible;
        });

        expect(result, isTrue);
        expect(shifts.last, hitShift);
      }
    });

    test('only works in the primary world if the CRS is not replicated', () {
      final painter = _painter(crs: const Epsg4326());
      final shifts = <double>[];

      final result = painter.workAcrossWorlds((shift) {
        shifts.add(shift);
        return WorldWorkControl.visible;
      });

      expect(result, isFalse);
      expect(shifts, [0]);
    });
  });
}
