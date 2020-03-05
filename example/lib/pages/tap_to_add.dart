import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class TapToAddPage extends StatefulWidget {
  static const String route = '/tap';

  @override
  State<StatefulWidget> createState() {
    return TapToAddPageState();
  }
}

class TapToAddPageState extends State<TapToAddPage> {
  MapOptions options = MapOptions();
  StreamController<LatLng> streamController =
      StreamController<LatLng>.broadcast();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tap to add pins')),
      drawer: buildDrawer(context, TapToAddPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('Tap to add pins'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(45.5231, -122.6765),
                  zoom: 13.0,
                  onTap: (position) {
                    streamController.add(position);
                  },
                ),
                layers: [
                  TileLayerWidget(
                    options: TileLayerOptions(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                  ),
                  HandleTapMarkerWidget(
                    stream: streamController.stream,
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

class HandleTapMarkerWidget extends StatefulWidget {
  final Stream<LatLng> stream;

  HandleTapMarkerWidget({this.stream});

  @override
  _HandleTapMarkerWidgetState createState() => _HandleTapMarkerWidgetState();
}

class _HandleTapMarkerWidgetState extends State<HandleTapMarkerWidget> {
  List<Marker> markers = [];
  StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen((latlng) {
      setState(() {
        var marker = Marker(
          width: 80.0,
          height: 80.0,
          point: latlng,
          builder: (ctx) => Container(
            child: FlutterLogo(),
          ),
        );
        markers.add(marker);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _sub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayerWidget(markers: markers);
  }
}
