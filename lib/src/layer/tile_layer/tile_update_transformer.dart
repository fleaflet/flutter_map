import 'dart:async';

import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_update_event.dart';
import 'package:meta/meta.dart';

/// Defines which [TileUpdateEvent]s should cause which [TileUpdateEvent]s and
/// when
///
/// [TileUpdateTransformers] defines a default set of transformers.
///
/// If needed, build your own using [StreamTransformer.fromHandlers], adding
/// [TileUpdateEvent]s to the exposed [EventSink] if the event should cause an
/// update.
typedef TileUpdateTransformer
    = StreamTransformer<TileUpdateEvent, TileUpdateEvent>;

/// Set of default [TileUpdateTransformer]s
@immutable
abstract class TileUpdateTransformers {
  /// Always* load/update/prune tiles on events
  ///
  /// {@template tut-ignore_tap}
  /// Ignores events where it is one of:
  ///  - [MapEventTap]
  ///  - [MapEventSecondaryTap]
  ///  - [MapEventLongPress]
  ///
  /// It is assumed (/guaranteed) that these events should not cause the map to
  /// move, and therefore, tile changes are not required.
  /// {@endtemplate}
  ///
  /// Default transformer for [TileLayer].
  static final ignoreTapEvents =
      TileUpdateTransformer.fromHandlers(handleData: (event, sink) {
    if (!wasTriggeredByTap(event)) sink.add(event);
  });

  /// Throttle loading/updating/pruning tiles such that it only occurs once per
  /// [duration]
  ///
  /// {@macro tut-ignore_tap}
  static TileUpdateTransformer throttle(Duration duration) {
    Timer? timer;
    TileUpdateEvent recentEvent;
    var trailingCall = false;

    void throttleHandler(
      TileUpdateEvent event,
      EventSink<TileUpdateEvent> sink,
    ) {
      if (wasTriggeredByTap(event)) return;

      recentEvent = event;

      if (timer == null) {
        sink.add(recentEvent);
        timer = Timer(duration, () {
          timer = null;

          if (trailingCall) {
            trailingCall = false;
            throttleHandler(recentEvent, sink);
          }
        });
      } else {
        trailingCall = true;
      }
    }

    return StreamTransformer.fromHandlers(
      handleData: throttleHandler,
      handleDone: (sink) {
        timer?.cancel();
        sink.close();
      },
    );
  }

  @internal
  static bool wasTriggeredByTap(TileUpdateEvent event) =>
      event.mapEvent is MapEventTap ||
      event.mapEvent is MapEventSecondaryTap ||
      event.mapEvent is MapEventLongPress;
}
