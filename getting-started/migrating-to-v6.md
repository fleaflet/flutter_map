# Migrating To v6

{% hint style="info" %}
This update has renewed two of the oldest surviving sections of 'flutter\_map' (state/`MapController` and `TileProvider`s), fixed bugs, and added features!

This is significant progress in our aim to renew the project and bring it up to date. In the long run, this will bring it inline with up-to-date Flutter good practises and techniques, improve its performance and stability, and reduce the maintenance burden.
{% endhint %}

There are major breaking changes for all users, as well as some things users should check and possibly change.

Some changes have deprecations and messages, some do not. Please refer to the sections below for information on how to migrate your project, as well as in-code documentation and deprecation messages, if your migration is not listed below. Some changes are omitted if they are deemed unlikely to affect implementations.

## Changelog & Highlights

There's loads of changes in this release, which will improve performance and reduce costs! Check out these highlights, along with the full changelog:

{% embed url="https://github.com/fleaflet/flutter_map/blob/master/CHANGELOG.md" %}
Full Changelog
{% endembed %}

{% hint style="success" %}
We've added in-memory caching to the underlying custom `ImageProvider`. This means that they do not need to be re-requested if they are pruned then re-loaded, reducing tile loading times, and reduce tile requests and costs!

No action is needed to benefit from this.
{% endhint %}

{% hint style="success" %}
If you're developing an app for the web, there's an exciting new performance boost available. By aborting in-flight HTTP requests if tiles are pruned before they are fully-loaded, connections can be freed up, reducing tile loading times, and potentially saving you money!

There are also advantages for other platforms, although they may not be quite as visible.

