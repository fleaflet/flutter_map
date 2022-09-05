# Recommended Options

## Center (`center`)

Takes a `LatLng` object, specifying the latitude and longitude of the center of the map when it is first built. For example:

```dart
        center: LatLng(0.0, 0.0),
```

will put the map at '[Null Island](https://en.wikipedia.org/wiki/Null\_Island)' on first build, where the Prime Meridian and Equator intersect at 0 deg Latitude and 0 deg Longitude.

Defaults to `LatLng(50.5, 30.51)`.

## Zooms (`zoom`, `minZoom`, `maxZoom`)

Takes `double`s, but should usually be set initially to integers (in double format).

For an explanation of zoom levels, see the [How Does It Work?](../../getting-started/explanation/#zoom) page.

`zoom` specifies what the zoom level of the map should be when it is first built, defaulting to level 13. `maxZoom` specifies what the maximum zoom level can be, and should depend on your use case and/or tile server. `minZoom` specifies what the minimum zoom level can be, and should usually be set to 0/`null` default.

```dart
        zoom: 13.0,
        maxZoom: 19.0,
```

{% hint style="warning" %}
Note that many tile servers will not support past a zoom level of 18. Always specify the `maxZoom` below the maximum zoom level of the server, to avoid your users seeing a void of grey tiles.

The OpenStreetMap Tile Server supports up to level 19, and a small amount of other servers support up to level 22.
{% endhint %}

## Boundaries (`bounds`, `maxBounds`)

Takes `LatLngBounds` to restrict the map view within a rectangular area.

`bounds` is only effective on first build, and is an alternative to using `center` and `zoom` to initialise the map. `maxBounds` is persistent and prevents the view moving outside of the area. For example:

```dart
        bounds: LatLngBounds(
            LatLng(51.74920, -0.56741),
            LatLng(51.25709, 0.34018),
        ),
        maxBounds: LatLngBounds(
            LatLng(-90, -180.0),
            LatLng(90.0, 180.0),
        ),
```

will make the map center on London at first, and ensure that the gray void around the world cannot appear on screen (in the default projection).

{% hint style="warning" %}
Always specify your center within your boundaries to avoid errors. Boundaries will take preference over center.
{% endhint %}

## Rotation (`rotation`)

Takes a double specifying the bearing of the map when it is first built. For example:

```dart
        rotation: 180.0,
```

will put the South of the map at the top of the device.

Defaults to 0(°).

## Keep Alive (`keepAlive`)

If you are using a more complex layout in your application - such as using the map inside a `ListView`, a `PageView`, or a tabbed layout - you may find that the map resets when it appears/scrolls back into view. This option is designed to prevent that.

Takes a `bool` flag, toggling whether the internal map state should `wantKeepAlive`.

```dart
        keepAlive: true,
```

Defaults to `false`.

{% hint style="warning" %}
Overuse of this option may lead to performance issues.

It prevents the Flutter VM from freeing up as much memory, and it must remain processing any events that may happen to it.
{% endhint %}
