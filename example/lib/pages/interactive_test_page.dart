import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:latlong2/latlong.dart';

class InteractiveFlagsPage extends StatefulWidget {
  static const String route = '/interactive_flags';

  const InteractiveFlagsPage({super.key});

  @override
  State createState() => _InteractiveFlagsPageState();
}

class _InteractiveFlagsPageState extends State<InteractiveFlagsPage> {
  final flagsSet = ValueNotifier(
    InteractiveFlag.drag |
        InteractiveFlag.pinchZoom |
        InteractiveFlag.scrollWheelZoom,
  );

  bool keyboardCursorRotate = false;
  bool keyboardArrowsMove = false;
  bool keyboardWASDMove = false;
  bool keyboardQERotate = false;
  bool keyboardRFZoom = false;

  bool useSmoothScrollZooming = true;

  MapEvent? _latestEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Flags')),
      drawer: const MenuDrawer(InteractiveFlagsPage.route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 32,
                runSpacing: 16,
                alignment: WrapAlignment.spaceEvenly,
                runAlignment: WrapAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      const Text(
                        'Move/Pan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          InteractiveFlagCheckbox(
                            name: 'Drag',
                            flag: InteractiveFlag.drag,
                            flagsSet: flagsSet,
                          ),
                          InteractiveFlagCheckbox(
                            name: 'Fling',
                            flag: InteractiveFlag.flingAnimation,
                            flagsSet: flagsSet,
                          ),
                          InteractiveFlagCheckbox(
                            name: 'Pinch',
                            flag: InteractiveFlag.pinchMove,
                            flagsSet: flagsSet,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox.adaptive(
                                value: keyboardArrowsMove,
                                onChanged: (enabled) => setState(
                                  () => keyboardArrowsMove = enabled!,
                                ),
                              ),
                              const Text(
                                'Keyboard\nArrows',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox.adaptive(
                                value: keyboardWASDMove,
                                onChanged: (enabled) => setState(
                                  () => keyboardWASDMove = enabled!,
                                ),
                              ),
                              const Text(
                                'Keyboard\nW/A/S/D',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      const Text(
                        'Zoom',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          InteractiveFlagCheckbox(
                            name: 'Pinch',
                            flag: InteractiveFlag.pinchZoom,
                            flagsSet: flagsSet,
                          ),
                          InteractiveFlagCheckbox(
                            name: 'Scroll',
                            flag: InteractiveFlag.scrollWheelZoom,
                            flagsSet: flagsSet,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox.adaptive(
                                value: useSmoothScrollZooming,
                                onChanged: (enabled) => setState(
                                  () => useSmoothScrollZooming = enabled!,
                                ),
                              ),
                              const Text(
                                '(smooth)',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          InteractiveFlagCheckbox(
                            name: 'Double tap',
                            flag: InteractiveFlag.doubleTapZoom,
                            flagsSet: flagsSet,
                          ),
                          InteractiveFlagCheckbox(
                            name: '+ drag',
                            flag: InteractiveFlag.doubleTapDragZoom,
                            flagsSet: flagsSet,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox.adaptive(
                                value: keyboardRFZoom,
                                onChanged: (enabled) => setState(
                                  () => keyboardRFZoom = enabled!,
                                ),
                              ),
                              const Text(
                                'Keyboard\nR/F',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      const Text(
                        'Rotate',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          InteractiveFlagCheckbox(
                            name: 'Twist',
                            flag: InteractiveFlag.rotate,
                            flagsSet: flagsSet,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox.adaptive(
                                value: keyboardCursorRotate,
                                onChanged: (enabled) => setState(
                                  () => keyboardCursorRotate = enabled!,
                                ),
                              ),
                              const Text(
                                'Cursor\n& CTRL',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox.adaptive(
                                value: keyboardQERotate,
                                onChanged: (enabled) => setState(
                                  () => keyboardQERotate = enabled!,
                                ),
                              ),
                              const Text(
                                'Keyboard\nQ/E',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                'Current event: ${_eventName(_latestEvent)}\n'
                'Source: ${_latestEvent?.source.name ?? "none"}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: flagsSet,
              builder: (context, value, child) => FlutterMap(
                options: MapOptions(
                  onMapEvent: (evt) => setState(() => _latestEvent = evt),
                  initialCenter: const LatLng(51.5, -0.09),
                  initialZoom: 11,
                  interactionOptions: InteractionOptions(
                    flags: value,
                    scrollZoomOptions: useSmoothScrollZooming
                        ? const ScrollZoomOptions.smooth()
                        : const ScrollZoomOptions.snapping(),
                    cursorKeyboardRotationOptions:
                        CursorKeyboardRotationOptions(
                      isKeyTrigger: (key) =>
                          keyboardCursorRotate &&
                          CursorKeyboardRotationOptions.defaultTriggerKeys
                              .contains(key),
                    ),
                    keyboardOptions: KeyboardOptions(
                      enableArrowKeysPanning: keyboardArrowsMove,
                      enableWASDPanning: keyboardWASDMove,
                      enableQERotating: keyboardQERotate,
                      enableRFZooming: keyboardRFZoom,
                    ),
                  ),
                ),
                children: [child!],
              ),
              child: openStreetMapTileLayer,
            ),
          ),
        ],
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

class InteractiveFlagCheckbox extends StatelessWidget {
  const InteractiveFlagCheckbox({
    super.key,
    required this.name,
    required this.flag,
    required this.flagsSet,
  });

  final String name;
  final int flag;
  final ValueNotifier<int> flagsSet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: flagsSet,
          builder: (context, value, _) => Checkbox.adaptive(
            value: InteractiveFlag.hasFlag(flag, value),
            onChanged: (enabled) =>
                flagsSet.value = !enabled! ? value &= ~flag : value |= flag,
          ),
        ),
        Text(name),
      ],
    );
  }
}
