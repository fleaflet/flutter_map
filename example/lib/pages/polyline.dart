import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class PolylinePage extends StatefulWidget {
  static const String route = '/polyline';

  const PolylinePage({super.key});

  @override
  State<PolylinePage> createState() => _PolylinePageState();
}

class _PolylinePageState extends State<PolylinePage> {
  final PolylineHitNotifier hitNotifier = ValueNotifier(null);

  final polylines = <Polyline, ({String title, String subtitle})>{
    Polyline(
      points: [
        const LatLng(51.5, -0.09),
        const LatLng(53.3498, -6.2603),
        const LatLng(48.8566, 2.3522),
      ],
      strokeWidth: 8,
      color: const Color(0xFF60399E),
    ): (
      title: 'Elizabeth Line',
      subtitle: 'Nothing really special here...',
    ),
    Polyline(
      points: [
        const LatLng(48.5, -3.09),
        const LatLng(47.3498, -9.2603),
        const LatLng(43.8566, -1.3522),
      ],
      strokeWidth: 16000,
      color: Colors.pink,
      useStrokeWidthInMeter: true,
    ): (
      title: 'Pink Line',
      subtitle: 'Fixed radius in meters instead of pixels',
    ),
    Polyline(
      points: [
        const LatLng(55.5, -0.09),
        const LatLng(54.3498, -6.2603),
        const LatLng(52.8566, 2.3522),
      ],
      strokeWidth: 4,
      gradientColors: [
        const Color(0xffE40203),
        const Color(0xffFEED00),
        const Color(0xff007E2D),
      ],
    ): (
      title: 'Traffic Light Line',
      subtitle: 'Fancy gradient instead of a solid color',
    ),
    Polyline(
      points: [
        const LatLng(50.5, -0.09),
        const LatLng(51.3498, 6.2603),
        const LatLng(53.8566, 2.3522),
      ],
      strokeWidth: 20,
      color: Colors.blue.withOpacity(0.6),
      borderStrokeWidth: 20,
      borderColor: Colors.red.withOpacity(0.4),
    ): (
      title: 'BlueRed Line',
      subtitle: 'Solid translucent color fill, with different color outline',
    ),
    Polyline(
      points: [
        const LatLng(50.2, -0.08),
        const LatLng(51.2498, -10.2603),
        const LatLng(54.8566, -9.3522),
      ],
      strokeWidth: 20,
      color: Colors.black.withOpacity(0.2),
      borderStrokeWidth: 20,
      borderColor: Colors.white30,
    ): (
      title: 'BlackWhite Line',
      subtitle: 'Solid translucent color fill, with different color outline',
    ),
    Polyline(
      points: [
        const LatLng(49.1, -0.06),
        const LatLng(52.15, -1.4),
        const LatLng(55.5, 0.8),
      ],
      strokeWidth: 10,
      color: Colors.yellow,
      borderStrokeWidth: 10,
      borderColor: Colors.blue.withOpacity(0.5),
    ): (
      title: 'YellowBlue Line',
      subtitle: 'Solid translucent color fill, with different color outline',
    ),
  };

  List<Polyline>? hoverLines;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polylines')),
      drawer: const MenuDrawer(PolylinePage.route),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(51.5, -0.09),
          initialZoom: 5,
        ),
        children: [
          openStreetMapTileLayer,
          MouseRegion(
            hitTestBehavior: HitTestBehavior.deferToChild,
            cursor: SystemMouseCursors.click,
            onHover: (_) {
              if (hitNotifier.value == null) return;

              final lines = hitNotifier.value!.lines
                  .where((e) => polylines.containsKey(e))
                  .map(
                    (e) => Polyline(
                      points: e.points,
                      strokeWidth: e.strokeWidth + e.borderStrokeWidth,
                      color: Colors.transparent,
                      borderStrokeWidth: 15,
                      borderColor: Colors.green,
                      useStrokeWidthInMeter: e.useStrokeWidthInMeter,
                    ),
                  )
                  .toList();
              setState(() => hoverLines = lines);
            },

            /// Clear hovered lines when touched lines modal appears
            onExit: (_) => setState(() => hoverLines = null),
            child: GestureDetector(
              onTap: () => _openTouchedLinesModal(
                'Tapped',
                hitNotifier.value!.lines,
                hitNotifier.value!.point,
              ),
              onLongPress: () => _openTouchedLinesModal(
                'Long pressed',
                hitNotifier.value!.lines,
                hitNotifier.value!.point,
              ),
              onSecondaryTap: () => _openTouchedLinesModal(
                'Secondary tapped',
                hitNotifier.value!.lines,
                hitNotifier.value!.point,
              ),
              child: PolylineLayer(
                hitNotifier: hitNotifier,
                polylines: (hoverLines ?? []).followedBy(polylines.keys),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openTouchedLinesModal(
    String eventType,
    List<Polyline> tappedLines,
    LatLng coords,
  ) {
    tappedLines.removeWhere((e) => !polylines.containsKey(e));

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tapped Polyline(s)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '$eventType at point: (${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)})',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  final tappedLineData = polylines[tappedLines[index]]!;
                  return ListTile(
                    leading: index == 0
                        ? const Icon(Icons.vertical_align_top)
                        : index == tappedLines.length - 1
                            ? const Icon(Icons.vertical_align_bottom)
                            : const SizedBox.shrink(),
                    title: Text(tappedLineData.title),
                    subtitle: Text(tappedLineData.subtitle),
                    dense: true,
                  );
                },
                itemCount: tappedLines.length,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
