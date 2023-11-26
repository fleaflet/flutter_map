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

  final ImageStream stream = provider.resolve(ImageConfiguration.empty);
  stream.addListener(
    ImageStreamListener(
      (imageInfo, _) {
        return completer.complete(imageInfo);
      },
      onError: (exception, stackTrace) {
        return completer.completeError(exception, stackTrace);
      },
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

  setUpAll(() {
    // Ensure the Mock library has example values for Uri.
    registerFallbackValue(Uri());
  });

  // We expect a request to be made to the correct URL with the appropriate headers.
  testWidgets('test load with correct url/headers', (tester) async {
    final mockClient = MockHttpClient();
    final url = randomUrl();
    when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async {
      return testWhiteTileBytes;
    });

    final provider = MapNetworkImageProvider(
      url: url.toString(),
      fallbackUrl: null,
      headers: headers,
      httpClient: mockClient,
    );

    final img = await tester.runAsync(() => getImageInfo(provider));
    expect(img, isNotNull);
    expect(img!.image.width, equals(256));
    expect(img.image.height, equals(256));

    verify(() => mockClient.readBytes(url, headers: headers)).called(1);
  }, timeout: defaultTimeout);

  // We expect the request to be made, and a HTTP ClientException to be bubbled
  // up to the caller.
  testWidgets('test load with server failure (no fallback)', (tester) async {
    final mockClient = MockHttpClient();
    final url = randomUrl();
    when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async {
      throw ClientException(
        'Server error',
      );
    });

    final provider = MapNetworkImageProvider(
      url: url.toString(),
      fallbackUrl: null,
      headers: headers,
      httpClient: mockClient,
    );

    final img = await tester.runAsync(() => getImageInfo(provider));
    expect(img, isNull);
    expect(tester.takeException(), isInstanceOf<ClientException>());

    verify(() => mockClient.readBytes(url, headers: headers)).called(1);
  }, timeout: defaultTimeout);

  // We expect the regular URL to be called once, then the fallback URL.
  testWidgets('test load with server error (with successful fallback)',
      (tester) async {
    final mockClient = MockHttpClient();
    final url = randomUrl();
    when(() => mockClient.readBytes(url, headers: any(named: 'headers')))
        .thenAnswer((_) async {
      throw ClientException(
        'Server error',
      );
    });
    final fallbackUrl = randomUrl(fallback: true);
    when(() =>
            mockClient.readBytes(fallbackUrl, headers: any(named: 'headers')))
        .thenAnswer((_) async {
      return testWhiteTileBytes;
    });

    final provider = MapNetworkImageProvider(
      url: url.toString(),
      fallbackUrl: fallbackUrl.toString(),
      headers: headers,
      httpClient: mockClient,
    );

    final img = await tester.runAsync(() => getImageInfo(provider));
    expect(img, isNotNull);
    expect(img!.image.width, equals(256));
    expect(img.image.height, equals(256));

    verify(() => mockClient.readBytes(url, headers: headers)).called(1);
    verify(() => mockClient.readBytes(fallbackUrl, headers: headers)).called(1);
  }, timeout: defaultTimeout);

  testWidgets('test load with server error (with failed fallback)',
      (tester) async {
    final mockClient = MockHttpClient();
    final url = randomUrl();
    final fallbackUrl = randomUrl(fallback: true);
    when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async {
      throw ClientException(
        'Server error',
      );
    });

    final provider = MapNetworkImageProvider(
      url: url.toString(),
      fallbackUrl: fallbackUrl.toString(),
      headers: headers,
      httpClient: mockClient,
    );

    final img = await tester.runAsync(() => getImageInfo(provider));
    expect(img, isNull);
    expect(tester.takeException(), isInstanceOf<ClientException>());

    verify(() => mockClient.readBytes(url, headers: headers)).called(1);
    verify(() => mockClient.readBytes(fallbackUrl, headers: headers)).called(1);
  }, timeout: defaultTimeout);

  testWidgets('test load with invalid response (no fallback)', (tester) async {
    final mockClient = MockHttpClient();
    final url = randomUrl();
    when(() => mockClient.readBytes(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async {
      // 200 OK with html
      return Uint8List.fromList(utf8.encode('<html>Server Error</html>'));
    });

    final provider = MapNetworkImageProvider(
      url: url.toString(),
      fallbackUrl: null,
      headers: headers,
      httpClient: mockClient,
    );

    final img = await tester.runAsync(() => getImageInfo(provider));
    expect(img, isNull);
    expect(tester.takeException(), isInstanceOf<Exception>());

    verify(() => mockClient.readBytes(url, headers: headers)).called(1);
  }, timeout: defaultTimeout);

  testWidgets('test load with invalid response (with successful fallback)',
      (tester) async {
    final mockClient = MockHttpClient();
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

    final provider = MapNetworkImageProvider(
      url: url.toString(),
      fallbackUrl: fallbackUrl.toString(),
      headers: headers,
      httpClient: mockClient,
    );

    final img = await tester.runAsync(() => getImageInfo(provider));
    expect(img, isNotNull);
    expect(img!.image.width, equals(256));
    expect(img.image.height, equals(256));

    verify(() => mockClient.readBytes(url, headers: headers)).called(1);
    verify(() => mockClient.readBytes(fallbackUrl, headers: headers)).called(1);
  }, timeout: defaultTimeout);
}
