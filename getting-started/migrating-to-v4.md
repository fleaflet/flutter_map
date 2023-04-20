# To v4.0.0

This update brings major breaking changes for all users.

{% hint style="info" %}
We apologise for any difficulty this may cause and time you may spend migrating.

However, this update is a part of our aim to simplify this library, and should improve stability, readability, and performance for you in the long term. In addition, this will make the library much easier to maintain and add new functionality to through plugins and future features.
{% endhint %}

Please refer to the sections below for information on how to migrate your project. This will contain the changes that most users may need to make, but not all changes.

For a full list of changes, please see the full [CHANGELOG](https://pub.dev/packages/flutter\_map/changelog), and make use of the old and new API reference.

## `TileLayer` Changes

One of the major cores of flutter\_map has been upgraded to the 21st century by a generous contributor (@rorystephenson). This increases the simplicity of the layer, and its performance!

<details>

<summary>Consolidated multiple properties into <code>tileDisplay</code> and <code>tileUpdateTransformer</code></summary>

The following properties have been removed:

* `updateInterval`
* `tileFadeInDuration`
* `tileFadeInStart`
* `tileFadeInStartWhenOverride`
* `overrideTilesWhenUrlChanges`
* `fastReplace`

... and replaced with `tileDisplay` (`TileDisplay`) & `tileUpdateTransformer` (`StreamTransformer<TileUpdateEvent, TileUpdateEvent>`).

There is no "one size fits all" available for this migration: you'll need to experiment to find a combination of the two that work. Read the in-code API documentation for more information about what each one does.

</details>

<details>

<summary>Removed <code>opacity</code> property</summary>

To migrate, wrap the `TileLayer` with an `Opacity` widget.

{% code title="Old Code (<4.0.0)" %}
```dart
children: [
    TileLayer(
        // urlTemplate: '',
        opacity: 0.5,
    ),
],
```
{% endcode %}

{% code title="New Code (4.0.0+)" %}
```dart
children: [
    Opacity(
        opacity: 0.5,
        child: TileLayer(
            // urlTemplate: '',
        ),
    ),
],
```
{% endcode %}

</details>

## Attribution Changes

Grey boxes get a little boring, don't you think? We think so as well, so we've developed a new interactive animated attribution layer that should cover all your needs.

{% content-ref url="../layers/attribution-layer.md" %}
[attribution-layer.md](../layers/attribution-layer.md)
{% endcontent-ref %}

<details>

<summary>Replaced <code>AttributionWidget.defaultWidget</code> with <code>SimpleAttributionWidget</code></summary>

To migrate, replace with `SimpleAttributionWidget` and fill properties as necessary - see the in-code API documentation.

Alternatively, consider implementing attribution using [#richattributionwidget](../layers/attribution-layer.md#richattributionwidget "mention") to take advantage of the new interactive, animated layer.

</details>

<details>

<summary>Removed <code>AttributionWidget</code></summary>

To migrate, replace with an `Align` widget (and insert directly into the map's `nonRotatedChildren`).

</details>

## Other Changes

<details>

<summary>Removed <code>absorbPanEventsOnScrollables</code></summary>

Setting this to `false` was equivalent to disabling drag gestures through [#interactivity-settings-interactiveflags](../usage/options/other-options.md#interactivity-settings-interactiveflags "mention").

To migrate map code, use the `interactiveFlags` as above.

To migrate plugin code, use `onVerticalDrag` and `onHorizontalDrag` updates instead of `onPan`. For more information, see [https://github.com/fleaflet/flutter\_map/pull/1455](https://github.com/fleaflet/flutter\_map/pull/1455).

</details>
