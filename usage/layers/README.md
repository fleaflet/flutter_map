# Layers

The `children` property takes a list of widgets, usually provided by this library, called 'layers'. The following pages detail how to use these layers. Multiple layers can be stacked on top of each other, to add other functionality on top of the basic map view.

Each layer is in the format `...LayerWidget`, and takes an `options` argument which must be a `...LayerOptions`.

This widget format is useful, as other widgets can be wrapped around each layer, such as `FutureBuilder` or `StreamBuilder`, which are especially useful in non-tile layers.

{% hint style="info" %}
Many of the subpages omit the `LayerWidget` and just demonstrate the `LayerOptions` inside a `layers` parameter.

This used to be the recommended way of adding layers, and can still be used (will not be deprecated).
{% endhint %}
