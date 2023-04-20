# Overlay Image Layer

You can overlay images on the map (for example, town or floor plans) using `OverlayImageLayer` and `OverlayImage`s or `RotatedOverlayImage`s.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/OverlayImageLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/BaseOverlayImage-class.html" %}

<figure><img src="../.gitbook/assets/ExampleImageOverlay.png" alt=""><figcaption><p>Example <code>RotatedOverlayImage</code></p></figcaption></figure>

```dart
OverlayImageLayer(
  circles: [
    OverlayImage(
      bounds: LatLngBounds(
        LatLng(45.3367881884556, 14.159452282322459),
        LatLng(45.264129635422826, 14.252585831779033),
      ),
      imageProvider: NetworkImage(),
    ),
  ],
),
```
