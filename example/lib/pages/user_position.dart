import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class UserPostionPage extends StatefulWidget {
  static const String route = 'user_position';

  @override
  _UserPositionPageState createState() => _UserPositionPageState();
}

List<LatLng> positions = [
  LatLng(
    48.851401888437294,
    2.3431509733200073,
  ),
  LatLng(
    48.85148307522343,
    2.3431992530822754,
  ),
  LatLng(
    48.8515819111332,
    2.343258261680603,
  ),
  LatLng(
    48.85168074684787,
    2.3433226346969604,
  ),
  LatLng(
    48.85183605971957,
    2.343381643295288,
  ),
  LatLng(
    48.851949014232765,
    2.3434245586395264,
  ),
  LatLng(
    48.85210432627228,
    2.3435157537460323,
  ),
  LatLng(
    48.85227728684016,
    2.34358012676239,
  ),
  LatLng(
    48.85243612765169,
    2.3436713218688965,
  ),
  LatLng(
    48.85260202751681,
    2.3437464237213135,
  ),
  LatLng(
    48.85272556961246,
    2.3438000679016113,
  ),
  LatLng(
    48.85276439706526,
    2.3438215255737305,
  ),
  LatLng(
    48.85273262915158,
    2.343987822532654,
  ),
  LatLng(
    48.8526443848411,
    2.344282865524292,
  ),
  LatLng(
    48.85259496795929,
    2.344508171081543,
  ),
  LatLng(
    48.852524372329235,
    2.344679832458496,
  ),
  LatLng(
    48.852457306388494,
    2.344733476638794,
  ),
  LatLng(
    48.85230199544395,
    2.3445403575897217,
  ),
  LatLng(
    48.8521608032581,
    2.3444008827209473,
  ),
  LatLng(
    48.852044319405046,
    2.3442560434341426,
  ),
  LatLng(
    48.85193489493255,
    2.344180941581726,
  ),
  LatLng(
    48.85188194752128,
    2.3443418741226196,
  ),
  LatLng(
    48.85176899285682,
    2.3446744680404663,
  ),
  LatLng(
    48.851708985587635,
    2.3448944091796875,
  ),
  LatLng(
    48.851592500683374,
    2.3452752828598022,
  ),
  LatLng(
    48.85150425436337,
    2.345559597015381,
  ),
  LatLng(
    48.85141953774982,
    2.345806360244751,
  ),
];

class _UserPositionPageState extends State<UserPostionPage> {
  Timer _timer;
  StreamController<LatLng> userPosition = StreamController<LatLng>.broadcast();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timer.tick == positions.length) {
        _timer.cancel();
        return;
      }

      var point = positions[timer.tick - 1];
      userPosition.add(point);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User position')),
      drawer: buildDrawer(context, UserPostionPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text('User position'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: positions[0],
                  zoom: 18.0,
                ),
                layers: [
                  TileLayerWidget(
                    options: TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                  ),
                  UserPositionLayer(stream: userPosition.stream),
                  UserPositionLinesLayer(stream: userPosition.stream),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserPositionLayer extends StatefulWidget {
  final Stream<LatLng> stream;
  UserPositionLayer({@required this.stream});

  @override
  _UserPositionLayerState createState() => _UserPositionLayerState();
}

class _UserPositionLayerState extends State<UserPositionLayer> {
  Marker _marker;

  Marker _createMarker(LatLng point) {
    return Marker(
      width: 16.0,
      height: 16.0,
      point: point,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.white, width: 2.0),
          boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 5.0)],
        ),
      ),
    );
  }

  StreamSubscription _sub;

  @override
  void initState() {
    _marker = _createMarker(positions[0]);
    _sub = widget.stream.listen((point) {
      setState(() {
        _marker = _createMarker(point);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayerWidget(
      markers: [_marker],
    );
  }
}

class UserPositionLinesLayer extends StatefulWidget {
  final Stream<LatLng> stream;
  UserPositionLinesLayer({@required this.stream});

  @override
  _UserPositionLinesLayer createState() => _UserPositionLinesLayer();
}

class _UserPositionLinesLayer extends State<UserPositionLinesLayer> {
  StreamSubscription _sub;
  List<LatLng> _points;

  @override
  void initState() {
    _points = [];
    _sub = widget.stream.listen((point) {
      setState(() {
        _points.add(point);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PolylineLayerWidget(
      polylines: [
        Polyline(
          points: _points,
          strokeWidth: 4.0,
          color: Colors.blueAccent,
        ),
      ],
    );
  }
}
