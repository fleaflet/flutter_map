import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/image_provider/image_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';

import '../../../test_utils/test_tile_image.dart';

/// Answers after 100 ms, or fails 20 ms after the request's abort trigger.
class _SlowClient extends BaseClient {
  int requests = 0;
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    requests++;
    final result = Completer<StreamedResponse>();
    Timer(const Duration(milliseconds: 100), () {
      if (!result.isCompleted) {
        result
            .complete(StreamedResponse(Stream.value(testWhiteTileBytes), 200));
      }
    });
    if (request is Abortable) {
      request.abortTrigger
          ?.then((_) => Timer(const Duration(milliseconds: 20), () {
                if (!result.isCompleted) {
                  result.completeError(RequestAbortedException(request.url));
                }
              }));
    }
    return result.future;
  }
}

void main() {
  testWidgets(
      'a tile requested again while an aborted request ends gets the image',
      (tester) async {
    final client = _SlowClient();
    NetworkTileImageProvider provider(Future<void> abortTrigger) =>
        NetworkTileImageProvider(
          url: 'https://example.com/1/2/3.png',
          fallbackUrl: null,
          headers: const {},
          httpClient: client,
          abortTrigger: abortTrigger,
          silenceExceptions: false,
          attemptDecodeOfHttpErrorResponses: true,
          cachingProvider: const DisabledMapCachingProvider(),
        );
    await tester.runAsync(() async {
      final cancelA = Completer<void>();
      provider(cancelA.future).resolve(ImageConfiguration.empty);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cancelA.complete();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final image = Completer<ImageInfo>();
      provider(Completer<void>().future)
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener((info, _) => image.complete(info),
              onError: image.completeError));
      final info = await image.future.timeout(const Duration(seconds: 2));
      expect(client.requests, 2);
      expect(info.image.width, 256);
    });
  });
}
