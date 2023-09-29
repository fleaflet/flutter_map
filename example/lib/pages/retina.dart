import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class RetinaPage extends StatefulWidget {
  static const String route = '/retina';

  static const String _defaultUrlTemplate =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}{r}?access_token={accessToken}';

  const RetinaPage({Key? key}) : super(key: key);

  @override
  State<RetinaPage> createState() => _RetinaPageState();
}

class _RetinaPageState extends State<RetinaPage> {
  RetinaMethod? retinaMethod = RetinaMethod.auto;
  String urlTemplate = RetinaPage._defaultUrlTemplate;
  String? accessToken;

  @override
  Widget build(BuildContext context) {
    final tileLayer = TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
      additionalOptions: {'accessToken': accessToken ?? ''},
      retinaContext: retinaMethod == null ? null : context,
      retinaMethod: retinaMethod ?? RetinaMethod.auto,
      tileBuilder: (context, tileWidget, _) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.white),
        ),
        position: DecorationPosition.foreground,
        child: tileWidget,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Retina Tiles')),
      drawer: buildDrawer(context, RetinaPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Column(
                  children: [
                    DropdownMenu(
                      label: const Text('Retina Method'),
                      initialSelection: RetinaMethod.auto,
                      enableSearch: false,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(
                          label: 'Disabled',
                          value: null,
                        ),
                        DropdownMenuEntry(
                          label: 'Automatic',
                          value: RetinaMethod.auto,
                        ),
                        DropdownMenuEntry(
                          label: 'Prefer Real',
                          value: RetinaMethod.preferServer,
                        ),
                        DropdownMenuEntry(
                          label: 'Force Simulation',
                          // ignore: invalid_use_of_visible_for_testing_member
                          value: RetinaMethod.forceSimulation,
                        ),
                      ],
                      onSelected: (v) => setState(() => retinaMethod = v),
                    ),
                    Builder(
                        key: UniqueKey(),
                        builder: (context) {
                          final dpr = MediaQuery.of(context).devicePixelRatio;
                          return RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                const TextSpan(
                                  text: '\nScreen Density: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: '@${dpr.toStringAsFixed(2)}x\n'),
                                const TextSpan(
                                  text: 'Is Retina Eligible: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: '${dpr > 1 ? 'Yes' : 'No'}\n'),
                                const TextSpan(
                                  text: 'Resulting Method: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: !tileLayer.useServerRetina &&
                                          !tileLayer.useSimulatedRetina
                                      ? 'Disabled'
                                      : tileLayer.useServerRetina
                                          ? 'Server'
                                          : 'Simulated',
                                ),
                              ],
                            ),
                          );
                        }),
                  ],
                ),
                const SizedBox.square(dimension: 12),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: RetinaPage._defaultUrlTemplate,
                        onChanged: (v) => setState(() => urlTemplate = v),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.link),
                          border: UnderlineInputBorder(),
                          labelText: 'URL Template',
                        ),
                      ),
                      TextFormField(
                        onChanged: (v) => setState(() => accessToken = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          border: const UnderlineInputBorder(),
                          labelText: 'Access Token',
                          errorText: accessToken?.isEmpty ?? true
                              ? 'Insert your own access token'
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(51.5, -0.09),
                initialZoom: 5,
                maxZoom: 19,
              ),
              nonRotatedChildren: [
                RichAttributionWidget(
                  attributions: [
                    LogoSourceAttribution(
                      Image.asset(
                        "assets/mapbox-logo-white.png",
                        color: Colors.black,
                      ),
                      height: 16,
                    ),
                    TextSourceAttribution(
                      'Mapbox',
                      onTap: () => launchUrl(
                          Uri.parse('https://www.mapbox.com/about/maps/')),
                    ),
                    TextSourceAttribution(
                      'OpenStreetMap',
                      onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright')),
                    ),
                    TextSourceAttribution(
                      'Improve this map',
                      prependCopyright: false,
                      onTap: () => launchUrl(
                          Uri.parse('https://www.mapbox.com/map-feedback')),
                    ),
                  ],
                ),
              ],
              children: [if (accessToken?.isNotEmpty ?? false) tileLayer],
            ),
          ),
        ],
      ),
    );
  }
}
