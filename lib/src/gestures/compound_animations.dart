part of 'map_interactive_viewer.dart';

mixin _InfiniteNotifier<T> on CompoundAnimation<T> {
  @override
  void didStartListening() {
    first.addListener(notifyListeners);
    first.addStatusListener(_maybeNotifyStatusListeners);
    next.addListener(notifyListeners);
    next.addStatusListener(_maybeNotifyStatusListeners);
  }

  @override
  void didStopListening() {
    first.removeListener(notifyListeners);
    first.removeStatusListener(_maybeNotifyStatusListeners);
    next.removeListener(notifyListeners);
    next.removeStatusListener(_maybeNotifyStatusListeners);
  }

  AnimationStatus? _lastStatus;
  void _maybeNotifyStatusListeners(AnimationStatus _) {
    if (status != _lastStatus) {
      _lastStatus = status;
      notifyStatusListeners(status);
    }
  }
}

class _NumInfiniteSumAnimation<T extends num> extends CompoundAnimation<T>
    with _InfiniteNotifier {
  _NumInfiniteSumAnimation(Animation<T> a, Animation<T> b)
      : super(first: a, next: b);

  @override
  T get value => first.value + next.value as T;
}

class _OffsetInfiniteSumAnimation extends CompoundAnimation<Offset>
    with _InfiniteNotifier {
  _OffsetInfiniteSumAnimation(Animation<Offset> a, Animation<Offset> b)
      : super(first: a, next: b);

  @override
  Offset get value => first.value + next.value;
}

class _InfiniteAnimation<T> extends CompoundAnimation<T>
    with _InfiniteNotifier {
  _InfiniteAnimation(Animation<T> repeat, Animation<T> curve)
      : super(first: repeat, next: curve);

  @override
  AnimationStatus get status => switch (next.status) {
        AnimationStatus.completed => AnimationStatus.forward,
        AnimationStatus.forward => AnimationStatus.forward,
        AnimationStatus.dismissed => AnimationStatus.dismissed,
        AnimationStatus.reverse => AnimationStatus.reverse,
      };

  @override
  T get value => !next.isCompleted ? next.value : first.value;
}
