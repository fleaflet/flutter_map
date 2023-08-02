import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong2/latlong.dart';

class InteractiveTestPage extends StatefulWidget {
  static const String route = 'interactive_test_page';

  const InteractiveTestPage({Key? key}) : super(key: key);

  @override
  State createState() {
    return _InteractiveTestPageState();
  }
}

class _InteractiveTestPageState extends State<InteractiveTestPage> {
  final availableFlags = {
    'Movement': {
      InteractiveFlag.drag: 'Drag',
      InteractiveFlag.flingAnimation: 'Fling',
      InteractiveFlag.pinchMove: 'Pinch',
    },
    'Zooming': {
      InteractiveFlag.pinchZoom: 'Pinch',
      InteractiveFlag.scrollWheelZoom: 'Scroll',
      InteractiveFlag.doubleTapZoom: 'Double tap',
      InteractiveFlag.doubleTapDragZoom: '+ drag',
    },
    'Rotation': {
      InteractiveFlag.rotate: 'Twist',
    },
  };

  // Enable pinchZoom and doubleTapZoomBy by default
  int flags = InteractiveFlag.drag | InteractiveFlag.pinchZoom;

  bool keyboardCursorRotate = false;

  MapEvent? _latestEvent;

  @override
  void initState() {
    super.initState();
  }

  void onMapEvent(MapEvent mapEvent) {
    if (mapEvent is! MapEventMove && mapEvent is! MapEventRotate) {
      // do not flood console with move and rotate events
      debugPrint(_eventName(mapEvent));
    }

    setState(() {
      _latestEvent = mapEvent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Flags')),
      drawer: buildDrawer(context, InteractiveTestPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Flex(
              direction: MediaQuery.of(context).size.width >= 600
                  ? Axis.horizontal
                  : Axis.vertical,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: availableFlags.entries
                  .map<Widget?>(
                    (category) => Column(
                      children: [
                        Text(
                          category.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...category.value.entries
                                .map<Widget>(
                                  (e) => Column(
                                    children: [
                                      Checkbox.adaptive(
                                        value: InteractiveFlag.hasFlag(
                                            e.key, flags),
                                        onChanged: (enabled) {
                                          if (!enabled!) {
                                            flags &= ~e.key;
                                          } else {
                                            flags |= e.key;
                                          }
                                          setState(() {});
                                        },
                                      ),
                                      Text(e.value),
                                    ],
                                  ),
                                )
                                .interleave(const SizedBox(width: 12)),
                            if (category.key == 'Rotation') ...[
                              Column(
                                children: [
                                  Checkbox.adaptive(
                                    value: keyboardCursorRotate,
                                    onChanged: (enabled) => setState(
                                        () => keyboardCursorRotate = enabled!),
                                  ),
                                  const Text('Cursor & CTRL'),
                                ],
                              ),
                              const SizedBox(width: 12),
                            ]
                          ]..removeLast(),
                        )
                      ],
                    ),
                  )
                  .interleave(
                    MediaQuery.of(context).size.width >= 600
                        ? null
                        : const SizedBox(height: 12),
                  )
                  .whereType<Widget>()
                  .toList(),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: Text(
                  'Current event: ${_eventName(_latestEvent)}\nSource: ${_latestEvent?.source.name ?? "none"}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  onMapEvent: onMapEvent,
                  initialCenter: const LatLng(51.5, -0.09),
                  initialZoom: 11,
                  interactionOptions: InteractionOptions(
                    flags: flags,
                    isCursorRotationKeyboardKeyTrigger: (key) =>
                        keyboardCursorRotate &&
                        {
                          LogicalKeyboardKey.control,
                          LogicalKeyboardKey.controlLeft,
                          LogicalKeyboardKey.controlRight
                        }.contains(key),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _eventName(MapEvent? event) {
    switch (event) {
      case MapEventTap():
        return 'MapEventTap';
      case MapEventSecondaryTap():
        return 'MapEventSecondaryTap';
      case MapEventLongPress():
        return 'MapEventLongPress';
      case MapEventMove():
        return 'MapEventMove';
      case MapEventMoveStart():
        return 'MapEventMoveStart';
      case MapEventMoveEnd():
        return 'MapEventMoveEnd';
      case MapEventFlingAnimation():
        return 'MapEventFlingAnimation';
      case MapEventFlingAnimationNotStarted():
        return 'MapEventFlingAnimationNotStarted';
      case MapEventFlingAnimationStart():
        return 'MapEventFlingAnimationStart';
      case MapEventFlingAnimationEnd():
        return 'MapEventFlingAnimationEnd';
      case MapEventDoubleTapZoom():
        return 'MapEventDoubleTapZoom';
      case MapEventScrollWheelZoom():
        return 'MapEventScrollWheelZoom';
      case MapEventDoubleTapZoomStart():
        return 'MapEventDoubleTapZoomStart';
      case MapEventDoubleTapZoomEnd():
        return 'MapEventDoubleTapZoomEnd';
      case MapEventRotate():
        return 'MapEventRotate';
      case MapEventRotateStart():
        return 'MapEventRotateStart';
      case MapEventRotateEnd():
        return 'MapEventRotateEnd';
      case MapEventNonRotatedSizeChange():
        return 'MapEventNonRotatedSizeChange';
      case null:
        return 'null';
      default:
        return 'Unknown';
    }
  }
}

extension _IterableExt<E> on Iterable<E> {
  Iterable<E> interleave(E separator) sync* {
    for (int i = 0; i < length; i++) {
      yield elementAt(i);
      if (i < length) yield separator;
    }
  }
}
