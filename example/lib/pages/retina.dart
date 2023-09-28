import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class RetinaPage extends StatefulWidget {
  static const String route = '/retina';

  final String defaultUrlTemplate =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}{r}?access_token={accessToken}';
  // TODO Remove
  final String defaultAccessToken =
      'pk.eyJ1IjoiZXhhbXBsZXMiLCJhIjoiY2p0MG01MXRqMW45cjQzb2R6b2ptc3J4MSJ9.zA2W0IkI0c6KaAhJfk9bWg';

  const RetinaPage({Key? key}) : super(key: key);

  @override
  State<RetinaPage> createState() => _RetinaPageState();
}

class _RetinaPageState extends State<RetinaPage> {
  bool retina = false;
  RetinaMethod retinaMethod = RetinaMethod.auto;

  late String urlTemplate;
  late String accessToken;

  @override
  void initState() {
    super.initState();

    urlTemplate = widget.defaultUrlTemplate;
    accessToken = widget.defaultAccessToken;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retina Tiles')),
      drawer: buildDrawer(context, RetinaPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                OverflowBar(
                  spacing: 8,
                  overflowAlignment: OverflowBarAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Retina'),
                        const SizedBox.square(dimension: 10),
                        Switch.adaptive(
                          value: retina,
                          onChanged: (v) => setState(() => retina = v),
                        ),
                        DropdownMenu(
                          label: const Text('Retina Method'),
                          initialSelection: RetinaMethod.auto,
                          enableSearch: false,
                          enabled: retina,
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(
                                label: 'auto', value: RetinaMethod.auto),
                            DropdownMenuEntry(
                                label: 'server', value: RetinaMethod.server),
                            DropdownMenuEntry(
                                label: 'simulate',
                                value: RetinaMethod.simulate),
                          ],
                          onSelected: (v) {
                            if (v == null) return;
                            setState(() => retinaMethod = v);
                          },
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 0,
                        maxWidth: 400,
                        minHeight: 0,
                        maxHeight: double.infinity,
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: widget.defaultUrlTemplate,
                            onChanged: (v) => setState(() => urlTemplate = v),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.link),
                              border: UnderlineInputBorder(),
                              labelText: 'URL Template',
                            ),
                          ),
                          TextFormField(
                            initialValue: widget.defaultAccessToken,
                            onChanged: (v) => setState(() => accessToken = v),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              border: const UnderlineInputBorder(),
                              labelText: 'Access Token',
                              errorText: accessToken.isEmpty
                                  ? "Please request a token from https://docs.mapbox.com/help/glossary/access-token/"
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox.square(dimension: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Screen Density: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                        '@${MediaQuery.of(context).devicePixelRatio.toStringAsFixed(2)}'
                        'x'),
                    const SizedBox.square(dimension: 10),
                    const Text(
                      'Chosen Method: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(retina
                        // ignore: invalid_use_of_visible_for_testing_member
                        ? TileLayer.determineRetinaMethod(
                                retinaMethod, urlTemplate)
                            .toString()
                        : 'Disabled'),
                  ],
                )
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
                          // TODO This URL can end in #/-74.5/40/10 to specify
                          // the location. Make this change automagically.
                          Uri.parse('https://www.mapbox.com/map-feedback/')),
                    ),
                  ],
                ),
              ],
              children: [
                if (accessToken.isNotEmpty)
                  TileLayer(
                    urlTemplate: urlTemplate,
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                    additionalOptions: {
                      'accessToken': accessToken,
                    },
                    retinaMode: retina,
                    retinaMethod: retinaMethod,
                    tileSize: 256,
                    tileBuilder: (context, tileWidget, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.white),
                      ),
                      position: DecorationPosition.foreground,
                      child: tileWidget,
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
