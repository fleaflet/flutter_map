import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// Projecton & Simplification Caching State
///
/// [P] is a Projected feature.
@internal
mixin PSCachingLayerState<P extends Object, W extends StatefulWidget>
    on State<W> {
  /// Default/last [PlatformDispatcher.onMetricsChanged] callback
  ///
  /// Monitoring the current device pixel ratio is necessary, as a change in this
  /// will invalidate the cache
  ///
  /// Will be called inside overriden callback, and restored during [dispose].
  void Function()? _onMetricsChangedDefault;
  double? _devicePixelRatio;

  List<P>? cachedProjected;
  final cachedSimplified = <int, List<P>>{};

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    _onMetricsChangedDefault = PlatformDispatcher.instance.onMetricsChanged;
    PlatformDispatcher.instance.onMetricsChanged = () {
      _onMetricsChangedDefault?.call();

      final newDPR = MediaQuery.devicePixelRatioOf(context);
      if (_devicePixelRatio != newDPR) {
        _devicePixelRatio = newDPR;
        cachedSimplified.clear();
      }
    };
  }

  @override
  @mustCallSuper
  void dispose() {
    PlatformDispatcher.instance.onMetricsChanged = _onMetricsChangedDefault;
    super.dispose();
  }

  @override
  @mustCallSuper
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (canReuseCache(oldWidget)) return;
    cachedSimplified.clear();
    cachedProjected = null;
  }

  /// Whether the currently cached projections and simplifications can be reused
  bool canReuseCache(W oldWidget);
}
