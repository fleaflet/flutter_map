# Move

{% hint style="info" %}
We're writing this documentation page now! Please hold tight for now, and refer to older documentation or look in the API Reference.
{% endhint %}

```dart
MapController().move(
    center: LatLng, // Required
    zoom: int, // Required
    id: String?,
);
```

Pans the map to the specified location and zoom level.Optionally specify the `id` attribute to emit a move event and if you listen to mapEventStream later a MapEventMove event will be emitted (if move was success) with same `id` attribute. Event's source attribute will be MapEventSource.mapController.returns `true` if move was success (for example it won't be success if navigating to same place with same zoom or if center is out of bounds and MapOptions.slideOnBoundaries isn't enabled)
