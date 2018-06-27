import 'package:flutter/material.dart';
import 'package:flutter_map_example/pages/esri.dart';
import 'package:flutter_map_example/pages/home.dart';
import 'package:flutter_map_example/pages/map_controller.dart';
import 'package:flutter_map_example/pages/animated_map_controller.dart';
import 'package:flutter_map_example/pages/marker_anchor.dart';
import 'package:flutter_map_example/pages/plugin_api.dart';
import 'package:flutter_map_example/pages/polyline.dart';
import 'package:flutter_map_example/pages/tap_to_add.dart';
import 'package:flutter_map_example/pages/offline_map.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Map Example',
      theme: new ThemeData(
        primarySwatch: mapBoxBlue,
      ),
      home: new HomePage(),
      routes: <String, WidgetBuilder>{
        TapToAddPage.route: (context) => new TapToAddPage(),
        EsriPage.route: (context) => new EsriPage(),
        PolylinePage.route: (context) => new PolylinePage(),
        MapControllerPage.route: (context) => new MapControllerPage(),
        AnimatedMapControllerPage.route: (context) => new AnimatedMapControllerPage(),
        MarkerAnchorPage.route: (context) => new MarkerAnchorPage(),
        PluginPage.route: (context) => new PluginPage(),
        OfflineMapPage.route: (context) => new OfflineMapPage(),
      },
    );
  }
}

// Generated using Material Design Palette/Theme Generator
// http://mcg.mbitson.com/
// https://github.com/mbitson/mcg
const int _bluePrimary = 0xFF395afa;
const MaterialColor mapBoxBlue = const MaterialColor(
  _bluePrimary,
  const <int, Color>{
    50: const Color(0xFFE7EBFE),
    100: const Color(0xFFC4CEFE),
    200: const Color(0xFF9CADFD),
    300: const Color(0xFF748CFC),
    400: const Color(0xFF5773FB),
    500: const Color(_bluePrimary),
    600: const Color(0xFF3352F9),
    700: const Color(0xFF2C48F9),
    800: const Color(0xFF243FF8),
    900: const Color(0xFF172EF6),
  },
);
