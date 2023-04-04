import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';

abstract class TileTransition {
  const TileTransition();

  factory TileTransition.from({
    required double opacity,
    bool? fastReplace,
    TileFadeIn? tileFadeIn,
  }) {
    if ((opacity != 1.0) || fastReplace == true) {
      return InstantaneousTileTransition(opacity: opacity);
    }

    return FadedTileTransition(tileFadeIn ?? const TileFadeIn());
  }

  T map<T>({
    required T Function(InstantaneousTileTransition instantaneous)
        instantaneous,
    required T Function(FadedTileTransition faded) faded,
  }) {
    switch (runtimeType) {
      case InstantaneousTileTransition:
        return instantaneous(this as InstantaneousTileTransition);
      case FadedTileTransition:
        return faded(this as FadedTileTransition);
      default:
        throw 'Unknown TileTransition type: $runtimeType';
    }
  }

  void when({
    void Function(InstantaneousTileTransition instantaneous)? instantaneous,
    void Function(FadedTileTransition faded)? faded,
  }) {
    switch (runtimeType) {
      case InstantaneousTileTransition:
        return instantaneous?.call(this as InstantaneousTileTransition);
      case FadedTileTransition:
        return faded?.call(this as FadedTileTransition);
      default:
        throw 'Unknown TileTransition type: $runtimeType';
    }
  }
}

class InstantaneousTileTransition extends TileTransition {
  final double opacity;

  const InstantaneousTileTransition({
    this.opacity = 1.0,
  }) : assert(opacity >= 0.0 && opacity <= 1.0);
}

class FadedTileTransition extends TileTransition {
  final TileFadeIn tileFadeIn;

  const FadedTileTransition(this.tileFadeIn);

  Duration get duration => tileFadeIn.duration;
}
