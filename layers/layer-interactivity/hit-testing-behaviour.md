# Hit Testing Behaviour

The behaviour of hit testing can be confusing at first. These rules define how hit testing usually behaves:

1. Gesture callbacks in `MapOptions` are always invoked, no matter what is within the layers or the result of `hitTest`s in those layers, with the exception of custom defined hit test behaviours (not those layers that support interactivity, see [.](./ "mention")), such as applying `GestureDetector`s around `Marker.child`ren

{% hint style="warning" %}
`GestureDetector`s absorb hit tests, and so corresponding callbacks in `MapOptions` will not be invoked if they are defined/invoked in the `GestureDetector`.

Workarounds to resolve this are discussed below.
{% endhint %}

2. Hit testing is always\* performed on the interactable layers (see [.](./ "mention")) even if they have not been set-up for interactivity: hit testing != interactivity
3. Non-interactable layers (such as [overlay-image-layer.md](../overlay-image-layer.md "mention")) have no defined `hitTest`, and behaviour is situation dependent
4. A successful hit test (`true`) from an interactable layer will prevent hit testing on layers below it in the `children` stack

To change this behviour, make use of these three widgets, wrapping them around layers when and as necessary:

* [`IgnorePointer`](https://api.flutter.dev/flutter/widgets/IgnorePointer-class.html)
* [`AbsorbPointer`](https://api.flutter.dev/flutter/widgets/AbsorbPointer-class.html)
* `TranslucentPointer`: a general purpose 'widget' included with flutter\_map that allows the child to hit test as normal, but also allows widgets beneath it to hit test as normal, both seperately

***

For example, a marker with a `GestureDetector` child that detects taps beneath a `Polyline` will not detect a tap, no matter if the `PolylineLayer` has a defined `hitNotifier` or the `Polyline` has a defined `hitValue`. A defined `onTap` callback in `MapOptions` would be called however. If the `Marker` were no longer obscured by the `Polyline`, it's `onTap` callback would be fired instead of the one defined in `MapOptions`.

However, this behaviour could be changed by wrapping the `PolylineLayer` with a `TranslucentPointer`. This would allow interacitivity to function as normal, but also allow the `Marker` beneath to have it's `onTap` callback fired. Further wrapping another `TransclucentPointer` around the `MarkerLayer` would allow all 3 detections to function.
