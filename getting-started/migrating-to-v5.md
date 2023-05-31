# Migrating To v5

This update brings support for Dart 3 and Flutter 3.10.

{% hint style="success" %}
We've updated some dependencies, including 'latlong2' (to 0.9.0) and 'http' (1.0.0)!

`LatLng` objects now have `const` constructors to improve performance. To automatically insert the `const` keyword where necessary, run `dart fix`.
{% endhint %}

There are a few minor breaking changes for some users, but most changes are internal and need no work to take advantage of.

Please refer to the sections below for information on how to migrate your project. This will contain the changes that most users may need to make, but not all changes. It also excludes some deprecations where the message is self-descriptive.

For a full list of changes, please see the full [CHANGELOG](https://pub.dev/packages/flutter\_map/changelog), and make use of the old and new API reference.

{% embed url="https://github.com/fleaflet/flutter_map/blob/master/CHANGELOG.md" %}

<details>

<summary><code>NetworkNoRetryTileProvider</code> has been removed &#x26; <code>NetworkTileProvider</code> now retries failed requests by default</summary>

`NetworkNoRetryTileProvider` did not automatically retry requests, unlike `NetworkTileProvider`. The differentiation was required because of restrictions of its HTTP client and ability to change its headers.

This appears to be fixed, so this workaround is no longer required.

Therefore, `NetworkTileProvider` now uses a `RetryClient`, and `NetworkNoRetryTileProvider` has been removed.

If you were leaving the `TileLayer`'s `TileProvider` at its default (`NetworkNoRetryTileProvider`), **no migration is necessary**. Most users should not see a difference with the new retry strategy, as it is preferable anyway.

If non-retriable requests are a necessity, specify `NetworkTileProvider`, and manually set its `httpClient` property to a standard `Client`.

</details>

<details>

<summary><code>FileTileProvider</code> now throws an <code>UnsupportedError</code> when used on web</summary>

Previously, `FileTileProvider` redirected automatically on web to a `NetworkImage` internally, as the web platform does not have access to IO.

To migrate, detect the web platform yourself (if you run on it), and switch automatically to `NetworkTileProvider`.

</details>

<details>

<summary><code>PolylineLayer</code> no longer includes the <code>saveLayers</code> property</summary>

Whether canvas layers need to be saved is now decided automatically internally. If the polyline(s) within have translucency (<1 opacity), the canvas layers will be saved, to improve the render quality. Otherwise, they will not be unnecessarily saved, in order to improve performance.

To migrate, remove the argument without replacement.

</details>

<details>

<summary>Changed some <code>CustomPoint&#x3C;T></code>s' generic type</summary>

`CustomPoints` previously used `num` as their generic type, which lead to type casting within FM and plugins, as some code only allowed `int`/`double`, not `num`.

Many of these have been updated to reflect their true usage.

To migrate, look for any methods which now take a different generic typed `CustomPoint` than was previously required. These should then be either casted at this location, or the source of the number should more accurately represent what the number will be.

For more information, see [https://github.com/fleaflet/flutter\_map/pull/1515](https://github.com/fleaflet/flutter\_map/pull/1515).

</details>
