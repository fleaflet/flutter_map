import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Asynchronously read the existing size monitor if available,
/// returning `null` if unavailable
@internal
Future<int?> asyncGetOnlySizeMonitor(String sizeMonitorFilePath) async {
  final sizeMonitorFile = File(sizeMonitorFilePath);
  if (!await sizeMonitorFile.exists()) return null;
  final bytes = await sizeMonitorFile.readAsBytes();
  if (bytes.length == 8) return bytes.buffer.asInt64List()[0];
  return null;
}

/// Opens and reads the existing size monitor if available
///
/// If one does not exist, it calculates the current cache size and writes it
/// to a new size monitor.
///
/// The returned [RandomAccessFile] is open - closure is the responsibility of
/// the caller.
@internal
Future<({int currentSize, RandomAccessFile sizeMonitor})>
    getOrCreateSizeMonitor({
  required String cacheDirectoryPath,
  required String sizeMonitorFilePath,
}) async {
  final sizeMonitorFile = File(sizeMonitorFilePath);

  final sizeMonitor = sizeMonitorFile.openSync(mode: FileMode.append)
    ..setPositionSync(0);
  final bytes = sizeMonitor.readSync(8);

  if (bytes.length == 8) {
    return (
      currentSize: bytes.buffer.asInt64List()[0],
      sizeMonitor: sizeMonitor,
    );
  }

  final calculatedCurrentSize = await Directory(cacheDirectoryPath)
      .listSync()
      .whereType<File>()
      .where(
        (f) {
          final uuid = p.basename(f.absolute.path);
          return uuid != BuiltInMapCachingProviderImpl.sizeMonitorFileName;
        },
      )
      .map((f) => f.length())
      .asyncFold(0, (v, l) => v + l);

  sizeMonitor
    ..setPositionSync(0)
    ..writeFromSync(
      Uint8List(8)..buffer.asInt64List()[0] = calculatedCurrentSize,
    )
    ..flushSync();

  return (currentSize: calculatedCurrentSize, sizeMonitor: sizeMonitor);
}

extension _AsyncFold<E> on Iterable<Future<E>> {
  /// Reduces a collection of [Future]s to a single value by iteratively
  /// combining each element of the collection when it completes with an
  /// existing value
  ///
  /// The result must not depend on the order of completetion and [combine]
  /// calls.
  Future<T> asyncFold<T>(
    T initialValue,
    T Function(T previousValue, E element) combine,
  ) async {
    var value = initialValue;

    bool hasFinishedIterating = false;
    int waiting = 0;
    final completer = Completer<void>();

    for (final element in this) {
      waiting++;
      unawaited(
        element.then((result) {
          value = combine(value, result);
          waiting--;
          if (hasFinishedIterating && waiting == 0) completer.complete();
        }),
      );
    }

    if (waiting == 0) return value;

    hasFinishedIterating = true;
    await completer.future;
    return value;
  }
}
