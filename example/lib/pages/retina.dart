import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class RetinaPage extends StatefulWidget {
  static const String route = '/retina';

  static const String _defaultUrlTemplate =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}{r}?access_token={accessToken}';

  const RetinaPage({super.key});

  @override
  State<RetinaPage> createState() => _RetinaPageState();
}

class _RetinaPageState extends State<RetinaPage> {
  String urlTemplate = RetinaPage._defaultUrlTemplate;
  final urlTemplateInputController = InputFieldStylizer(
    {
      '{r}': const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
      '{accessToken}': const TextStyle(fontStyle: FontStyle.italic),
      '{access_token}': const TextStyle(fontStyle: FontStyle.italic),
    },
    initialValue: RetinaPage._defaultUrlTemplate,
  );
  String? accessToken;

  bool? retinaMode;

  @override
  Widget build(BuildContext context) {
    final tileLayer = TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
      additionalOptions: {
        'accessToken': accessToken ?? '',
        'access_token': accessToken ?? '',
      },
      retinaMode: switch (retinaMode) {
        null => RetinaMode.isHighDensity(context),
        _ => retinaMode!,
      },
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
      drawer: const MenuDrawer(RetinaPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Retina Mode',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Checkbox.adaptive(
                            tristate: true,
                            value: retinaMode,
                            onChanged: (v) => setState(() => retinaMode = v),
                          ),
                          Text(switch (retinaMode) {
                            null => '(auto)',
                            true => '(force)',
                            false => '(disabled)',
                          }),
                        ],
                      ),
                      const SizedBox.square(dimension: 4),
                      Builder(
                        builder: (context) {
                          final dpr = MediaQuery.of(context).devicePixelRatio;
                          return RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                const TextSpan(
                                  text: 'Screen Density: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: '@${dpr.toStringAsFixed(2)}x\n'),
                                const TextSpan(
                                  text: 'Resulting Method: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text:
                                      tileLayer.resolvedRetinaMode.friendlyName,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (v) => setState(() => urlTemplate = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.link),
                            border: const UnderlineInputBorder(),
                            isDense: true,
                            labelText: 'URL Template',
                            helperText: urlTemplate.contains('{r}')
                                ? "Remove the '{r}' placeholder to simulate retina mode when enabled"
                                : "Add an '{r}' placeholder to request retina tiles when enabled",
                          ),
                          controller: urlTemplateInputController,
                        ),
                        TextField(
                          onChanged: (v) {
                            if (v == '' || (v != '' && accessToken == '')) {
                              setState(() => accessToken = v);
                            }
                          },
                          onSubmitted: (v) => setState(() => accessToken = v),
                          enabled: urlTemplate.contains('{accessToken}') ||
                              urlTemplate.contains('{access_token}'),
                          autofocus: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.password),
                            border: const UnderlineInputBorder(),
                            isDense: true,
                            labelText: 'Access Token',
                            errorText: (urlTemplate.contains('{accessToken}') ||
                                        urlTemplate
                                            .contains('{access_token}')) &&
                                    (accessToken?.isEmpty ?? true)
                                ? 'Insert your own access token (or remove the placeholder)'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(51.5, -0.09),
                initialZoom: 5,
                maxZoom: 19,
              ),
              children: [
                if (accessToken?.isNotEmpty ?? true) tileLayer,
                RichAttributionWidget(
                  attributions: [
                    LogoSourceAttribution(
                      Image.asset(
                        'assets/mapbox-logo-white.png',
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
            ),
          ),
        ],
      ),
    );
  }
}

// Inspired by https://stackoverflow.com/a/59773962/11846040
class InputFieldStylizer extends TextEditingController {
  final Map<String, TextStyle> mapping;
  final Pattern pattern;

  InputFieldStylizer(this.mapping, {String? initialValue})
      : pattern = RegExp(mapping.keys.map(RegExp.escape).join('|')),
        super(text: initialValue);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];

    text.splitMapJoin(
      pattern,
      onMatch: (match) {
        children.add(
          TextSpan(text: match[0], style: style!.merge(mapping[match[0]])),
        );
        return '';
      },
      onNonMatch: (text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
