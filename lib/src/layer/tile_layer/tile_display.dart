import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Defines how the tile should get displayed on the map.
@immutable
sealed class TileDisplay {
  const TileDisplay();

  /// Instantly display tiles once they are loaded without a fade animation.
  /// Sets the opacity of tile images to the given value (0.0 - 1.0), default
  /// 1.0. Note that this opacity setting is applied at the tile level which
  /// means that overlapping tiles will be simultaneously visible. This can
  /// happen when changing zoom as tiles from the previous zoom level will
  /// not be cleared until all of the tiles at the new zoom level have
  /// finished loading. For this reason this opacity setting is only
  /// recommended when the displayed map will remain at the same zoom level
  /// or will not move gradually between zoom levels at the same position.
  ///
  /// If you wish to show a transparent map without these restrictions you
  /// can simply wrap the entire [TileLayer] in an [Opacity] widget.
  const factory TileDisplay.instantaneous({
    double opacity,
  }) = InstantaneousTileDisplay._;

  /// Fade in the tile when it is loaded. Not that opacity is not supported
  /// when fading is enabled. This is because underlying tiles are kept when
  /// fading in a new tile until it is loaded and with a partially transparent
  /// tile they are both visible during fading which causes flickering.
  ///
  /// If you wish to make the TileLayer transparent you must disable fading
  /// (see the TileDisplay.instantaneous opacity option) or wrap the whole
  /// TileLayer in an Opacity widget.
  const factory TileDisplay.fadeIn({
    /// Duration of the fade. Defaults to 100ms.
    Duration duration,

    /// Opacity start value when a tile is faded in, default 1.0. The allowed
    /// range is (0.0 - 1.0).
    double startOpacity,

    /// Opacity start value when a tile is reloaded, default 1.0. Valid range is
    /// (0.0 - 1.0).
    double reloadStartOpacity,
  }) = FadeInTileDisplay._;

  /// Output a value of type [T] dependent on this and its type
  T? when<T>({
    T? Function(InstantaneousTileDisplay instantaneous)? instantaneous,
    T? Function(FadeInTileDisplay fadeIn)? fadeIn,
  }) {
    final display = this;
    return switch (display) {
      InstantaneousTileDisplay() => instantaneous?.call(display),
      FadeInTileDisplay() => fadeIn?.call(display),
    };
  }
}

/// Display the tile instantaneous.
@immutable
class InstantaneousTileDisplay extends TileDisplay {
  /// The optional opacity of the tile.
  ///
  /// Defaults to 1.0
  final double opacity;

  const InstantaneousTileDisplay._({this.opacity = 1.0})
      : assert(
          opacity >= 0.0 && opacity <= 1.0,
          'The opacity value needs to be between 0 and 1',
        );

  /// Note this is used to check if the option has changed.
  @override
  bool operator ==(Object other) {
    return other is InstantaneousTileDisplay && opacity == other.opacity;
  }

  @override
  int get hashCode => opacity.hashCode;
}

/// A [TileDisplay] that should get faded in.
@immutable
class FadeInTileDisplay extends TileDisplay {
  /// The duration of the fade in animation.
  final Duration duration;

  /// The opacity of what the tile should start loading in.
  final double startOpacity;

  /// The opacity of what the tile should start loading in when a
  /// reload occurred.
  final double reloadStartOpacity;

  /// Options for fading in tiles when they are loaded.
  const FadeInTileDisplay._({
    this.duration = const Duration(milliseconds: 100),
    this.startOpacity = 0.0,
    this.reloadStartOpacity = 0.0,
  })  : assert(
          startOpacity >= 0.0 && startOpacity <= 1.0,
          'startOpacity needs to be between 0 and 1',
        ),
        assert(reloadStartOpacity >= 0.0 && reloadStartOpacity <= 1.0,
            'reloadStartOpacity needs to be between 0 and 1');

  // Note this is used to check if the option has changed.
  @override
  bool operator ==(Object other) {
    return other is FadeInTileDisplay &&
        duration == other.duration &&
        startOpacity == other.startOpacity &&
        reloadStartOpacity == other.reloadStartOpacity;
  }

  @override
  int get hashCode => Object.hash(duration, startOpacity, reloadStartOpacity);
}
