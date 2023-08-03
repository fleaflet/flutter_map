import 'dart:async';

import 'package:flutter_map/src/gestures/map_events.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_update_event.dart';
import 'package:flutter_map/src/misc/private/util.dart';
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
  /// Always load/update/prune tiles on events, except where the event is one of:
  ///  - [MapEventTap]
  ///  - [MapEventSecondaryTap]
  ///  - [MapEventLongPress]
  ///
  /// It is assumed (/guaranteed) that these events should not cause the map to
  /// move, and therefore, tile changes are not required.
  ///
  /// Default transformer for [TileLayer].
  static final ignoreTapEvents =
      TileUpdateTransformer.fromHandlers(handleData: (event, sink) {
    if (!_triggeredByTap(event)) sink.add(event);
  });

  /// This feature is deprecated since v5.
  ///
  /// Prefer `ignoreTapEvents` instead. This transformer produces theoretically
  /// unnecessary tile updates which can harm performance. If you notice a
  /// difference in behaviour, please open a bug report on GitHub.
  @Deprecated(
    'Prefer `ignoreTapEvents` instead. '
    'This transformer produces theoretically unnecessary tile updates which can harm performance. '
    'If you notice a difference in behaviour, please open a bug report on GitHub. '
    'This feature is deprecated since v5.',
  )
  static final alwaysLoadAndPrune =
      TileUpdateTransformer.fromHandlers(handleData: (event, sink) {
    sink.add(event);
  });

  /// Throttle loading/updating/pruning tiles such that it only occurs once per
  /// [duration]
  static TileUpdateTransformer throttle(
    Duration duration, {
    /// Whether to filter tap events as [ignoreTapEvents] does
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
