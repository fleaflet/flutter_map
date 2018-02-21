import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

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
      },
    );
  }
}

class HomePage extends StatelessWidget {
  static const String route = '/';
  Widget build(BuildContext context) {
    var markers = <Marker>[
      new Marker(
        width: 80.0,
        height: 80.0,
        point: new LatLng(51.5, -0.09),
        builder: (ctx) => new Container(
              child: new FlutterLogo(),
            ),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: new LatLng(53.3498, -6.2603),
        builder: (ctx) => new Container(
              child: new FlutterLogo(
                colors: Colors.green,
              ),
            ),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: new LatLng(48.8566, 2.3522),
        builder: (ctx) => new Container(
              child: new FlutterLogo(colors: Colors.purple),
            ),
      ),
    ];

    return new Scaffold(
      appBar: new AppBar(title: new Text("Home")),
      drawer: _buildDrawer(context, route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("This is a map that is showing (51.5, -0.9)."),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(51.5, -0.09),
                  zoom: 5.0,
                ),
                layers: [
                  new TileLayerOptions(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a','b','c']
                  ),
                  new MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TapToAddPage extends StatefulWidget {
  static const String route = '/tap';

  State<StatefulWidget> createState() {
    return new TapToAddPageState();
  }
}

class TapToAddPageState extends State<TapToAddPage> {
  List<LatLng> tappedPoints = [];

  Widget build(BuildContext context) {
    var markers = tappedPoints.map((latlng) {
      return new Marker(
        width: 80.0,
        height: 80.0,
        point: latlng,
        builder: (ctx) => new Container(
              child: new FlutterLogo(),
            ),
      );
    }).toList();

    return new Scaffold(
      appBar: new AppBar(title: new Text("Tap to add pins")),
      drawer: _buildDrawer(context, TapToAddPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("Tap to add pins"),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                    center: new LatLng(45.5231, -122.6765),
                    zoom: 13.0,
                    onTap: _handleTap),
                layers: [
                  new TileLayerOptions(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  new MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(LatLng latlng) {
    setState(() {
      tappedPoints.add(latlng);
    });
  }
}

class EsriPage extends StatelessWidget {
  static const String route = "esri";

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Esri")),
      drawer: _buildDrawer(context, TapToAddPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("Esri"),
            ),
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(45.5231, -122.6765),
                  zoom: 13.0,
                ),
                layers: [
                  new TileLayerOptions(
                    urlTemplate:
                        "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  Widget build(BuildContext context) {
    return new AppBar(
      elevation: 0.0,
      title: new Text("Examples"),
    );
  }
}

Drawer _buildDrawer(BuildContext context, String currentRoute) {
  return new Drawer(
    child: new ListView(
      children: <Widget>[
        const DrawerHeader(
          child: const Center(
            child: const Text("Flutter Map Examples"),
          ),
        ),
        new ListTile(
          title: const Text('OpenStreetMap'),
          selected: currentRoute == HomePage.route,
          onTap: () {
            Navigator.popAndPushNamed(context, HomePage.route);
          },
        ),
        new ListTile(
          title: const Text('Add Pins'),
          selected: currentRoute == TapToAddPage.route,
          onTap: () {
            Navigator.popAndPushNamed(context, TapToAddPage.route);
          },
        ),
        new ListTile(
          title: const Text('Esri'),
          selected: currentRoute == EsriPage.route,
          onTap: () {
            Navigator.popAndPushNamed(context, EsriPage.route);
          },
        ),
      ],
    ),
  );
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
