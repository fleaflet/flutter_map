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

    if (!canReuseProjectionCache(oldWidget)) {
      cachedProjected = null;
      cachedSimplified.clear();
    } else if (!canReuseSimplificationCache(oldWidget)) {
      cachedSimplified.clear();
    }
  }

  /// Whether the currently cached projections can be reused
  ///
  /// Ignore device pixel ratio changes, this is handled automatically
  /// internally.
  ///
  /// If this is `false`, [canReuseSimplificationCache] will be treated as
  /// `false` without execution.
  bool canReuseProjectionCache(W oldWidget);

  /// Whether the currently cached simplifications can be reused
  ///
  /// Ignore device pixel ratio changes, this is handled automatically
  /// internally.
  bool canReuseSimplificationCache(W oldWidget);
}
