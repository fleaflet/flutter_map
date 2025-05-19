import 'dart:async';

typedef TimedFuture<E> = ({
  Future<E> result,
  Future<Duration> duration,
  Future<({E result, Duration duration})> future,
});

extension CreateTimedFuture<E> on Future<E> {
  /// Augments the future with the length of time it took to complete
  ///
  /// Note that the time is started on invocation of this method, not the actual
  /// duration of the future from when it was created.
  TimedFuture<E> timed() {
    final timer = Stopwatch()..start();
    final duration = Completer<Duration>();
    final future = Completer<({E result, Duration duration})>();
    whenComplete(() => duration.complete((timer..stop()).elapsed));
    then(
      (result) => duration.future.then(
        (duration) => future.complete((result: result, duration: duration)),
      ),
      onError: future.completeError,
    );
    return (result: this, duration: duration.future, future: future.future);
  }
}
