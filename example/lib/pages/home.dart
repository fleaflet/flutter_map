import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/misc/timed_future.dart';
import 'package:flutter_map_example/widgets/drawer/floating_menu_button.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/first_start_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  const HomePage({
    super.key,
    required this.cacheInitComplete,
  });

  final TimedFuture<int?>? cacheInitComplete;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    showIntroDialogIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuDrawer(HomePage.route),
      body: Stack(
        children: [
          if (widget.cacheInitComplete case final cacheInitComplete?)
            Positioned.fill(
              child: FutureBuilder(
                future: cacheInitComplete.result,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return const ColoredBox(color: Color(0xFFE0E0E0));
                  }
                  return const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 16,
                      children: [
                        SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator.adaptive(),
                        ),
                        Text('Awaiting cache initialisation'),
                      ],
                    ),
                  );
                },
              ),
            ),
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(51.5, -0.09),
              initialZoom: 5,
              backgroundColor: Colors.transparent,
            ),
            children: [
              openStreetMapTileLayer,
              RichAttributionWidget(
                popupInitialDisplayDuration: const Duration(seconds: 5),
                animationConfig: const ScaleRAWA(),
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () async => launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'),
                    ),
                  ),
                  const TextSourceAttribution(
                    'This attribution is the same throughout this app, except '
                    'where otherwise specified',
                    prependCopyright: false,
                  ),
                ],
              ),
            ],
          ),
          const FloatingMenuButton()
        ],
      ),
    );
  }

  void showIntroDialogIfNeeded() {
    const seenIntroBoxKey = 'seenIntroBox(a)';
    if (kIsWeb && Uri.base.host.trim() == 'demo.fleaflet.dev') {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) async {
          final prefs = await SharedPreferences.getInstance();
          if (prefs.getBool(seenIntroBoxKey) ?? false) return;

          if (!mounted) return;

          await showDialog<void>(
            context: context,
            builder: (context) => const FirstStartDialog(),
          );
          await prefs.setBool(seenIntroBoxKey, true);
        },
      );
    }
  }
}
