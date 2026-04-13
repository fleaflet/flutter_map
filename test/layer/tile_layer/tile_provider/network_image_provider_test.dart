import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/image_provider/image_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_utils/test_tile_image.dart';

class MockHttpClient extends Mock implements Client {}

// Helper function to resolve the ImageInfo from the ImageProvider.
Future<ImageInfo> getImageInfo(ImageProvider provider) {
  final completer = Completer<ImageInfo>();

  provider.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener(
          (imageInfo, _) => completer.complete(imageInfo),
          onError: completer.completeError,
        ),
      );

  return completer.future;
}

/// Returns a random URL to use for testing. Due to Flutter caching images
/// we need to use a different URL each time.
int _urlId = 0;

Uri randomUrl({bool fallback = false}) {
  _urlId++;
  if (fallback) {
    return Uri.parse('https://example.net/fallback/$_urlId.png');
  } else {
    return Uri.parse('https://example.com/main/$_urlId.png');
  }
}

// TODO: Write tests to test aborting?
// TODO: Write tests to test built-in caching

void main() {
  const headers = {
    'user-agent': 'flutter_map',
    'x-whatever': '123',
  };

  const defaultTimeout = Timeout(Duration(seconds: 1));

  final mockClient = MockHttpClient();

  NetworkTileImageProvider createDefaultImageProvider(
    Uri url, {
    Uri? fallbackUrl,
    bool silenceExceptions = false,
  }) =>
      NetworkTileImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl?.toString(),
        headers: headers,
        httpClient: mockClient,
        abortTrigger: null,
        silenceExceptions: silenceExceptions,
        attemptDecodeOfHttpErrorResponses: true,
        cachingProvider: const DisabledMapCachingProvider(),
      );

  setUpAll(() {
    // Ensure the Mock library has example values for Uri.
    registerFallbackValue(Uri());
    registerFallbackValue(Request('GET', Uri()));
  });

  // We expect a request to be made to the correct URL with the appropriate headers.
  testWidgets(
    'Valid/expected response',
    (tester) async {
      when(() => mockClient.send(any())).thenAnswer(
        (_) async => StreamedResponse(Stream.value(testWhiteTileBytes), 200),
      );

      final url = randomUrl();
      final provider = createDefaultImageProvider(url);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(img!.image.width, equals(256));
      expect(img.image.height, equals(256));
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  // We expect the request to be made, and a HTTP ClientException to be bubbled
  // up to the caller.
  testWidgets(
    'ClientException - no fallback, exceptions enabled',
    (tester) async {
      when(() => mockClient.send(any()))
          .thenAnswer((_) async => throw ClientException('Server error'));

      final url = randomUrl();
      final provider = createDefaultImageProvider(url);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNull);
      expect(tester.takeException(), isInstanceOf<ClientException>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'ClientException - no fallback, exceptions silenced',
    (tester) async {
      when(() => mockClient.send(any()))
          .thenAnswer((_) async => throw ClientException('Server error'));

      final url = randomUrl();
      final provider = createDefaultImageProvider(url, silenceExceptions: true);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  // We expect the regular URL to be called once, then the fallback URL.
  testWidgets(
    'ClientException - successful fallback',
    (tester) async {
      final url = randomUrl();
      when(
        () => mockClient.send(
            any(that: isA<BaseRequest>().having((r) => r.url, 'URL', url))),
      ).thenAnswer((_) async => throw ClientException('Server error'));

      final fallbackUrl = randomUrl(fallback: true);
      when(
        () => mockClient.send(any(
            that: isA<BaseRequest>().having((r) => r.url, 'URL', fallbackUrl))),
      ).thenAnswer(
        (_) async => StreamedResponse(Stream.value(testWhiteTileBytes), 200),
      );

      final provider =
          createDefaultImageProvider(url, fallbackUrl: fallbackUrl);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(img!.image.width, equals(256));
      expect(img.image.height, equals(256));
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'ClientException - failed fallback, exceptions enabled',
    (tester) async {
      when(() => mockClient.send(any()))
          .thenAnswer((_) async => throw ClientException('Server error'));

      final url = randomUrl();
      final fallbackUrl = randomUrl(fallback: true);
      final provider =
          createDefaultImageProvider(url, fallbackUrl: fallbackUrl);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNull);
      expect(tester.takeException(), isInstanceOf<ClientException>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'ClientException - failed fallback, exceptions silenced',
    (tester) async {
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => throw ClientException('Server error'));

      final url = randomUrl();
      final fallbackUrl = randomUrl(fallback: true);
      final provider = createDefaultImageProvider(
        url,
        fallbackUrl: fallbackUrl,
        silenceExceptions: true,
      );

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'HTTP errstatus - no fallback, exceptions enabled',
    (tester) async {
      when(() => mockClient.send(any()))
          .thenAnswer((_) async => StreamedResponse(const Stream.empty(), 400));

      final url = randomUrl();
      final provider = createDefaultImageProvider(url);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNull);
      expect(tester.takeException(), isInstanceOf<NetworkImageLoadException>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );
  testWidgets(
    'HTTP errstatus - no fallback, exceptions silenced',
    (tester) async {
      when(() => mockClient.send(any()))
          .thenAnswer((_) async => StreamedResponse(const Stream.empty(), 400));

      final url = randomUrl();
      final provider = createDefaultImageProvider(url, silenceExceptions: true);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'HTTP errstatus - successful fallback',
    (tester) async {
      final url = randomUrl();
      when(
        () => mockClient.send(
            any(that: isA<BaseRequest>().having((r) => r.url, 'URL', url))),
      ).thenAnswer((_) async => StreamedResponse(const Stream.empty(), 400));

      final fallbackUrl = randomUrl(fallback: true);
      when(
        () => mockClient.send(any(
            that: isA<BaseRequest>().having((r) => r.url, 'URL', fallbackUrl))),
      ).thenAnswer(
        (_) async => StreamedResponse(Stream.value(testWhiteTileBytes), 200),
      );

      final provider =
          createDefaultImageProvider(url, fallbackUrl: fallbackUrl);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(img!.image.width, equals(256));
      expect(img.image.height, equals(256));
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'HTTP errstatus - failed fallback, exceptions enabled',
    (tester) async {
      when(() => mockClient.send(any()))
          .thenAnswer((_) async => StreamedResponse(const Stream.empty(), 400));

      final url = randomUrl();
      final fallbackUrl = randomUrl(fallback: true);
      final provider =
          createDefaultImageProvider(url, fallbackUrl: fallbackUrl);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNull);
      expect(tester.takeException(), isInstanceOf<NetworkImageLoadException>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'HTTP errstatus - failed fallback, exceptions silenced',
    (tester) async {
      when(() => mockClient.send(any()))
          .thenAnswer((_) async => StreamedResponse(const Stream.empty(), 400));

      final url = randomUrl();
      final fallbackUrl = randomUrl(fallback: true);
      final provider = createDefaultImageProvider(
        url,
        fallbackUrl: fallbackUrl,
        silenceExceptions: true,
      );

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'HTTP errstatus with image - optimistic decode enabled',
    (tester) async {
      when(() => mockClient.send(any())).thenAnswer(
        (_) async => StreamedResponse(
          Stream.value(testWhiteTileBytes),
          400,
        ),
      );

      final url = randomUrl();
      final provider = createDefaultImageProvider(url);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(img!.image.width, equals(256));
      expect(img.image.height, equals(256));
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'HTTP errstatus with image - optimistic decode disabled',
    (tester) async {
      when(() => mockClient.send(any())).thenAnswer(
        (_) async => StreamedResponse(
          Stream.value(testWhiteTileBytes),
          400,
        ),
      );

      final url = randomUrl();
      final provider = NetworkTileImageProvider(
        url: url.toString(),
        fallbackUrl: null,
        headers: headers,
        httpClient: mockClient,
        abortTrigger: null,
        silenceExceptions: false,
        attemptDecodeOfHttpErrorResponses: false,
        cachingProvider: const DisabledMapCachingProvider(),
      );

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNull);
      expect(tester.takeException(), isInstanceOf<NetworkImageLoadException>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'Non-image response - no fallback, exceptions enabled',
    (tester) async {
      when(() => mockClient.send(any())).thenAnswer(
        (_) async => StreamedResponse(
          Stream.value(
              Uint8List.fromList(utf8.encode('<html>Server Error</html>'))),
          200,
        ),
      );

      final url = randomUrl();
      final provider = createDefaultImageProvider(url);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNull);
      final exception = tester.takeException();
      expect(exception, isInstanceOf<Exception>());
      expect(
        (exception as Exception).toString(),
        equals('Exception: Invalid image data'),
      );

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Non-image response - no fallback, exceptions silenced',
    (tester) async {
      when(() => mockClient.send(any())).thenAnswer(
        (_) async => StreamedResponse(
          Stream.value(
              Uint8List.fromList(utf8.encode('<html>Server Error</html>'))),
          200,
        ),
      );

      final url = randomUrl();
      final provider = createDefaultImageProvider(
        url,
        silenceExceptions: true,
      );

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Non-image response - successful fallback',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.send(
              any(that: isA<BaseRequest>().having((r) => r.url, 'URL', url))))
          .thenAnswer(
        (_) async => StreamedResponse(
          Stream.value(
              Uint8List.fromList(utf8.encode('<html>Server Error</html>'))),
          200,
        ),
      );

      final fallbackUrl = randomUrl(fallback: true);
      when(
        () => mockClient.send(any(
            that: isA<BaseRequest>().having((r) => r.url, 'URL', fallbackUrl))),
      ).thenAnswer(
        (_) async => StreamedResponse(Stream.value(testWhiteTileBytes), 200),
      );

      final provider = createDefaultImageProvider(
        url,
        fallbackUrl: fallbackUrl,
      );

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(img!.image.width, equals(256));
      expect(img.image.height, equals(256));
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Non-image response - failed fallback, exceptions enabled',
    (tester) async {
      final url = randomUrl();
      final fallbackUrl = randomUrl(fallback: true);
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        // 200 OK with html
        return Uint8List.fromList(utf8.encode('<html>Server Error</html>'));
      });

      final provider =
          createDefaultImageProvider(url, fallbackUrl: fallbackUrl);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNull);
      final exception = tester.takeException();
      expect(exception, isInstanceOf<Exception>());
      expect(
        (exception as Exception).toString(),
        equals('Exception: Invalid image data'),
      );

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Non-image response - failed fallback, exceptions silenced',
    (tester) async {
      final url = randomUrl();
      final fallbackUrl = randomUrl(fallback: true);
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        // 200 OK with html
        return Uint8List.fromList(utf8.encode('<html>Server Error</html>'));
      });

      final provider = createDefaultImageProvider(
        url,
        fallbackUrl: fallbackUrl,
        silenceExceptions: true,
      );

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<void>());

      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', url)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
      verify(
        () => mockClient.send(
          captureAny(
            that: isA<BaseRequest>()
                .having((r) => r.url, 'URL', fallbackUrl)
                .having((r) => r.method, 'method', 'GET')
                .having((r) => r.headers, 'headers', equals(headers)),
          ),
        ),
      ).called(1);
    },
    timeout: defaultTimeout,
  );

  tearDownAll(mockClient.close);
}
