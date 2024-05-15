import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/notice_banner.dart';
import 'package:latlong2/latlong.dart';

class DebouncingTileUpdateTransformerPage extends StatefulWidget {
  static const String route = '/debouncing_tile_update_transformer_page';

  const DebouncingTileUpdateTransformerPage({super.key});

  @override
  State<DebouncingTileUpdateTransformerPage> createState() =>
      _DebouncingTileUpdateTransformerPageState();
}

class _DebouncingTileUpdateTransformerPageState
    extends State<DebouncingTileUpdateTransformerPage> {
  int _changeEndKeyRefresher = 0;
  double _durationInMilliseconds = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debouncing Tile Update Transformer')),
      drawer: const MenuDrawer(DebouncingTileUpdateTransformerPage.route),
      body: Column(
        children: [
          const NoticeBanner.informational(
            text:
                'This TileUpdateTransformer debounces TileUpdateEvents so they '
                "don't occur too frequently, which can improve performance and "
                'reduce tile requests.\nHowever, this does lead to reduced UX, '
                'as tiles will not be loaded during long movements or '
                'animations, resulting in the background grey breaking the '
                'illusion of a seamless map.',
            url:
                'https://docs.fleaflet.dev/layers/tile-layer#tile-update-transformers',
            sizeTransition: 1360,
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(51.5, -0.09),
                    initialZoom: 5,
                    cameraConstraint: CameraConstraint.contain(
                      bounds: LatLngBounds(
                        const LatLng(-90, -180),
                        const LatLng(90, 180),
                      ),
                    ),
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey('TileLayer-$_changeEndKeyRefresher'),
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                      tileUpdateTransformer: TileUpdateTransformers.debounce(
                        Duration(milliseconds: _durationInMilliseconds.toInt()),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  right: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 8, top: 4, bottom: 4),
                      child: Row(
                        children: [
                          const Tooltip(
                            message: 'Adjust Duration',
                            child: Icon(Icons.timer),
                          ),
                          Expanded(
                            child: Slider.adaptive(
                              value: _durationInMilliseconds,
                              onChanged: (v) =>
                                  setState(() => _durationInMilliseconds = v),
                              onChangeEnd: (v) =>
                                  setState(() => _changeEndKeyRefresher++),
                              min: 0,
                              max: 500,
                              divisions: 100,
                              label: _durationInMilliseconds == 0
                                  ? 'Instant/No Debounce'
                                  : '${_durationInMilliseconds.toInt()} ms',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
