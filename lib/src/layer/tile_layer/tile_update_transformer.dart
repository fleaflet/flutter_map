import 'dart:async';

import 'package:flutter_map/src/core/util.dart';
import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_update_event.dart';

typedef TileUpdateTransformer
    = StreamTransformer<TileUpdateEvent, TileUpdateEvent>;

class TileUpdateTransformers {
  const TileUpdateTransformers._();

  /// Avoid loading/updating tiles when a tap occurs on the assumption that it
  /// should not cause new tiles to be loaded.
  static final ignoreTapEvents =
      TileUpdateTransformer.fromHandlers(handleData: (event, sink) {
    if (!_triggeredByTap(event)) sink.add(event);
  });

  /// Always load and update tiles for every map event.
  static final alwaysLoadAndPrune =
      TileUpdateTransformer.fromHandlers(handleData: (event, sink) {
    sink.add(event);
  });

  /// Throttle updates such that maximum one per [duration] is emitted.
  static TileUpdateTransformer throttle(
    Duration duration, {
    /// If true tap events will be filtered out.
    bool ignoreTapEvents = true,
  }) =>
      throttleStreamTransformerWithTrailingCall<TileUpdateEvent>(
        duration,
        ignore: ignoreTapEvents ? _triggeredByTap : null,
      );

  static bool _triggeredByTap(TileUpdateEvent event) =>
      event.mapEvent is MapEventTap ||
      event.mapEvent is MapEventSecondaryTap ||
      event.mapEvent is MapEventLongPress;
}
