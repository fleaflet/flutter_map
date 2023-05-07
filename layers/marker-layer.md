# Marker Layer

You can add single point features - such as pins, labels, or markers - to maps using `MarkerLayer` and `Marker`s.

{% hint style="success" %}
No more image only markers! [Unlike _other_ ](https://github.com/flutter/flutter/issues/24213)😉[^1][ popular mapping libraries](https://github.com/flutter/flutter/issues/24213), we allow usage of any widget as the marker.
{% endhint %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/MarkerLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/Marker-class.html" %}

<figure><img src="../.gitbook/assets/ExampleMarker.png" alt=""><figcaption><p>An example <code>Marker</code>, using <code>FlutterLogo</code> as the child</p></figcaption></figure>

```dart
MarkerLayer(
  markers: [
    Marker(
      point: LatLng(30, 40),
      width: 80,
      height: 80,
      builder: (context) => FlutterLogo(),
    ),
  ],
),
```

{% hint style="warning" %}
Excessive use of markers may create performance issues.

Consider using a clustering plugin to merge nearby markers together, reducing the work that needs to be done when rendering: [#marker-clustering](../plugins/list.md#marker-clustering "mention").
{% endhint %}

## Rotation

Marker rotation support isn't built in (other than counter rotating to the map, to ensure the marker is always displayed right side up), but can easily be implemented through a rotation widget, such as `Transform.rotate`.

[^1]: [Google Maps \*wink \*wink](https://github.com/flutter/flutter/issues/24213)
