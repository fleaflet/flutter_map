# Unbounded Horizontal Scrolling

{% hint style="info" %}
This page contains references to as-of-yet unreleased versions.
{% endhint %}

Since v8 & v8.2.0, flutter\_map supports unbounded horizontal (longitudinally) scrolling for the default map projection. This means users can keep scrolling left and right (when North is up) and never hit an edge! Feature layers, such as the `PolygonLayer`, can also take advantage of this functionality.

<div data-full-width="true"><figure><img src="../../.gitbook/assets/Basic Multi-World Screenshot.png" alt=""><figcaption></figcaption></figure></div>

## Enabling/disabling unbounded horizontal scrolling

Within the codebase, unbounded horizontal scrolling is referred to as `replicatesWorldLongitude`, and is set on the CRS/projection level.

The default projection, `Epsg3857`, enables the functionality by default.

<details>

<summary>Disabling unbounded horizontal scrolling</summary>

To disable the functionality, change the projection. If you want to keep using `Epsg3857`, create the following class, and pass it to `MapOptions.crs`:

```dart
class Epsg3857NoRepeat extends Epsg3857 {
  const Epsg3857NoRepeat();

  @override
  bool get replicatesWorldLongitude => false;
}
```

</details>

## Constraining the camera vertically/latitudinally

It's now possible to remove the grey edges that appear at the top and bottom of the map when zoomed far out.

To do this, set the `MapOptions.cameraConstraint` parameter:

```dart
FlutterMap(
    options: MapOptions(
      cameraConstraint: const CameraConstraint.containLatitude(),
    ),
    children: [],
),
```

## Feature layers & multi-worlds

Each square of map that is repeated longitudinally is referred to as a "world". By default, the feature layers (for example, `PolygonLayer`, `PolylineLayer`, `CircleLayer`, and `MarkerLayer`) will repeat their features across the layers, so that each world looks identical.

In the `PolylineLayer` & `PolygonLayer`, this can be disabled by setting the `drawInSingleWorld` property.

<div data-full-width="true"><figure><img src="../../.gitbook/assets/drawInSingleWorld disabled.png" alt=""><figcaption><p><code>drawInSingleWorld: false</code> (default)</p></figcaption></figure> <figure><img src="../../.gitbook/assets/drawInSingleWorld enabled.png" alt=""><figcaption><p><code>drawInSingleWorld: true</code></p></figcaption></figure></div>

