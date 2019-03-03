import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/drawer.dart';

class OfflineMBTilesMapPage extends StatefulWidget {
  static const String route = '/offline_mbtiles_map';

  @override
  _OfflineMBTilesMapPageState createState() => _OfflineMBTilesMapPageState();
}

class _OfflineMBTilesMapPageState extends State<OfflineMBTilesMapPage> {
  File db;

  @override
  void initState() {
    super.initState();

    loadAsset("assets/berlin.mbtiles");
  }

  Future loadAsset(String asset) async {
    var tempDir = await getTemporaryDirectory();
    var filename = asset.split("/").last;
    var file = File("${tempDir.path}/$filename");

    var data = await rootBundle.load(asset);
    file.writeAsBytesSync(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true);
    setState(() {
      db = file;
    });
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Offline Map (using MBTiles)")),
      drawer: buildDrawer(context, OfflineMBTilesMapPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Padding(
              padding: new EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text(
                  "This is an offline map of Berlin, Germany using a single MBTiles file. The file was built from the stamen toner map data (http://maps.stamen.com).\n\n"
                  "(Map tiles by Stamen Design, under CC BY 3.0. Data by OpenStreetMap, under ODbL.)"),
            ),
            new Flexible(
              child: db == null
                  ? Container()
                  : new FlutterMap(
                      options: new MapOptions(
                        center: new LatLng(
                          52.516144904680495,
                          13.404938674758466,
                        ),
                        minZoom: 10.0,
                        maxZoom: 13.0,
                        zoom: 11.0,
                        swPanBoundary:
                            LatLng(52.482205339202984, 13.272081510335342),
                        nePanBoundary:
                            LatLng(52.550084470158005, 13.537795839181591),
                      ),
                      layers: [
                        new TileLayerOptions(
                            tileProvider: MBTilesImageProvider.fromFile(db),
                            maxZoom: 13.0,
                            tms: true),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
