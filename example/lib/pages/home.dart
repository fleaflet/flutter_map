import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    const seenIntroBoxKey = 'seenIntroBox(a)';
    if (kIsWeb && Uri.base.host.trim() == 'demo.fleaflet.dev') {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) async {
          final prefs = await SharedPreferences.getInstance();
          if (prefs.getBool(seenIntroBoxKey) ?? false) return;

          if (!mounted) return;

          final width = MediaQuery.of(context).size.width;
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              icon: UnconstrainedBox(
                child: SizedBox.square(
                  dimension: 64,
                  child:
                      Image.asset('assets/ProjectIcon.png', fit: BoxFit.fill),
                ),
              ),
              title: const Text('flutter_map Live Web Demo'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width < 750
                      ? double.infinity
                      : (width / (width < 1100 ? 1.5 : 2.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "This is built automatically off of the latest commits to 'master', so may not reflect the latest release available on pub.dev.\nThis is hosted on Firebase Hosting, meaning there's limited bandwidth to share between all users, so please keep loads to a minimum.",
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 8, top: 16, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "This won't be shown again",
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .inverseSurface
                                .withOpacity(0.5),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  label: const Text('OK'),
                  icon: const Icon(Icons.done),
                ),
              ],
              contentPadding: const EdgeInsets.only(
                left: 24,
                top: 16,
                bottom: 0,
                right: 24,
              ),
            ),
          );
          await prefs.setBool(seenIntroBoxKey, true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: buildDrawer(context, HomePage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text('This is a map that is showing (51.5, -0.9).'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(51.5, -0.09),
                  initialZoom: 5,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(-90, -180),
                      const LatLng(90, 180),
                    ),
                  ),
                ),
                nonRotatedChildren: [
                  RichAttributionWidget(
                    popupInitialDisplayDuration: const Duration(seconds: 5),
                    animationConfig: const ScaleRAWA(),
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://openstreetmap.org/copyright'),
                        ),
                      ),
                      const TextSourceAttribution(
                        'This attribution is the same throughout this app, except where otherwise specified',
                        prependCopyright: false,
                      ),
                    ],
                  ),
                ],
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                  const MarkerLayer(
                    markers: [
                      Marker(
                        width: 80,
                        height: 80,
                        point: LatLng(51.5, -0.09),
                        child: FlutterLogo(
                          textColor: Colors.blue,
                          key: ObjectKey(Colors.blue),
                        ),
                      ),
                      Marker(
                        width: 80,
                        height: 80,
                        point: LatLng(53.3498, -6.2603),
                        child: FlutterLogo(
                          textColor: Colors.green,
                          key: ObjectKey(Colors.green),
                        ),
                      ),
                      Marker(
                        width: 80,
                        height: 80,
                        point: LatLng(48.8566, 2.3522),
                        child: FlutterLogo(
                          textColor: Colors.purple,
                          key: ObjectKey(Colors.purple),
                        ),
                      ),
                    ],
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
