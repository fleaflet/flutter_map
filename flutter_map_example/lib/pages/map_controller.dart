import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class MapControllerPage extends StatefulWidget {
  static const String route = 'map_controller';

  @override
  MapControllerPageState createState() {
    return new MapControllerPageState();
  }
}

class MapControllerPageState extends State<MapControllerPage> {
  static LatLng london = new LatLng(51.5, -0.09);
  static LatLng paris = new LatLng(48.8566, 2.3522);
  static LatLng dublin = new LatLng(53.3498, -6.2603);

  MapController mapController;

  void initState() {
    super.initState();
    mapController = new MapController();
  }

  Widget build(BuildContext context) {
    var markers = <Marker>[
      new Marker(
        width: 80.0,
        height: 80.0,
        point: london,
        builder: (ctx) => new Container(
          key: new Key("blue"),
              child: new FlutterLogo(),
            ),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: dublin,
        builder: (ctx) => new Container(
              child: new FlutterLogo(
                key: new Key("green"),
                colors: Colors.green,
              ),
            ),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: paris,
        builder: (ctx) => new Container(
          key: new Key("purple"),
              child: new FlutterLogo(colors: Colors.purple),
            ),
      ),
    ];

    return new Scaffold(
      appBar: new AppBar(title: new Text("MapController")),
      drawer: buildDrawer(context, MapControllerPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Row(
                children: <Widget>[
                  new MaterialButton(
                    child: new Text("London"),
                    onPressed: () {
                      mapController.move(london, 18.0);
                    },
                  ),
                  new MaterialButton(
                    child: new Text("Paris"),
                    onPressed: () {
                      mapController.move(paris, 5.0);
                    },
                  ),
                  new MaterialButton(
                    child: new Text("Dublin"),
                    onPressed: () {
                      mapController.move(dublin, 5.0);
                    },
                  ),
                ],
              ),
            ),
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Row(
                children: <Widget>[
                  new MaterialButton(
                    child: new Text("Fit Bounds"),
                    onPressed: () {
                      var bounds = new LatLngBounds();
                      bounds.extend(dublin);
                      bounds.extend(paris);
                      bounds.extend(london);
                      mapController.fitBounds(
                        bounds,
                        options: new FitBoundsOptions(
                          padding: new Point<double>(30.0, 0.0),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            new Flexible(
              child: new FlutterMap(
                mapController: mapController,
                options: new MapOptions(
                  center: new LatLng(51.5, -0.09),
                  zoom: 5.0,
                  maxZoom: 5.0,
                  minZoom: 3.0
                ),
                layers: [
                  new TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
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
