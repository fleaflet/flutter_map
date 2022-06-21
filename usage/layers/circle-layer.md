# Circle Layer

{% hint style="info" %}
We're writing this documentation page now! Please hold tight for now, and refer to older documentation or look in the API Reference.
{% endhint %}

You can add circle polygons to maps to users using `CircleLayerOptions()`.

```dart
FlutterMap(
    options: MapOptions(),
    layers: [
        CircleLayerOptions(
            circles: [],
        ),
    ],
),
```

{% hint style="warning" %}
Due to the nature of the Earth being a sphere, drawing lines perfectly requires large amounts of difficult maths that may not behave correctly when given certain edge-cases.

Avoid creating large polygons, or polygons that cross the edges of the map, as this may create undesired results.
{% endhint %}

{% hint style="warning" %}
Excessive use of circles will create performance issues and lag/'jank' as the user interacts with the map. See [Performance Issues](../common-issues.md#performance-issues) for more information.
{% endhint %}
