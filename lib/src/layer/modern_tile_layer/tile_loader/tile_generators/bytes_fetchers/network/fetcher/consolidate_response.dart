// Adapted from Flutter (c 2014 BSD The Flutter Authors) method to work without
// `dart:io` using a `StreamedResponse`

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

/// Efficiently converts the response body of an [Response] into a
/// [Uint8List].
///
/// Assumes response has been uncompressed automatically.
///
/// See [consolidateHttpClientResponseBytes] for more info.
@internal
Future<Uint8List> consolidateStreamedResponseBytes(
  StreamedResponse response, {
  BytesReceivedCallback? onBytesReceived,
}) {
  final completer = Completer<Uint8List>.sync();
  final output = _OutputBuffer();

  int? expectedContentLength = response.contentLength;
  if (expectedContentLength == -1) expectedContentLength = null;

  int bytesReceived = 0;
  late final StreamSubscription<List<int>> subscription;
  subscription = response.stream.listen(
    (chunk) {
      output.add(chunk);
      if (onBytesReceived != null) {
        bytesReceived += chunk.length;
        try {
          onBytesReceived(bytesReceived, expectedContentLength);
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
          subscription.cancel();
          return;
        }
      }
    },
    onDone: () {
      output.close();
      completer.complete(output.bytes);
    },
    onError: completer.completeError,
    cancelOnError: true,
  );

  return completer.future;
}

class _OutputBuffer extends ByteConversionSinkBase {
  List<List<int>>? _chunks = <List<int>>[];
  int _contentLength = 0;
  Uint8List? _bytes;

  @override
  void add(List<int> chunk) {
    assert(_bytes == null, '`_bytes` must be `null`');
    _chunks!.add(chunk);
    _contentLength += chunk.length;
  }

  @override
  void close() {
    if (_bytes != null) {
      // We've already been closed; this is a no-op
      return;
    }
    _bytes = Uint8List(_contentLength);
    int offset = 0;
    for (final List<int> chunk in _chunks!) {
      _bytes!.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _chunks = null;
  }

  Uint8List get bytes => _bytes!;
}
