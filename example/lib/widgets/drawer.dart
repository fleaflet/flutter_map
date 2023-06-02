import 'package:flutter/material.dart';

import 'package:flutter_map_example/pages/animated_map_controller.dart';
import 'package:flutter_map_example/pages/circle.dart';
import 'package:flutter_map_example/pages/custom_crs/custom_crs.dart';
import 'package:flutter_map_example/pages/epsg3413_crs.dart';
import 'package:flutter_map_example/pages/epsg4326_crs.dart';
import 'package:flutter_map_example/pages/fallback_url_network_page.dart';
import 'package:flutter_map_example/pages/home.dart';
import 'package:flutter_map_example/pages/interactive_test_page.dart';
import 'package:flutter_map_example/pages/latlng_to_screen_point.dart';
import 'package:flutter_map_example/pages/many_markers.dart';
import 'package:flutter_map_example/pages/map_controller.dart';
import 'package:flutter_map_example/pages/map_inside_listview.dart';
import 'package:flutter_map_example/pages/markers.dart';
import 'package:flutter_map_example/pages/moving_markers.dart';
import 'package:flutter_map_example/pages/offline_map.dart';
import 'package:flutter_map_example/pages/overlay_image.dart';
import 'package:flutter_map_example/pages/plugin_scalebar.dart';
import 'package:flutter_map_example/pages/plugin_zoombuttons.dart';
import 'package:flutter_map_example/pages/point_to_latlng.dart';
import 'package:flutter_map_example/pages/polygon.dart';
import 'package:flutter_map_example/pages/polyline.dart';
import 'package:flutter_map_example/pages/reset_tile_layer.dart';
import 'package:flutter_map_example/pages/secondary_tap.dart';
import 'package:flutter_map_example/pages/sliding_map.dart';
import 'package:flutter_map_example/pages/stateful_markers.dart';
import 'package:flutter_map_example/pages/tile_builder_example.dart';
import 'package:flutter_map_example/pages/tile_loading_error_handle.dart';
import 'package:flutter_map_example/pages/wms_tile_layer.dart';

Widget _buildMenuItem(
  BuildContext context,
  Widget title,
  String routeName,
  String currentRoute, {
  Widget? icon,
}) {
  final isSelected = routeName == currentRoute;

  return ListTile(
    title: title,
    leading: icon,
    selected: isSelected,
    onTap: () {
      if (isSelected) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, routeName);
      }
    },
  );
}

Drawer buildDrawer(BuildContext context, String currentRoute) {
  return Drawer(
    child: ListView(
      children: <Widget>[
        DrawerHeader(
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
            ],
          ),
        ),
        _buildMenuItem(
          context,
          const Text('Home'),
          HomePage.route,
          currentRoute,
          icon: const Icon(Icons.home),
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('Marker Layer'),
          MarkerPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Polygon Layer'),
          PolygonPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Polyline Layer'),
          PolylinePage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Circle Layer'),
          CirclePage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Overlay Image Layer'),
          OverlayImagePage.route,
          currentRoute,
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('Map Controller'),
          MapControllerPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Animated Map Controller'),
          AnimatedMapControllerPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Interactive Flags'),
          InteractiveTestPage.route,
          currentRoute,
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('WMS Sourced Map'),
          WMSLayerPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Asset Sourced Map'),
          OfflineMapPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Fallback URL'),
          FallbackUrlNetworkPage.route,
          currentRoute,
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('Stateful Markers'),
          StatefulMarkersPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Many Markers'),
          ManyMarkersPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Moving Marker'),
          MovingMarkersPage.route,
          currentRoute,
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('ScaleBar Plugins'),
          PluginScaleBar.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('ZoomButtons Plugins'),
          PluginZoomButtons.route,
          currentRoute,
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('Custom CRS'),
          CustomCrsPage.route,
          currentRoute,
        ),
        ListTile(
          title: const Text('EPSG4326 CRS'),
          selected: currentRoute == EPSG4326Page.route,
          onTap: () {
            Navigator.pushReplacementNamed(context, EPSG4326Page.route);
          },
        ),
        ListTile(
          title: const Text('EPSG3413 CRS'),
          selected: currentRoute == EPSG3413Page.route,
          onTap: () {
            Navigator.pushReplacementNamed(context, EPSG3413Page.route);
          },
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('Sliding Map'),
          SlidingMapPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Map Inside Scrollable'),
          MapInsideListViewPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Secondary Tap'),
          SecondaryTapPage.route,
          currentRoute,
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('Custom Tile Error Handling'),
          TileLoadingErrorHandle.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Custom Tile Builder'),
          TileBuilderPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Reset Tile Layer'),
          ResetTileLayerPage.route,
          currentRoute,
        ),
        const Divider(),
        _buildMenuItem(
          context,
          const Text('Screen Point -> LatLng'),
          PointToLatLngPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('LatLng -> Screen Point'),
          LatLngScreenPointTestPage.route,
          currentRoute,
        ),
      ],
    ),
  );
}
