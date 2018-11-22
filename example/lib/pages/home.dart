import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  @override
  State<StatefulWidget> createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {

  bool _isEditing = false;

  final markers = <Marker>[
    new Marker(
      width: 30.0,
      height: 30.0,
      point: new LatLng(51.5, -0.09),
      builder: (ctx) => new Container(
        child: new FlutterLogo(),
      ),
    ),
    new Marker(
      width: 60.0,
      height: 60.0,
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


  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Home")),
      drawer: buildDrawer(context, HomePage.route),
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
                    subdomains: ['a', 'b', 'c']),
                  new MarkerLayerOptions(
                    markers: markers,
                    editable: _isEditing,
                    onMoved: (marker, point) {
                      print("original: ${marker.point}, moved: $point");
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState((){
          _isEditing = !_isEditing;
        }),
        tooltip: _isEditing ? 'Apply' : "Edit",
        backgroundColor: Colors.white,
        child: Icon(
            _isEditing ? Icons.check : Icons.edit,
            color: Colors.black
        ),
      ),
    );
  }
}