Manual action is required to benefit from this. See [#cancellablenetworktileprovider](../layers/tile-layer/tile-providers.md#cancellablenetworktileprovider "mention") for more information.
{% endhint %}

{% hint style="success" %}
Rotation is now supported on desktop! Simply use the CTRL (or equivalent) keyboard key (customizable in `MapOptions`) and mouse.
{% endhint %}

{% hint style="success" %}
We've added some warning & recommendation logs in-code, that will trigger under certain circumstances. If they trigger, make sure to listen to them to benefit from performance and efficiency improvements!
{% endhint %}

## Migration Instructions

### General/Misc

<details>

<summary><code>CustomPoint</code> has been replaced by extension methods on <code>Point</code></summary>

[Extension methods](https://dart.dev/language/extension-methods) are now used to add the required functionality to the standard 'dart:math' `Point` object.

To migrate, most cases should just need to replace all occurrences of `CustomPoint` with `Point`.

</details>

<details>

<summary>"Plugin API" import has been removed</summary>

This import path was getting increasingly useless and exposing increasingly less features compared to the standard import. It also covered the standard import in the auto-generated DartDoc documentation, as it exported it as well.

All features that need to be exposed are now exposed through the primary import, and the dedicated plugin import has been removed.

</details>

### State Management

<details>

<summary><code>FlutterMapState</code> has been removed</summary>

`FlutterMapState` previously represented all of the map's state. However, to improve the maintainability of this library's internals, and to improve performance, it has been removed and replaced with several 'aspects':

* `MapCamera.of`: for more information, see  [#some-of-mapcontrollers-responsibilities-have-been-moved-to-mapcamera](migrating-to-v6.md#some-of-mapcontrollers-responsibilities-have-been-moved-to-mapcamera "mention")
* `MapOptions.of`: use to access the ambient configured `MapOptions`
* (`MapController.of`): use to access the ambient `MapController`, even if one was not explicitly defined by the user

In most cases, migrating will entail replacing `FlutterMapState` with `MapCamera`, but another aspect may be required.

See [#2.-hooking-into-inherited-state](../plugins/making-a-plugin/creating-new-layers.md#2.-hooking-into-inherited-state "mention") and [programmatic-control](../usage/programmatic-control/ "mention") for more information.

</details>

<details>

<summary>Some of <code>MapController</code>'s responsibilities have been moved to <code>MapCamera</code></summary>

`MapController` now only controls the map's position/viewport/camera. The map's position is now described by `MapCamera`.

You should not read camera data directly from a `MapController`: these methods have been deprecated.

There are multiple possibilities for migration:

1. If inside the `FlutterMap` context, prefer using `MapCamera.of(context)`
2. Otherwise, use `MapController` in the same way, but use the `.camera` getter to retrieve the `MapCamera`.

See [programmatic-control](../usage/programmatic-control/ "mention") for more information.

</details>

### Children/Layers

<details>

<summary><code>nonRotatedChildren</code> has been removed</summary>

The approach to 'mobile' and 'static' layers has been changed. Mobile layers now wrap themselves in a `MobileLayerTransformer` which uses the inherited state, instead of `FlutterMap` applying the affects directly to them. Static layers should now ensure they use `Align` and/or `SizedBox.expand`.

This has been done to simplify setup, and allow for placing static layers between mobile layers.

</details>

<details>

<summary>Custom layers need to define their behaviour</summary>

The way custom layers are defined has changed. Mobile/moving layers should now use `MobileLayerTransformer` at the top of their widget tree.

For more information, see [#1.-creating-a-layer-widget](../plugins/making-a-plugin/creating-new-layers.md#1.-creating-a-layer-widget "mention").

</details>

#### Tile Layer

<details>

<summary><code>retinaMode</code> behaviour has changed</summary>

Previously, the `retinaMode` property enabled/disabled the simulation of retina mode. To request retina tiles from the server, either the `{r}`placeholder or "@2x" string could be included in the `urlTemplate`.\
This behaviour was unclear, did not conform to the norms of other mapping packages, and meant the `{r}` placeholder was actually redundant.

Now, `retinaMode` also affects whether the `{r}` placeholder is filled in. If `true`, and `{r}` is present, then that will now be filled in to request retina tiles. If the placeholder is not present, only then will flutter\_map simulate retina mode.

Additionally, it is now recommended to use the `RetinaMode.isHighDensity` method to check whether `retinaMode` should be enabled.

For more information, see [#retina-mode](../layers/tile-layer/#retina-mode "mention").

</details>

<details>

<summary><code>backgroundColor</code> has been replaced by <code>MapOptions.backgroundColor</code></summary>

This will simplify the developer experience when using multiple overlaid `TileLayer`s, as `Colors.transparent` will no longer need to be specified. There is no reason that multiple `TileLayer`s would each need to have a different (non-transparent) background colors, as the layers beneath would be invisible and therefore pointless.

Therefore, `TileLayer`s now have transparent backgrounds, and the new `MapOptions.backgroundColor` property sets the background color of the entire map.

To migrate, move any background colour specified on the bottom-most `TileLayer` to `MapOptions`.

</details>

<details>

<summary><code>templateFunction</code> has been replaced by <code>TileProvider.populateTemplatePlaceholders</code></summary>

`TileProvider.templateFunction` has been deprecated. It is now preferrable to create a custom `TileProvider` extension, and override the `populateTemplatePlaceholders` method. This has been done to reduce the scope of `TileLayer`.

To migrate, see [creating-new-tile-providers.md](../plugins/making-a-plugin/creating-new-tile-providers.md "mention").

</details>

#### Marker Layer

<details>

<summary><code>anchor</code> and all related objects have been removed</summary>

In order to simplify `Marker`s, the `anchor` property and `AnchorPos`/`Anchor` objects have been removed without replacement.

Marker alignment is now performed with the standard `Alignment` object through the `alignment` argument.

Due to the previously named `anchor` being confusingly (and perhaps incorrectly) named, migration without behaviour change is possible just by taking the `Alignment` from inside any `AnchorPos` and passing it directly to `alignment`.

</details>

<details>

<summary><code>rotateOrigin</code> and <code>rotateAligment</code> have been removed</summary>

These properties on `Marker` have been removed as it is not apparent what any valid use-case could be, and removing them helped simplify the internals significantly.

If these are currently used, try changing `alignment`, and if that does not give the desired results, use a `Transform` widget yourself.

</details>

### Map Options

<details>

<summary><code>center</code>, <code>bounds</code>, <code>zoom</code>, and <code>rotation</code> have been replaced with <code>initialCenter</code>, <code>initialCameraFit</code>, <code>initialZoom</code>, and <code>initialRotation</code></summary>

These have been renamed for clarity, as well as to better fit the change into using a documented 'camera' and increasing customizability.

To migrate, rename the properties, and also check the in-code documentation and new objects for information.

</details>

<details>

<summary><code>maxBounds</code> has been replaced with <code>cameraConstraint</code></summary>

This is part of to better fit the change into using a documented 'camera' and increasing customizability.

To migrate, rename the properties, and also check the in-code documentation and new objects for information.

</details>

<details>

<summary>Interactive options (such as <code>interactiveFlags</code>) have been moved into <code>InteractionOptions</code></summary>

This has been done to improve readability and seperation of responsibilities.

For more information, see [interaction-options.md](../usage/options/interaction-options.md "mention").

</details>

### Tile Providers

<details>

<summary>Implementations should switch to extensions</summary>

It is not recommended to implement `TileProvider`, as there are now two methods of which only one should be implemented (`getImage` & `getImageWithCancelLoadingSupport`), as well as other members that should not usually be overridden.

To migrate, use `extends` instead of `implements`.

_Further panes will refer to implementations that use `extends` as 'extensions' for clarity, not to be confused with extension methods._

</details>

<details>

<summary>Extensions should not provide a constant default value for <code>headers</code> in the constructor</summary>

`TileLayer` behaviour has been modified so that the 'User-Agent' header can be set without copying all user-specified `headers`. It is now inserted into the `Map`, so it must be immutable/non-constant.

Note that the `headers` property is also now `final`.

To migrate, remove the default value for `super.headers`: it is not necessary.

</details>

<details>

<summary>Extensions overriding <code>getTileUrl</code> should consider overriding other methods instead</summary>

The logic previously handled by `getTileUrl`, `invertY`, and `getSubdomain` has been refactored into `generateReplacementMap`, `populateTemplatePlaceholders`, and `getTileUrl`.

To migrate, consider overriding another of those methods, if it is more suitable. This will reduce the amount of code duplicated in your library from flutter\_map's implementation.

</details>

<details>

<summary>Extensions implementing <code>getImage</code> should consider overriding <code>getImageWithCancelLoadingSupport</code> instead </summary>

The framework necessary to support tile providers that can abort in-flight HTTP requests and other processing is now available. For more information about the advantages of cancelling unnecessary tile requests when they are pruned before being fully loaded, see [#cancellablenetworktileprovider](../layers/tile-layer/tile-providers.md#cancellablenetworktileprovider "mention").

If it is not possible to cancel the loading of a tile, or there is no advantage gained by doing so, you can ignore this.

To migrate, override `supportsCancelLoading` to `true`, implement `getImageWithCancelLoadingSupport` as appropriate, and remove the implementation of `getImage`.

</details>
