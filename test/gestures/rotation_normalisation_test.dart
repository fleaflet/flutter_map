import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Two fingers around [c], [scale] times their initial 100 px apart, the
/// line between them rotated by [degrees]. At 0° the line runs along the x
/// axis with the first finger to the left: `atan2` of the start line is 180°,
/// so a small rotation crosses ±180°.
List<Offset> _fingers(Offset c, double scale, double degrees) {
  final a = degrees * math.pi / 180;
  final v = Offset(math.cos(a), math.sin(a)) * 50 * scale;
  return [c - v, c + v];
}

void main() {
  testWidgets('a small rotation across ±180° does not win the gesture race',
      (tester) async {
    final controller = MapController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: FlutterMap(
              mapController: controller,
              options: const MapOptions(
                initialCenter: LatLng(46.5, 6.6),
                initialZoom: 10,
                interactionOptions: InteractionOptions(
                  enableMultiFingerGestureRace: true,
                ),
              ),
              children: const [],
            ),
          ),
        ),
      ),
    );

    final c = tester.getCenter(find.byType(FlutterMap));
    final start = _fingers(c, 1, 0);
    final g1 = await tester.startGesture(start[0], pointer: 1);
    final g2 = await tester.startGesture(start[1], pointer: 2);
    await tester.pump();
    // Spread the fingers too, so the gesture passes the touch slop.
    for (final (scale, degrees) in [(1.2, 2.0), (1.4, 4.0)]) {
      final p = _fingers(c, scale, degrees);
      await g1.moveTo(p[0]);
      await g2.moveTo(p[1]);
      await tester.pump();
    }
    await g1.up();
    await g2.up();
    await tester.pumpAndSettle();
    // Let the double tap timer expire.
    await tester.pump(const Duration(seconds: 1));

    // 4° is below the default rotationThreshold (20°): rotation must not win
    // the race, which the raw -356° value made it do.
    expect(controller.camera.rotation, 0);
  });
}
