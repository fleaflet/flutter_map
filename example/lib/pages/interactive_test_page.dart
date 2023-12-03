import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class InteractiveFlagsPage extends StatefulWidget {
  static const String route = '/interactive_flags_page';

  const InteractiveFlagsPage({super.key});

  @override
  State createState() => _InteractiveFlagsPageState();
}

class _InteractiveFlagsPageState extends State<InteractiveFlagsPage> {
  static const availableFlags = {
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

  int flags = InteractiveFlag.drag | InteractiveFlag.pinchZoom;
  bool keyboardCursorRotate = false;

  MapEvent? _latestEvent;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Flags')),
      drawer: const MenuDrawer(InteractiveFlagsPage.route),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Flex(
              direction: screenWidth >= 600 ? Axis.horizontal : Axis.vertical,
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
                          children: <Widget>[
                            ...category.value.entries.map(
                              (e) => Column(
                                children: [
                                  Checkbox.adaptive(
                                    value:
                                        InteractiveFlag.hasFlag(e.key, flags),
                                    onChanged: (enabled) {
                                      if (!enabled!) {
                                        setState(() => flags &= ~e.key);
                                        return;
                                      }
                                      setState(() => flags |= e.key);
                                    },
                                  ),
                                  Text(e.value),
                                ],
                              ),
                            ),
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
                            ]
                          ].interleave(const SizedBox(width: 12)).toList()
                            ..removeLast(),
                        )
                      ],
                    ),
                  )
                  .interleave(
                    screenWidth >= 600 ? null : const SizedBox(height: 12),
                  )
                  .whereType<Widget>()
                  .toList(),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'Current event: ${_eventName(_latestEvent)}\n'
                  'Source: ${_latestEvent?.source.name ?? "none"}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  onMapEvent: (evt) => setState(() => _latestEvent = evt),
                  initialCenter: const LatLng(51.5, -0.09),
                  initialZoom: 11,
                  interactionOptions: InteractionOptions(
                    flags: flags,
                    cursorKeyboardRotationOptions:
                        CursorKeyboardRotationOptions(
                      isKeyTrigger: (key) =>
                          keyboardCursorRotate &&
                          CursorKeyboardRotationOptions.defaultTriggerKeys
                              .contains(key),
                    ),
                  ),
                ),
                children: [openStreetMapTileLayer],
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
