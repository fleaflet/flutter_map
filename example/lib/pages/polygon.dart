import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class PolygonPage extends StatefulWidget {
  static const String route = "polygon";

  @override
  State<StatefulWidget> createState() => _PolygonPageState();

}

class _PolygonPageState extends State<PolygonPage> {

  bool _isEditing = false;

  final points = <LatLng>[
    new LatLng(51.5, -0.09),
    new LatLng(53.3498, -6.2603),
    new LatLng(48.8566, 2.3522),
  ];

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Polygons")),
      drawer: buildDrawer(context, PolygonPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text("Polygons"),
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
                  new PolygonLayerOptions(
                    polygons: [
                      new Polygon(
                          points: points,
                          borderColor: Colors.purple,
                          borderStrokeWidth: 4.0,
                          color: Colors.purpleAccent,
                      ),
                    ],
                    editable: _isEditing,
                  )
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