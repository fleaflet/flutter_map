import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_example/pages/abort_obsolete_requests.dart';
import 'package:flutter_map_example/pages/animated_map_controller.dart';
import 'package:flutter_map_example/pages/bundled_offline_map.dart';
import 'package:flutter_map_example/pages/circle.dart';
import 'package:flutter_map_example/pages/debouncing_tile_update_transformer.dart';
import 'package:flutter_map_example/pages/epsg3996_crs.dart';
import 'package:flutter_map_example/pages/epsg4326_crs.dart';
import 'package:flutter_map_example/pages/fallback_url_page.dart';
import 'package:flutter_map_example/pages/fling_animation_damping.dart';
import 'package:flutter_map_example/pages/home.dart';
import 'package:flutter_map_example/pages/interactive_test_page.dart';
import 'package:flutter_map_example/pages/latlng_to_screen_point.dart';
import 'package:flutter_map_example/pages/many_circles.dart';
import 'package:flutter_map_example/pages/many_markers.dart';
import 'package:flutter_map_example/pages/map_controller.dart';
import 'package:flutter_map_example/pages/map_inside_listview.dart';
import 'package:flutter_map_example/pages/markers.dart';
import 'package:flutter_map_example/pages/overlay_image.dart';
import 'package:flutter_map_example/pages/plugin_zoombuttons.dart';
import 'package:flutter_map_example/pages/polygon.dart';
import 'package:flutter_map_example/pages/polygon_perf_stress.dart';
import 'package:flutter_map_example/pages/polyline.dart';
import 'package:flutter_map_example/pages/polyline_perf_stress.dart';
import 'package:flutter_map_example/pages/repeated_worlds.dart';
import 'package:flutter_map_example/pages/reset_tile_layer.dart';
import 'package:flutter_map_example/pages/retina.dart';
import 'package:flutter_map_example/pages/scalebar.dart';
import 'package:flutter_map_example/pages/screen_point_to_latlng.dart';
import 'package:flutter_map_example/pages/secondary_tap.dart';
import 'package:flutter_map_example/pages/single_world_polys.dart';
import 'package:flutter_map_example/pages/sliding_map.dart';
import 'package:flutter_map_example/pages/tile_builder.dart';
import 'package:flutter_map_example/pages/tile_loading_error_handle.dart';
import 'package:flutter_map_example/pages/wms_tile_layer.dart';
import 'package:flutter_map_example/widgets/drawer/menu_item.dart';
import 'package:url_launcher/url_launcher.dart';

const _isWASM = bool.fromEnvironment('dart.tool.dart2wasm');
const _commitSHA = String.fromEnvironment('COMMIT_SHA');

class MenuDrawer extends StatelessWidget {
  final String currentRoute;

  const MenuDrawer(this.currentRoute, {super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16)
                .add(EdgeInsets.only(top: MediaQuery.paddingOf(context).top)),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(bottom: Divider.createBorderSide(context)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/ProjectIcon.png',
                  height: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'flutter_map Demo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '© flutter_map Authors & Contributors',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (kIsWeb)
                  Text(
                    _isWASM ? 'Running with WASM' : 'Running without WASM',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (_commitSHA != '')
                  SelectableText.rich(
                    TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(text: 'Built from: '),
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${_commitSHA.substring(
                                0,
                                min(_commitSHA.length, 7),
                              )} ',
                              recognizer: TapGestureRecognizer()
                                ..onTap = _openCommit,
                            ),
                            WidgetSpan(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _openCommit,
                                  child: const Icon(
                                    Icons.open_in_new,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          MenuItemWidget(
            caption: 'Home',
            routeName: HomePage.route,
            currentRoute: currentRoute,
            icon: const Icon(Icons.home),
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'Marker Layer',
            routeName: MarkerPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Polygon Layer',
            routeName: PolygonPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Polyline Layer',
            routeName: PolylinePage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Circle Layer',
            routeName: CirclePage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Overlay Image Layer',
            routeName: OverlayImagePage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Scale Bar Layer',
            routeName: ScaleBarPage.route,
            currentRoute: currentRoute,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'Repeated Worlds/Longitudes',
            routeName: RepeatedWorldsPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Single World Polys',
            routeName: SingleWorldPolysPage.route,
            currentRoute: currentRoute,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'Map Controller',
            routeName: MapControllerPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Animated Map Controller',
            routeName: AnimatedMapControllerPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Interactive Flags',
            routeName: InteractiveFlagsPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Fling Animation Damping',
            routeName: FlingAnimationDampingPage.route,
            currentRoute: currentRoute,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'WMS Sourced Map',
            routeName: WMSLayerPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Bundled Offline Map',
            routeName: BundledOfflineMapPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Fallback URL',
            routeName: FallbackUrlPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Abort Obsolete Requests',
            routeName: AbortObsoleteRequestsPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Debouncing Tile Update Transformer',
            routeName: DebouncingTileUpdateTransformerPage.route,
            currentRoute: currentRoute,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'Polygon Stress Test',
            routeName: PolygonPerfStressPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Polyline Stress Test',
            routeName: PolylinePerfStressPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Many Markers',
            routeName: ManyMarkersPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Many Circles',
            routeName: ManyCirclesPage.route,
            currentRoute: currentRoute,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'Zoom Buttons Plugin',
            routeName: PluginZoomButtons.route,
            currentRoute: currentRoute,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'EPSG:4326 CRS',
            currentRoute: currentRoute,
            routeName: EPSG4326Page.route,
          ),
          MenuItemWidget(
            caption: 'EPSG:3996 (Custom) CRS',
            currentRoute: currentRoute,
            routeName: EPSG3996Page.route,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'Sliding Map',
            routeName: SlidingMapPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Map Inside Scrollable',
            routeName: MapInsideListViewPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Secondary Tap',
            routeName: SecondaryTapPage.route,
            currentRoute: currentRoute,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'Custom Tile Error Handling',
            routeName: TileLoadingErrorHandle.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Custom Tile Builder',
            routeName: TileBuilderPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Retina Tile Layer',
            routeName: RetinaPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'Reset Tile Layer',
            routeName: ResetTileLayerPage.route,
            currentRoute: currentRoute,
          ),
          const Divider(),
          MenuItemWidget(
            caption: 'Screen Point 🡒 LatLng',
            routeName: ScreenPointToLatLngPage.route,
            currentRoute: currentRoute,
          ),
          MenuItemWidget(
            caption: 'LatLng 🡒 Screen Point',
            routeName: LatLngToScreenPointPage.route,
            currentRoute: currentRoute,
          ),
        ],
      ),
    );
  }

  void _openCommit() => launchUrl(
        Uri.parse('https://github.com/fleaflet/flutter_map/commit/$_commitSHA'),
      );
}
