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

Compatible tile providers must check `isSupported` before using `getTile` or `putTile`.

Check in-code documentation for more detail on requirements and expectations.

***

Many providers may only work on certain platforms. In this case, implementations can mix-in `DisabledMapCachingProvider` on unsupported platforms:

```dart
class CustomCachingProvider
    with DisabledMapCachingProvider
    implements MapCachingProvider {}
```

***

If a provider cannot read a tile from the cache, but the tile is present, the provider should:

* throw `CachedMapTileReadFailure` with as much information as possible from `readTile`
* repair or replace the tile with a fresh & valid one
* ensure other mechanisms are resilient to corruption

This could occur due to corruption, for example a power cut, a sudden storage issue, or an intentional modification that did not comply with the expected specification.

It is not the provider's responsibility to check that stored tile bytes are valid. Providers may return invalid or undecodable bytes to tile providers, which they should handle gracefully by falling back to a non-caching alternative to retrieve a tile, and safely updating the invalid stored tile.
