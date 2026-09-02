import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// A completer the test drives frame by frame — progressive tiles (a base
/// frame followed by a composed one) emit more than once, and handle-ownership
/// tests need to control exactly when each frame lands.
class DrivenCompleter extends ImageStreamCompleter {
  /// Delivers [info] to every listener as the next frame.
  void emit(ImageInfo info) => setImage(info);
}

/// An [ImageProvider] whose key is itself, so every [TileImage] resolving it
/// shares ONE completer — exactly what [ImageCache] does for equal keys.
class DrivenProvider extends ImageProvider<DrivenProvider> {
  /// Creates a provider that exposes [completer] to all resolvers.
  DrivenProvider(this.completer);

  /// The completer shared by every resolve of this provider.
  final ImageStreamCompleter completer;

  @override
  Future<DrivenProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<DrivenProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    DrivenProvider key,
    ImageDecoderCallback decode,
  ) =>
      completer;
}

/// One factory for the handle-ownership tests — the [TileImage] constructor
/// takes eight arguments and duplicating the boilerplate per test file meant a
/// constructor change touched every copy.
TileImage testTileImage({
  required ImageProvider provider,
  int x = 0,
  void Function(TileCoordinates)? onLoadComplete,
}) =>
    TileImage(
      vsync: const TestVSync(),
      coordinates: TileCoordinates(x, 0, 0),
      imageProvider: provider,
      onLoadComplete: onLoadComplete ?? (_) {},
      onLoadError: (_, __, ___) {},
      tileDisplay: const TileDisplay.instantaneous(),
      errorImage: null,
      cancelLoading: Completer<void>(),
    );
