import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_image_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_utils/test_tile_image.dart';

class MockHttpClient extends Mock implements BaseClient {}

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

void main() {
  const headers = {
    'user-agent': 'flutter_map',
    'x-whatever': '123',
  };

  const defaultTimeout = Timeout(Duration(seconds: 1));

  final mockClient = MockHttpClient();

  setUpAll(() {
    // Ensure the Mock library has example values for Uri.
    registerFallbackValue(Uri());
  });

  // We expect a request to be made to the correct URL with the appropriate headers.
  testWidgets(
    'Valid/expected response',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => testWhiteTileBytes);

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: null,
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: false,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(img!.image.width, equals(256));
      expect(img.image.height, equals(256));
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
    },
    timeout: defaultTimeout,
  );

  // We expect the request to be made, and a HTTP ClientException to be bubbled
  // up to the caller.
  testWidgets(
    'Server failure - no fallback, exceptions enabled',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => throw ClientException('Server error'));

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: null,
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: false,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNull);
      expect(tester.takeException(), isInstanceOf<ClientException>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Server failure - no fallback, exceptions silenced',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => throw ClientException('Server error'));

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: null,
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: true,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
    },
    timeout: defaultTimeout,
  );

  // We expect the regular URL to be called once, then the fallback URL.
  testWidgets(
    'Server failure - successful fallback, exceptions enabled',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(url, headers: any(named: 'headers')))
          .thenAnswer((_) async => throw ClientException('Server error'));

      final fallbackUrl = randomUrl(fallback: true);
      when(() =>
              mockClient.readBytes(fallbackUrl, headers: any(named: 'headers')))
          .thenAnswer((_) async {
        return testWhiteTileBytes;
      });

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl.toString(),
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: false,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(img!.image.width, equals(256));
      expect(img.image.height, equals(256));
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
      verify(() => mockClient.readBytes(fallbackUrl, headers: headers))
          .called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Server failure - successful fallback, exceptions silenced',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(url, headers: any(named: 'headers')))
          .thenAnswer((_) async => throw ClientException('Server error'));

      final fallbackUrl = randomUrl(fallback: true);
      when(() =>
              mockClient.readBytes(fallbackUrl, headers: any(named: 'headers')))
          .thenAnswer((_) async {
        return testWhiteTileBytes;
      });

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl.toString(),
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: true,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
      verify(() => mockClient.readBytes(fallbackUrl, headers: headers))
          .called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Server failure - failed fallback, exceptions enabled',
    (tester) async {
      final url = randomUrl();
      final fallbackUrl = randomUrl(fallback: true);
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => throw ClientException('Server error'));

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl.toString(),
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: false,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNull);
      expect(tester.takeException(), isInstanceOf<ClientException>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
      verify(() => mockClient.readBytes(fallbackUrl, headers: headers))
          .called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Server failure - failed fallback, exceptions silenced',
    (tester) async {
      final url = randomUrl();
      final fallbackUrl = randomUrl(fallback: true);
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => throw ClientException('Server error'));

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl.toString(),
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: true,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
      verify(() => mockClient.readBytes(fallbackUrl, headers: headers))
          .called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Non-image response - no fallback, exceptions enabled',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        // 200 OK with html
        return Uint8List.fromList(utf8.encode('<html>Server Error</html>'));
      });

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: null,
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: false,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNull);
      final exception = tester.takeException();
      expect(exception, isInstanceOf<Exception>());
      expect(
        (exception as Exception).toString(),
        equals('Exception: Invalid image data'),
      );

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Non-image response - no fallback, exceptions silenced',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        // 200 OK with html
        return Uint8List.fromList(utf8.encode('<html>Server Error</html>'));
      });

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: null,
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: true,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Non-image response - successful fallback, exceptions enabled',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(url, headers: any(named: 'headers')))
          .thenAnswer((_) async {
        // 200 OK with html
        return Uint8List.fromList(utf8.encode('<html>Server Error</html>'));
      });

      final fallbackUrl = randomUrl(fallback: true);
      when(() =>
              mockClient.readBytes(fallbackUrl, headers: any(named: 'headers')))
          .thenAnswer((_) async {
        return testWhiteTileBytes;
      });

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl.toString(),
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: false,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(img!.image.width, equals(256));
      expect(img.image.height, equals(256));
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
      verify(() => mockClient.readBytes(fallbackUrl, headers: headers))
          .called(1);
    },
    timeout: defaultTimeout,
  );

  testWidgets(
    'Non-image response - successful fallback, exceptions silenced',
    (tester) async {
      final url = randomUrl();
      when(() => mockClient.readBytes(url, headers: any(named: 'headers')))
          .thenAnswer((_) async {
        // 200 OK with html
        return Uint8List.fromList(utf8.encode('<html>Server Error</html>'));
      });

      final fallbackUrl = randomUrl(fallback: true);
      when(() =>
              mockClient.readBytes(fallbackUrl, headers: any(named: 'headers')))
          .thenAnswer((_) async {
        return testWhiteTileBytes;
      });

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl.toString(),
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: false,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
      verify(() => mockClient.readBytes(fallbackUrl, headers: headers))
          .called(1);
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

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl.toString(),
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: false,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNull);
      final exception = tester.takeException();
      expect(exception, isInstanceOf<Exception>());
      expect(
        (exception as Exception).toString(),
        equals('Exception: Invalid image data'),
      );

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
      verify(() => mockClient.readBytes(fallbackUrl, headers: headers))
          .called(1);
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

      bool startedLoadingTriggered = false;
      bool finishedLoadingTriggered = false;

      final provider = MapNetworkImageProvider(
        url: url.toString(),
        fallbackUrl: fallbackUrl.toString(),
        headers: headers,
        httpClient: mockClient,
        silenceExceptions: true,
        startedLoading: () => startedLoadingTriggered = true,
        finishedLoadingBytes: () => finishedLoadingTriggered = true,
      );

      expect(startedLoadingTriggered, false);

      final img = await tester.runAsync(() => getImageInfo(provider));

      expect(startedLoadingTriggered, true);
      expect(finishedLoadingTriggered, true);

      expect(img, isNotNull);
      expect(tester.takeException(), isInstanceOf<Null>());

      verify(() => mockClient.readBytes(url, headers: headers)).called(1);
      verify(() => mockClient.readBytes(fallbackUrl, headers: headers))
          .called(1);
    },
    timeout: defaultTimeout,
  );

  tearDownAll(() => mockClient.close());
}
