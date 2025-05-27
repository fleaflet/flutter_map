# Layers

Creating a new map layer is a great way to achieve a more custom, performant, map design. For example, it might be used to display a scale bar, or overlay a grid.

## 1. Creating A Layer Widget

It starts with a normal `StatelessWidget` or `StatefulWidget`, which then starts its widget tree with a widget dependent on whether the layer is designed to be either 'mobile' or 'static', depending on the purpose of the layer. For more information, see [#mobile-vs-static-layers](../../usage/layers.md#mobile-vs-static-layers "mention").

{% tabs %}
{% tab title="Mobile Layers" %}
```dart
class CustomMobileLayer extends StatelessWidget {
  const CustomMobileLayer({super.key});

  @override
  Widget build(BuildContext context) {    
    return MobileLayerTransformer(
      child: // your child here
    );
  }
}
```
{% endtab %}

{% tab title="Static Layers" %}
```dart
class CustomStaticLayer extends StatelessWidget {
  const CustomStaticLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand();
    // and/or
    return Align();
  }
}
```
{% endtab %}
{% endtabs %}

## 2. Hooking Into Inherited State

Then, there are three possible methods that could be used to retrieve separate 'aspects' of the state of the map.

Calling these inside a `build` method will also cause the layer to rebuild automatically when the depended-on aspects change.

```dart
final camera = MapCamera.of(context);
final controller = MapController.of(context);
final options = MapOptions.of(context);
```

{% hint style="warning" %}
Using these methods will restrict this widget to only being usable inside the context of a `FlutterMap`.
{% endhint %}
