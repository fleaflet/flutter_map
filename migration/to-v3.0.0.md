# To v3.0.0

This update brings major breaking changes for all users.

{% hint style="info" %}
We apologise for any difficulty this may cause and time you may spend migrating.

However, this update is a part of our aim to simplify this library, and should improve stability, readability, and performance for you in the long term. In addition, this will make the library much easier to maintain and add new functionality to through plugins and future features.
{% endhint %}

For a full list of changes, please see the full [CHANGELOG](https://pub.dev/packages/flutter\_map/changelog), and make use of the old and new API reference.

## Application Migration

Please refer to the sections below for information on how to migrate your application. This will contain the changes that most users may need to make, but not all changes.

{% hint style="success" %}
This version requires a minimum of Flutter 3.3.0. Use `flutter upgrade` to update to this version.
{% endhint %}

<details>

<summary>Removed <code>layers</code> in favour of <code>children</code></summary>

The `layers` (and `nonRotatedLayers`) properties on the `FlutterMap` widget have been removed without deprecation.

To migrate, replace `layers` with `children`, and also see [#removed-layerwidgets-and-layeroptions-in-favour-of-layers](to-v3.0.0.md#removed-layerwidgets-and-layeroptions-in-favour-of-layers "mention").

{% code title="Old Code (<3.0.0)" %}
```dart
    layers: [],
    nonRotatedLayers: [],
```
{% endcode %}

{% code title="New Code (3.0.0+)" %}
```dart
    children: [],
    nonRotatedChildren: [],
```
{% endcode %}

</details>

<details>

<summary>Removed <code>LayerWidget</code>s &#x26; <code>LayerOption</code>s in favour of <code>Layer</code>s</summary>

All existing `LayerWidget`s & `LayerOption`s have been removed without deprecation.

To migrate, replace `LayerOptions` with `Layer`. Additionally, if you are currently using `children`, remove all `LayerWidget` wrappers.

{% code title="Old Code (<3.0.0)" %}
```dart
    layers: [
        TileLayerOptions(),
        MarkerLayerOptions(),
    ],
    children: [
        TileLayerWidget(options: TileLayerOptions()),
        MarkerLayerWidget(options: MarkerLayerOptions()),
    ],
```
{% endcode %}

{% code title="New Code (3.0.0+)" %}
```dart
    children: [
        TileLayer(),
        MarkerLayer(),
    ],
```
{% endcode %}

</details>

<details>

<summary>Replaced <code>onMapCreated</code> with <code>onMapReady</code> inside <code>MapOptions</code></summary>

The `onMapCreated` property inside the `MapOptions` object has been removed without deprecation.

To migrate, replace `onMapCreated` with `onMapReady`. Note that the current `MapController` is no longer passed into the callback.

This method should only be used in particular circumstances, and avoided otherwise. See [#when-map-ready-onmapready](../usage/options/other-options.md#when-map-ready-onmapready "mention").

</details>

<details>

<summary>Removed <code>MapController().onReady</code></summary>

See [#replaced-onmapcreated-with-onmapready-inside-mapoptions](to-v3.0.0.md#replaced-onmapcreated-with-onmapready-inside-mapoptions "mention"). If this was necessary to `await` in your project (particularly in `initState`), you will need to migrate to using [#when-map-ready-onmapready](../usage/options/other-options.md#when-map-ready-onmapready "mention").

</details>

## Plugin Migration

Unfortunately, migrating plugins that implement custom layers is more difficult than just renaming in many cases. In good news, the new system requires no complex registration, and will simplify your code.

Previously, state was updated through a `StreamBuilder`. Since v3, state is updated using `setState`. This means your tile layer is now just a widget, for all intents and purposes, and anything you put in build will automatically be rebuilt when the map state changes.

For more information, see [creating-new-layers.md](../plugins/making-a-plugin/creating-new-layers.md "mention").

To migrate, place any `StreamBuilder` implementation with the below code snippet, and the latest map state will automatically get passed down.

```dart
@override
Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context)!;
    // Use `mapState` as necessary, for example `mapState.zoom`
}
```

Your plugin may also now be able to be a `StatelessWidget`, which may increase performance and simplify your code!

In addition to that change:

<details>

<summary>Replaced <code>MapState</code> with <code>FlutterMapState</code></summary>

The `MapState` class has been removed without deprecation.

To migrate, replace `MapState` with `FlutterMapState`.  This is a name change due to internal reorganization of state management.

</details>

<details>

<summary>Replaced <code>getPixelOrigin</code> with <code>pixelOrigin</code> inside <code>FlutterMapState</code></summary>

The `getPixelOrigin` method has been removed without deprecation.

To migrate, replace `getPixelOrigin` with `pixelOrigin`.  This is a name change aimed to improve internal consistency.

</details>
