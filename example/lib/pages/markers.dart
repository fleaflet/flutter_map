import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class MarkerPage extends StatefulWidget {
  static const String route = '/markers';

  const MarkerPage({super.key});

  @override
  State<MarkerPage> createState() => _MarkerPageState();
}

class _MarkerPageState extends State<MarkerPage> {
  Alignment selectedAlignment = Alignment.topCenter;
  bool counterRotate = false;
  bool constrainMeterMarkers = false;

  static const alignments = {
    315: Alignment.topLeft,
    0: Alignment.topCenter,
    45: Alignment.topRight,
    270: Alignment.centerLeft,
    null: Alignment.center,
    90: Alignment.centerRight,
    225: Alignment.bottomLeft,
    180: Alignment.bottomCenter,
    135: Alignment.bottomRight,
  };

  late final customMarkers = <Marker>[
    buildPin(const LatLng(51.51868093513547, -0.12835376940892318)),
    buildPin(const LatLng(53.33360293799854, -6.284001062079881)),
  ];

  Marker buildPin(LatLng point) => Marker(
        point: point,
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tapped existing marker'),
              duration: Duration(seconds: 1),
              showCloseIcon: true,
            ),
          ),
          child: const Icon(Icons.location_pin, size: 60, color: Colors.black),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markers')),
      drawer: const MenuDrawer(MarkerPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 20,
              spacing: 20,
              children: [
                Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotatedBox(
                      quarterTurns: 3,
                      child: FittedBox(
                        child: Text(
                          'ALIGNMENT OF PINS',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 130,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                        ),
                        itemCount: 9,
                        itemBuilder: (_, index) {
                          final deg = alignments.keys.elementAt(index);
                          final align = alignments.values.elementAt(index);

                          return IconButton.outlined(
                            onPressed: () =>
                                setState(() => selectedAlignment = align),
                            icon: Transform.rotate(
                              angle: deg == null ? 0 : deg * pi / 180,
                              child: Icon(
                                deg == null ? Icons.circle : Icons.arrow_upward,
                                color: selectedAlignment == align
                                    ? Colors.green
                                    : null,
                                size: deg == null ? 16 : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          'Tap/click map to\nadd more pins',
                          textAlign: TextAlign.center,
                        ),
                        Icon(Icons.add_location, size: 32)
                      ],
                    ),
                  ),
                ),
                IntrinsicWidth(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 12,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(child: Text('Counter rotate to map')),
                          Switch.adaptive(
                            value: counterRotate,
                            onChanged: (v) => setState(() => counterRotate = v),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 12,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                              child: Text('Constraints on meter marker')),
                          Switch.adaptive(
                            value: constrainMeterMarkers,
                            onChanged: (v) =>
                                setState(() => constrainMeterMarkers = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(51.5, -0.09),
                initialZoom: 5,
                onTap: (_, p) => setState(() => customMarkers.add(buildPin(p))),
                interactionOptions: const InteractionOptions(
                  flags: ~InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                openStreetMapTileLayer,
                MarkerLayer(
                  rotate: counterRotate,
                  markers: [
                    const Marker(
                      point: LatLng(47.18664, -1.54367),
                      width: 64,
                      height: 64,
                      alignment: Alignment.centerLeft,
                      child: ColoredBox(
                        color: Colors.lightBlue,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('-->'),
                        ),
                      ),
                    ),
                    const Marker(
                      point: LatLng(47.18664, -1.54367),
                      width: 64,
                      height: 64,
                      alignment: Alignment.centerRight,
                      child: ColoredBox(
                        color: Colors.pink,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('<--'),
                        ),
                      ),
                    ),
                    const Marker(
                      point: LatLng(47.18664, -1.54367),
                      rotate: false,
                      child: ColoredBox(color: Colors.black),
                    ),
                    Marker(
                      point: const LatLng(
                        0,
                        -0.12835,
                      ),
                      height: 500000,
                      width: 300000,
                      useDimensionsInMeters: constrainMeterMarkers
                          ? const BoxConstraints(maxHeight: 200, maxWidth: 200)
                          : const BoxConstraints(),
                      child: _MeterMarkerChild(
                        label: '500x300km\n('
                            '${constrainMeterMarkers ? '0-200px²' : 'constraints off'})',
                      ),
                    ),
                    Marker(
                      point: const LatLng(
                        51.51868,
                        -0.12835,
                      ),
                      height: 1000,
                      width: 1000,
                      useDimensionsInMeters: constrainMeterMarkers
                          ? const BoxConstraints(
                              minHeight: 30,
                              minWidth: 30,
                              maxHeight: 1000,
                              maxWidth: 1000,
                            )
                          : const BoxConstraints(),
                      child: _MeterMarkerChild(
                        label: '\n\n1km²\n('
                            '${constrainMeterMarkers ? '30px²-1000px²' : 'constraints off'})',
                      ),
                    ),
                    const Marker(
                      point: LatLng(
                        71.51868,
                        -0.12835,
                      ),
                      height: 500000,
                      width: 300000,
                      useDimensionsInMeters: BoxConstraints(),
                      child: _MeterMarkerChild(
                        label: '500x300km\n(no constraints)',
                      ),
                    ),
                  ],
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: const LatLng(
                        0,
                        -0.12835,
                      ),
                      radius: 150000,
                      useRadiusInMeter: true,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    CircleMarker(
                      point: const LatLng(
                        71.51868,
                        -0.12835,
                      ),
                      radius: 150000,
                      useRadiusInMeter: true,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: customMarkers,
                  rotate: counterRotate,
                  alignment: selectedAlignment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeterMarkerChild extends StatelessWidget {
  const _MeterMarkerChild({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) => DecoratedBox(
          decoration: BoxDecoration(border: Border.all()),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Center(child: Text(label, textAlign: TextAlign.center)),
            ),
          ),
        ),
      ),
    );
  }
}
