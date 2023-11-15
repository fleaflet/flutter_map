# Overlay Image Layer

You can overlay images on the map (for example, town or floor plans) using `OverlayImageLayer` and `OverlayImage`s or `RotatedOverlayImage`s.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/OverlayImageLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/BaseOverlayImage-class.html" %}

<figure><img src="../.gitbook/assets/ExampleImageOverlay.png" alt=""><figcaption><p>Example <code>RotatedOverlayImage</code></p></figcaption></figure>

```dart
OverlayImageLayer(
  overlayImages: [
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

{% hint style="warning" %}
There have been issues in the past where these images failed to appear properly, sometimes not showing up at all, sometimes showing up malformed or corrupted.

If this issue occurs to you, and you're using Impeller, try disabling Impeller at launch/build time to see if the issue rectifies itself. If it does, this is an Impeller issue, and should be reported to the Flutter team.
{% endhint %}
