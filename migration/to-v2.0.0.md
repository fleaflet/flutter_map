# To v2.0.0

This update brings major breaking changes. Please refer to the sections below for information on how to fix problems you may encounter.

<details>

<summary>Deprecated <code>NonCachingNetworkTileProvider</code> in favour of <code>NetworkNoRetryTileProvider</code></summary>

The old `TileProvider` was deprecated due to the misleading name and internal refactoring.

The provider did indeed provide some basic, unreliable, caching, and therefore the old name was incorrect. Additionally, other providers used a similar internal implementation, which provided the same caching, but did not also include 'NonCaching' in the name.&#x20;

To fix warnings, change all references to the new provider. No functionality will have been lost in this transfer.

_This deprecated API will be removed in the next minor update._

</details>

<details>

<summary><code>TileProviders</code> are no longer constant (<code>const</code>)</summary>

Due to internal refactoring, and the addition of the headers options, all built-in providers are no longer applicable to have the prefix keyword `const`.

To fix errors, remove the `const` keywords from the necessary locations.

</details>

<details>

<summary><code>updateInterval</code> and <code>tileFadeInDuration</code> are now <code>Duration</code>s </summary>

Previously, these parameters within the `TileLayerOptions` constructor were specified in an `int`eger number of milliseconds.

To fix errors, convert the millisecond time into a `Duration` object.

</details>

There are other changes, which can be seen in the full [CHANGELOG](https://pub.dev/packages/flutter\_map/changelog).
