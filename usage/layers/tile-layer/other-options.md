---
description: Visit the Full API Reference for the full list of available options
---

# Other Options

## Subdomains (`subdomains:`)

Takes a list of strings specifying the available subdomains. For example:

```dart
        subdomains: ['a', 'b', 'c'],
```

These are the available sub-subdomains for Open Street Maps' tile server, and one will be chosen differently every request by the tile provider to replace the '{s}' part of the `urlTemplate`.

If you are not sure of the correct values for your server, don't specify anything. For example, the `urlTemplate` used in the example above will work without the '{s}' part and any subdomains specified.

{% hint style="info" %}
This option is recommended when the map may be used on the web platform. Browsers impose a limit on the number of HTTP connections that can be made simultaneously to one domain, so as not to overload servers. Making tile requests to multiple subdomains works around this limitation.

On other platforms, this is redundant, and only needs to be used if your tile server recommends it, for example for load-balancing purposes.
{% endhint %}

## Tile Bounds (`tileBounds:`)

Takes a `LatLngBounds` to restrict the layer to only loading tiles within that area. For example:

```dart
        tileBounds: LatLngBounds(
            LatLng(32.2934590056236, 24.328924534719548),
            LatLng(21.792152188247265, 37.19854583903912),
        ),
```

will restrict the tiles to only loading Egypt (a square-ish country). Note that the map can still be moved freely outside of this range.

An example use-case might therefore be loading a specialised map for a region and just a basic map style elsewhere (different `urlTemplate`s). In this case, the bounded layer should go beneath the unbounded layer. Setting `backgroundColor: Colors.transparent` is also necessary on the bounded layer to ensure the other layer is visible elsewhere.

## Error/Fallback Tile (`errorImage:`)

Takes an `ImageProvider`, such as a `NetworkImage`, to use if the tile cannot be fetched using the `templateUrl`. The size of the returned image should be the same as the [tile size](other-options.md#tile-size). For example:

```dart
        errorImage: const NetworkImage('https://tile.openstreetmap.org/18/0/0.png'),
```

will use a sea tile on every tile that cannot be fetched.

This is an optional parameter that has no default. If this is not specified, and tiles are unable to be fetched, then the background color.

## Tile Size (`tileSize:`)

Takes a `double` number specifying the width and height (in pixels) of each tile. As tiles are always square, only one number is needed.

This defaults to 256, as most tile servers serve 256x256px tiles.

## Custom Tile Builder (`tileBuilder:`)

Takes a callback function, in the format `Widget Function(BuildContext context, Widget tileWidget, Tile tile)`. For example:

```dart
        tileBuilder: (context, widget, tile) =>
          Stack(
            fit: StackFit.passthrough,
            children: [
              widget,
              Center(
                child:
                  Text('${tile.coords.x.floor()} : ${tile.coords.y.floor()} : ${tile.coords.z.floor()}'),
              ),
            ],
          );
```

will show the tile's coordinate on the tile.

There is also `tilesContainerBuilder` available, which works slightly differently, but is recommended when the same builder can be used on every tile, for performance reasons.

There are predefined tile builders available, such as a dark mode emulator and a loading time debugger.

## Reset Stream (`reset:`)

Takes a `Stream<void>?`,  that causes the layer to 'reset' when an event is received. This might be necessary after updating the `templateUrl`. For example:

```dart
       reset: resetController.stream,
  
  // Elsewhere     
  final StreamController<void> resetController = StreamController.broadcast();
  void resetMap() => resetController.add(null);
```
