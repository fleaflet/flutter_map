# Polygon Layer

You can add areas/shapes to maps by making them out of individual coordinates using  `PolygonLayer` and `Polygon`s.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/PolygonLayer-class.html" %}

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map.plugin_api/Polygon-class.html" %}

<figure><img src="../.gitbook/assets/ExamplePolygon.png" alt=""><figcaption><p>An example <code>Polygon</code></p></figcaption></figure>

```dart
PolygonLayer(
  polygons: [
    Polygon(
      points: [LatLng(30, 40), LatLng(20, 50), LatLng(25, 45)],
      color: Colors.blue,
    ),
  ],
),
```

{% hint style="warning" %}
Due to the nature of the Earth being a sphere, drawing lines perfectly requires large amounts of difficult maths that may not behave correctly when given certain edge-cases.

Avoid creating large polygons, or polygons that cross the edges of the map, as this may create undesired results.
{% endhint %}

{% hint style="warning" %}
Excessive use of polygons may create performance issues.

Consider enabling `polygonCulling`. This will prevent the calculation and rendering of polygons outside of the current viewport, however this may not work as expected in all situations.
{% endhint %}

## Polygon Manipulation

'flutter\_map' doesn't provide any public methods to manipulate polygons, as these would be deemed out of scope.

However, some useful methods can be found in libraries such as 'latlong2' and ['poly\_bool\_dart'](https://github.com/mohammedX6/poly\_bool\_dart). These can be applied to the input of `Polygon`'s `points` argument, and the map will do it's best to try to render them. However, more complex polygons - such as those with holes - may be painted inaccurately, and may therefore require manual adjustment (of `holePointsList`, for example).

## ~~`onTap` Support~~

There is no support for handling taps on polygons, due to multiple technical challenges. To stay up to date with this existing feature request, see the linked issue.

{% embed url="https://github.com/fleaflet/flutter_map/issues/385" %}
