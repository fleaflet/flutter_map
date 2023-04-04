import 'dart:async';

import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_update_event.dart';

typedef TileUpdateTransformer = StreamTransformer<MapEvent, TileUpdateEvent>;

/// Avoid loading/updating tiles when a tap occurs on the assumption that it
/// should not cause new tiles to be loaded.
final ignoreTapEventsTransformer =
    TileUpdateTransformer.fromHandlers(handleData: (event, sink) {
  // Ignore known events that we know should not cause new tiles to load.
  if (event is MapEventTap ||
      event is MapEventSecondaryTap ||
      event is MapEventLongPress) {
    return;
  }

  // Let the event trigger load/prune.
  sink.add(const TileUpdateEvent.loadAndPrune());
});
