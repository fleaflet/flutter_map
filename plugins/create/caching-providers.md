# Caching Providers

[built-in-caching.md](../../layers/tile-layer/built-in-caching.md "mention") is extensible.

To create a new caching provider which is compatible with all tile providers which are compatible with built-in caching, create a class which implements `MapCachingProvider` and its required interface.

```dart
class CustomCachingProvider implements MapCachingProvider {
  @override
  bool get isSupported => throw UnimplementedError();

  @override
  Future<({Uint8List bytes, CachedMapTileMetadata metadata})?> getTile(
    String url,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) {
    throw UnimplementedError();
  }
}
```

Compatible tile providers check `isSupported` before using `getTile` or `putTile`.

Check in-code documentation for more detail on requirements and expectations.

Many providers may only work on certain platforms. In this case, implementations can mix-in `DisabledMapCachingProvider` on unsupported platforms:

```dart
class CustomCachingProvider
    with DisabledMapCachingProvider
    implements MapCachingProvider {}
```
