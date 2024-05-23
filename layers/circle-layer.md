# Circle Layer

You can add circle areas to maps by making them out of a center coordinate and radius using `CircleLayer` and `CircleMarker`s.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/CircleLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/CircleMarker-class.html" %}

<figure><img src="../.gitbook/assets/ExampleCircle.png" alt=""><figcaption><p>An example <code>CircleMarker</code></p></figcaption></figure>

```dart
CircleLayer(
  circles: [
    CircleMarker(
      point: LatLng(51.50739215592943, -0.127709825533512),
      radius: 10000,
      useRadiusInMeter: true,
    ),
  ],
),
```

{% hint style="warning" %}
Excessive use of circles may create performance issues.
{% endhint %}

## Interactivity

`CircleLayer`s and `CircleMarker`s support hit detection and interactivity.

{% content-ref url="layer-interactivity/" %}
[layer-interactivity](layer-interactivity/)
{% endcontent-ref %}
