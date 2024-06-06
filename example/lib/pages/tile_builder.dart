import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class TileBuilderPage extends StatefulWidget {
  static const String route = '/tile_builder';

  const TileBuilderPage({super.key});

  @override
  State<TileBuilderPage> createState() => _TileBuilderPageState();
}

class _TileBuilderPageState extends State<TileBuilderPage> {
  bool enableGrid = true;
  bool showCoordinates = true;
  bool showLoadingTime = true;
  bool enableDarkMode = true;

  final _darkModeColorFilter = const ColorFilter.matrix([
    -1,
    0,
    0,
    0,
    255,
    0,
    -1,
    0,
    0,
    255,
    0,
    0,
    -1,
    0,
    255,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tile Builder')),
      drawer: const MenuDrawer(TileBuilderPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Tooltip(
                    message: 'Overlay Tile Grid',
                    child: Icon(Icons.grid_4x4),
                  ),
                  Switch.adaptive(
                    value: enableGrid,
                    onChanged: (v) => setState(() => enableGrid = v),
                  ),
                  const SizedBox.square(dimension: 12),
                  const Tooltip(
                    message: 'Show Coordinates',
                    child: Icon(Icons.location_on),
                  ),
                  Switch.adaptive(
                    value: showCoordinates,
                    onChanged: (v) => setState(() => showCoordinates = v),
                  ),
                  const SizedBox.square(dimension: 12),
                  const Tooltip(
                    message: 'Show Tile Loading Duration',
                    child: Icon(Icons.timer_outlined),
                  ),
                  Switch.adaptive(
                    value: showLoadingTime,
                    onChanged: (v) => setState(() => showLoadingTime = v),
                  ),
                  const SizedBox.square(dimension: 12),
                  const Tooltip(
                    message: 'Simulate Dark Mode',
                    child: Icon(Icons.dark_mode),
                  ),
                  Switch.adaptive(
                    value: enableDarkMode,
                    onChanged: (v) => setState(() => enableDarkMode = v),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(51.5, -0.09),
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  tileProvider: CancellableNetworkTileProvider(),
                  tilePaint: enableDarkMode
                      ? (Paint()..colorFilter = _darkModeColorFilter)
                      : null,
                  tileOverlayPainter: tileOverlayPainter,
                ),
                const MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: LatLng(51.5, -0.09),
                      child: FlutterLogo(
                        key: ObjectKey(Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void tileOverlayPainter({
    required Canvas canvas,
    required Offset origin,
    required Size size,
    required TileImage tile,
  }) {
    final rect = origin & size;

    if (enableGrid) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = enableDarkMode ? Colors.white : Colors.black
          ..style = PaintingStyle.stroke,
      );
    }

    if (showCoordinates || showLoadingTime) {
      final textStyle = TextStyle(
        color: enableDarkMode ? Colors.white : Colors.black,
        fontSize: 18,
      );

      final textSpan = TextSpan(
        text: (showCoordinates ? tile.coordinates.toString() : '') +
            (showCoordinates && showLoadingTime ? '\n' : '') +
            (showLoadingTime
                ? tile.loadFinishedAt == null
                    ? 'Loading'
                    // sometimes result is negative which shouldn't happen, abs() corrects it
                    : '${(tile.loadFinishedAt!.millisecond - tile.loadStarted!.millisecond).abs()} ms'
                : ''),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );
      final xCenter = (size.width - textPainter.width) / 2;
      final yCenter = (size.height - textPainter.height) / 2;

      textPainter.paint(canvas, origin + Offset(xCenter, yCenter));
    }
  }
}
