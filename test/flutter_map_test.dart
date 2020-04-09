import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong/latlong.dart';

void main() {
  testWidgets('flutter_map', (tester) async {
    await tester.pumpWidget(TestApp());
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(TileLayer), findsOneWidget);
    expect(find.byType(RawImage), findsWidgets);
    expect(find.byType(MarkerLayer), findsWidgets);
    expect(find.byType(FlutterLogo), findsOneWidget);
  });
}

class TestApp extends StatefulWidget {
  @override
  _TestAppState createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  final List<Marker> _markers = <Marker>[
    Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(45.5231, -122.6765),
      builder: (ctx) => Container(
        child: FlutterLogo(),
      ),
    ),
    Marker(
      width: 80.0,
      height: 80.0,
      point: LatLng(40, -120), // not visible
      builder: (ctx) => Container(
        child: FlutterLogo(),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            width: 200,
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(45.5231, -122.6765),
                zoom: 13.0,
              ),
              layers: [
                TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c']),
                MarkerLayerOptions(markers: _markers),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
