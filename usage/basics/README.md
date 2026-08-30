# Base Widget

```dart
FlutterMap(
    options: MapOptions(),
    children: [],
);
```

{% stepper %}
{% step %}
### Configure the map

{% content-ref url="../options/" %}
[options](../options/)
{% endcontent-ref %}
{% endstep %}

{% step %}
### Add some layers

{% content-ref url="../layers.md" %}
[layers.md](../layers.md)
{% endcontent-ref %}
{% endstep %}
{% endstepper %}

{% hint style="info" %}
The map widget will expand to fill its constraints.

To avoid errors about infinite/unspecified sizes, ensure the map is contained within a constrained widget.
{% endhint %}
