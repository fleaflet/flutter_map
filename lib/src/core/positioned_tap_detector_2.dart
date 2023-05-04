import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

typedef TapPositionCallback = void Function(TapPosition position);

class PositionedTapDetector2 extends StatefulWidget {
  const PositionedTapDetector2({
    Key? key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.doubleTapDelay = _defaultDelay,
    this.behavior,
    this.controller,
  }) : super(key: key);

  static const _defaultDelay = Duration(milliseconds: 250);
  static const _doubleTapMaxOffset = 48.0;

  final Widget? child;
  final HitTestBehavior? behavior;
  final TapPositionCallback? onTap;
  final TapPositionCallback? onSecondaryTap;
  final TapPositionCallback? onDoubleTap;
  final TapPositionCallback? onLongPress;
  final Duration doubleTapDelay;
  final PositionedTapController? controller;

  @override
  State<PositionedTapDetector2> createState() => _TapPositionDetectorState();
}

class _TapPositionDetectorState extends State<PositionedTapDetector2> {
  final _controller = StreamController<TapDownDetails>();

  Stream<TapDownDetails> get _stream => _controller.stream;

  Sink<TapDownDetails> get _sink => _controller.sink;

  PositionedTapController? _tapController;
  TapDownDetails? _pendingTap;
  TapDownDetails? _firstTap;

  @override
  void initState() {
    _updateController();
    _stream
        .timeout(widget.doubleTapDelay)
        .handleError(_onTimeout, test: (e) => e is TimeoutException)
        .listen(_onTapConfirmed);
    super.initState();
  }

  @override
  void didUpdateWidget(PositionedTapDetector2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _updateController();
    }
  }

  void _updateController() {
    _tapController?._state = null;
    if (widget.controller != null) {
      widget.controller!._state = this;
      _tapController = widget.controller;
    }
  }

  void _onTimeout(dynamic error) {
    final firstTap = _firstTap;
    if (firstTap != null && _pendingTap == null) {
      _postCallback(firstTap, widget.onTap);
    }
  }

  void _onTapConfirmed(TapDownDetails details) {
    if (_firstTap == null) {
      _firstTap = details;
    } else {
      _handleSecondTap(details);
    }
  }

  void _handleSecondTap(TapDownDetails secondTap) {
    final firstTap = _firstTap;

    if (firstTap == null) return;

    if (_isDoubleTap(firstTap, secondTap)) {
      _postCallback(secondTap, widget.onDoubleTap);
    } else {
      _postCallback(firstTap, widget.onTap);
      _postCallback(secondTap, widget.onTap);
    }
  }

  bool _isDoubleTap(TapDownDetails d1, TapDownDetails d2) {
    final dx = (d1.globalPosition.dx - d2.globalPosition.dx);
    final dy = (d1.globalPosition.dy - d2.globalPosition.dy);
    return sqrt(dx * dx + dy * dy) <=
        PositionedTapDetector2._doubleTapMaxOffset;
  }

  void _onTapDownEvent(TapDownDetails details) {
    _pendingTap = details;
  }

  void _onTapEvent() {
    final pending = _pendingTap;
    if (pending == null) return;

    if (widget.onDoubleTap == null) {
      _postCallback(pending, widget.onTap);
    } else {
      _sink.add(pending);
    }

    _pendingTap = null;
  }

  void _onSecondaryTapEvent() {
    final pending = _pendingTap;
    if (pending == null) return;

    _postCallback(pending, widget.onSecondaryTap);
    _pendingTap = null;
  }

  void _onLongPressEvent() {
    final pending = _pendingTap;
    if (pending != null) {
      if (_firstTap == null) {
        _postCallback(pending, widget.onLongPress);
      } else {
        _sink.add(pending);
        _pendingTap = null;
      }
    }
  }

  void _postCallback(
    TapDownDetails details,
    TapPositionCallback? callback,
  ) async {
    _firstTap = null;
    if (callback != null) {
      callback(_getTapPositions(details));
    }
  }

  TapPosition _getTapPositions(TapDownDetails details) {
    final topLeft = _getWidgetTopLeft();
    final global = details.globalPosition;
    final relative = topLeft != null ? global - topLeft : null;
    return TapPosition(global, relative);
  }

  Offset? _getWidgetTopLeft() {
    final translation =
        context.findRenderObject()?.getTransformTo(null).getTranslation();
    return translation != null ? Offset(translation.x, translation.y) : null;
  }

  @override
  void dispose() {
    _controller.close();
    _tapController?._state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller != null) {
      if (widget.child != null) {
        return widget.child!;
      } else {
        return Container();
      }
    }
    return GestureDetector(
      behavior: (widget.behavior ??
          (widget.child == null
              ? HitTestBehavior.translucent
              : HitTestBehavior.deferToChild)),
      onTap: _onTapEvent,
      onLongPress: _onLongPressEvent,
      onTapDown: _onTapDownEvent,
      onSecondaryTapDown: _onTapDownEvent,
      onSecondaryTap: _onSecondaryTapEvent,
      child: widget.child,
    );
  }
}

class PositionedTapController {
  _TapPositionDetectorState? _state;

  void onTap() => _state?._onTapEvent();

  void onSecondaryTap() => _state?._onSecondaryTapEvent();

  void onLongPress() => _state?._onLongPressEvent();

  void onTapDown(TapDownDetails details) => _state?._onTapDownEvent(details);
}

class TapPosition {
  TapPosition(this.global, this.relative);

  Offset global;
  Offset? relative;

  @override
  bool operator ==(dynamic other) {
    if (other is! TapPosition) return false;
    final TapPosition typedOther = other;
    return global == typedOther.global && relative == other.relative;
  }

  @override
  int get hashCode => Object.hash(global, relative);
}
