import 'package:flutter/material.dart';
import 'package:flutter_map_example/pages/epsg4326_crs.dart';
import 'package:flutter_map_example/pages/map_inside_listview.dart';
import 'package:flutter_map_example/pages/network_tile_provider.dart';
import 'package:flutter_map_example/pages/point_to_latlng.dart';

import './pages/animated_map_controller.dart';
import './pages/circle.dart';
import './pages/custom_crs/custom_crs.dart';
import './pages/esri.dart';
import './pages/home.dart';
import './pages/interactive_test_page.dart';
import './pages/live_location.dart';
import './pages/many_markers.dart';
import './pages/map_controller.dart';
import './pages/marker_anchor.dart';
import './pages/marker_rotate.dart';
import './pages/max_bounds.dart';
import './pages/moving_markers.dart';
import './pages/offline_map.dart';
import './pages/on_tap.dart';
import './pages/overlay_image.dart';
import './pages/plugin_api.dart';
import './pages/plugin_scalebar.dart';
import './pages/plugin_zoombuttons.dart';
import './pages/polygon.dart';
import './pages/polyline.dart';
import './pages/reset_tile_layer.dart';
import './pages/sliding_map.dart';
import './pages/stateful_markers.dart';
import './pages/tap_to_add.dart';
import './pages/tile_builder_example.dart';
import './pages/tile_loading_error_handle.dart';
import './pages/widgets.dart';
import './pages/wms_tile_layer.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Example',
      theme: ThemeData(
        primarySwatch: mapBoxBlue,
      ),
      home: const HomePage(),
      routes: <String, WidgetBuilder>{
        NetworkTileProviderPage.route: (context) =>
            const NetworkTileProviderPage(),
        WidgetsPage.route: (context) => const WidgetsPage(),
        TapToAddPage.route: (context) => const TapToAddPage(),
        EsriPage.route: (context) => const EsriPage(),
        PolylinePage.route: (context) => const PolylinePage(),
        MapControllerPage.route: (context) => const MapControllerPage(),
        AnimatedMapControllerPage.route: (context) =>
            const AnimatedMapControllerPage(),
        MarkerAnchorPage.route: (context) => const MarkerAnchorPage(),
        PluginPage.route: (context) => const PluginPage(),
        PluginScaleBar.route: (context) => const PluginScaleBar(),
        PluginZoomButtons.route: (context) => const PluginZoomButtons(),
        OfflineMapPage.route: (context) => const OfflineMapPage(),
        OnTapPage.route: (context) => const OnTapPage(),
        MarkerRotatePage.route: (context) => const MarkerRotatePage(),
        MovingMarkersPage.route: (context) => const MovingMarkersPage(),
        CirclePage.route: (context) => const CirclePage(),
        OverlayImagePage.route: (context) => const OverlayImagePage(),
        PolygonPage.route: (context) => const PolygonPage(),
        SlidingMapPage.route: (_) => const SlidingMapPage(),
        WMSLayerPage.route: (context) => const WMSLayerPage(),
        CustomCrsPage.route: (context) => const CustomCrsPage(),
        LiveLocationPage.route: (context) => const LiveLocationPage(),
        TileLoadingErrorHandle.route: (context) =>
            const TileLoadingErrorHandle(),
        TileBuilderPage.route: (context) => const TileBuilderPage(),
        InteractiveTestPage.route: (context) => const InteractiveTestPage(),
        ManyMarkersPage.route: (context) => const ManyMarkersPage(),
        StatefulMarkersPage.route: (context) => const StatefulMarkersPage(),
        MapInsideListViewPage.route: (context) => const MapInsideListViewPage(),
        ResetTileLayerPage.route: (context) => const ResetTileLayerPage(),
        EPSG4326Page.route: (context) => const EPSG4326Page(),
        MaxBoundsPage.route: (context) => const MaxBoundsPage(),
        PointToLatLngPage.route: (context) => const PointToLatLngPage(),
      },
    );
  }
}

// Generated using Material Design Palette/Theme Generator
// http://mcg.mbitson.com/
// https://github.com/mbitson/mcg
const int _bluePrimary = 0xFF395afa;
const MaterialColor mapBoxBlue = MaterialColor(
  _bluePrimary,
  <int, Color>{
    50: Color(0xFFE7EBFE),
    100: Color(0xFFC4CEFE),
    200: Color(0xFF9CADFD),
    300: Color(0xFF748CFC),
    400: Color(0xFF5773FB),
    500: Color(_bluePrimary),
    600: Color(0xFF3352F9),
    700: Color(0xFF2C48F9),
    800: Color(0xFF243FF8),
    900: Color(0xFF172EF6),
  },
);
