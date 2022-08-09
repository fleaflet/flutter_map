# Controller

The `mapController` property takes a `MapController()`, and whilst it is optional, it is strongly recommended for any map other than the most basic. It allows you to programmatically interact with the map, such as panning, zooming and rotating.

This is the recommended setup:

```dart
import 'package:flutter_map/flutter_map.dart';

// Inside the stateful widget

late final MapController mapController;

@override
void initState() {
    super.initState();
    mapController = MapController();
}

// Inside the build method of the stateful widget

FlutterMap(
    mapController: mapController,
),
```

{% hint style="warning" %}
Don't be tempted to specify this property inside the `MapOptions()`. Always specify it at the top level of a `FlutterMap()` widget.
{% endhint %}

Each subpage details a specific method/getter available on the `MapController`. Full usage information can be found in the Full API Reference.

{% hint style="info" %}
We're writing this documentation page now! Please hold tight for now, and refer to older documentation or look in the API Reference.
{% endhint %}
