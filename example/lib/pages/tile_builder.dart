import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class TileBuilderPage extends StatefulWidget {
  static const String route = '/tile_builder';

  const TileBuilderPage({super.key});

  @override
  TileBuilderPageState createState() => TileBuilderPageState();
}

class TileBuilderPageState extends State<TileBuilderPage> {
  bool enableGrid = true;
  bool showCoordinates = true;
  bool showLoadingTime = true;
  bool darkMode = true;

  // mix of [coordinateDebugTileBuilder] and [loadingTimeDebugTileBuilder] from tile_builder.dart
  Widget tileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    final coords = tile.coordinates;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: enableGrid ? Border.all(width: 2, color: Colors.white) : null,
      ),
      position: DecorationPosition.foreground,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          tileWidget,
          if (showLoadingTime || showCoordinates)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showCoordinates)
                  Text(
                    '${coords.x} : ${coords.y} : ${coords.z}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                if (showLoadingTime)
                  Text(
                    tile.loadFinishedAt == null
                        ? 'Loading'
                        // sometimes result is negative which shouldn't happen, abs() corrects it
                        : '${(tile.loadFinishedAt!.millisecond - tile.loadStarted!.millisecond).abs()} ms',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
              ],
            ),
        ],
      ),
    );
  }

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
                    value: darkMode,
                    onChanged: (v) => setState(() => darkMode = v),
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
                _darkModeContainerIfEnabled(
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                    tileProvider: CancellableNetworkTileProvider(),
                    tileBuilder: tileBuilder,
                  ),
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

  Widget _darkModeContainerIfEnabled(Widget child) {
    if (!darkMode) return child;

    return darkModeTilesContainerBuilder(context, child);
  }
}
