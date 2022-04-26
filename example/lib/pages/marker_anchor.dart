import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/drawer.dart';

class MarkerAnchorPage extends StatefulWidget {
  static const String route = '/marker_anchors';

  const MarkerAnchorPage({Key? key}) : super(key: key);

  @override
  MarkerAnchorPageState createState() {
    return MarkerAnchorPageState();
  }
}

class MarkerAnchorPageState extends State<MarkerAnchorPage> {
  late AnchorPos anchorPos;

  @override
  void initState() {
    super.initState();
    anchorPos = AnchorPos.align(AnchorAlign.center);
  }

  void _setAnchorAlignPos(AnchorAlign alignOpt) {
    setState(() {
      anchorPos = AnchorPos.align(alignOpt);
    });
  }

  void _setAnchorExactlyPos(Anchor anchor) {
    setState(() {
      anchorPos = AnchorPos.exactly(anchor);
    });
  }

  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(51.5, -0.09),
        builder: (ctx) => const FlutterLogo(),
        anchorPos: anchorPos,
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(53.3498, -6.2603),
        builder: (ctx) => const FlutterLogo(
          textColor: Colors.green,
        ),
        anchorPos: anchorPos,
      ),
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(48.8566, 2.3522),
        builder: (ctx) => const FlutterLogo(textColor: Colors.purple),
        anchorPos: anchorPos,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Marker Anchor Points')),
      drawer: buildDrawer(context, MarkerAnchorPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                  'Markers can be anchored to the top, bottom, left or right.'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Wrap(
                children: <Widget>[
                  MaterialButton(
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.left),
                    child: const Text('Left'),
                  ),
                  MaterialButton(
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.right),
                    child: const Text('Right'),
                  ),
                  MaterialButton(
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.top),
                    child: const Text('Top'),
                  ),
                  MaterialButton(
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.bottom),
                    child: const Text('Bottom'),
                  ),
                  MaterialButton(
                    onPressed: () => _setAnchorAlignPos(AnchorAlign.center),
                    child: const Text('Center'),
                  ),
                  MaterialButton(
                    onPressed: () => _setAnchorExactlyPos(Anchor(80.0, 80.0)),
                    child: const Text('Custom'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                ),
                layers: [
                  TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
