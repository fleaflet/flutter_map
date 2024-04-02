import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// Restricts and limits [TileUpdateEvent]s (which are emitted 'by' [MapEvent]s),
/// which cause the tiles of the [TileLayer] to update (see below).
///
/// When a [MapEvent] occurs, a [TileUpdateEvent] is also emitted (containing
/// that event) by the internals. However, it is sometimes unnecessary for all
/// [MapEvent]s to result in a [TileUpdateEvent], which can be expensive and
/// time-consuming. Alternatively, some [TileUpdateEvent]s may be grouped
/// together to reduce the rate at which tiles are updates.
///
/// By default, [TileUpdateEvent]s both prune old tiles and load new tiles, as
/// necessary. However, this may not also be required.
///
/// A [TileUpdateTransformer] transforms/converts the incoming stream of
/// [TileUpdateEvent]s (one per every [MapEvent]) into a 'new' stream of
/// [TileUpdateEvent]s, at any rate, with any desired pruning/loading
/// configuration.
///
/// [TileUpdateTransformers] defines a built-in set of transformers. [TileLayer]
/// uses [TileUpdateTransformers.ignoreTapEvents] by default.
///
/// If neccessary, you can build your own using [StreamTransformer], usually
/// [StreamTransformer.fromHandlers], adding events to the exposed [EventSink]
/// if the incoming event should cause an update. Most implementations should
/// check [TileUpdateEvent.wasTriggeredByTap] before emitting an event, and
/// avoid emitting an event if this is `true`.
typedef TileUpdateTransformer
    = StreamTransformer<TileUpdateEvent, TileUpdateEvent>;

/// Contains a set of built-in [TileUpdateTransformer]s
///
/// See [TileUpdateTransformer] for more information.
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
  /// These events alone will not cause the camera to change position, and
  /// therefore tile updates are necessary.
  /// {@endtemplate}
  ///
  /// Default transformer for [TileLayer].
  static final ignoreTapEvents =
      TileUpdateTransformer.fromHandlers(handleData: (event, sink) {
    if (!event.wasTriggeredByTap()) sink.add(event);
  });

  /// Throttle loading/updating/pruning tiles such that it only occurs once per
  /// [duration]
  ///
  /// Also see [debounce].
  ///
  /// ---
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
      if (event.wasTriggeredByTap()) return;

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

  /// Suppresses tile updates with less inter-event spacing than [duration]
  ///
  /// This may improve performance, and reduce the number of tile requests, but
  /// at the expense of UX: new tiles will not be loaded until [duration] after
  /// the final tile load event in a series. For example, a fling gesture will
  /// not load new tiles during its animation, only at the end. Best used in
  /// combination with the cancellable tile provider, for even more fine-tuned
  /// optimization.
  ///
  /// Implementation follows that in
  /// ['package:stream_transform'](https://pub.dev/documentation/stream_transform/latest/stream_transform/RateLimit/debounce.html).
  ///
  /// Also see [throttle].
  ///
  /// ---
  ///
  /// {@macro tut-ignore_tap}
  static TileUpdateTransformer debounce(Duration duration) {
    Timer? timer;
    TileUpdateEvent? soFar;
    var hasPending = false;
    var shouldClose = false;

    return StreamTransformer.fromHandlers(
      handleData: (event, sink) {
        if (event.wasTriggeredByTap()) return;

        void emit() {
          sink.add(soFar!);
          soFar = null;
          hasPending = false;
        }

        timer?.cancel();
        soFar = event;
        hasPending = true;

        timer = Timer(duration, () {
          emit();
          if (shouldClose) sink.close();
          timer = null;
        });
      },
      handleDone: (sink) {
        if (hasPending) {
          shouldClose = true;
        } else {
          timer?.cancel();
          sink.close();
        }
      },
    );
  }
}
