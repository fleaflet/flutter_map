# Programmatic Interaction

There's two ways to interact with the map - that is to control it, as well as receive data from it - and it's current viewport, aka. 'camera'.

## via User Gestures

The first way is through user interaction, where they perform gestures (such as drags/pans), and the map reacts automatically to those gestures to change the camera view of the map.

These are usually restricted by [options](../options/ "mention"). It is possible to disable all input, either by disabling all gestures, or by wrapping the map with something like `IgnorePointer`.

## via Programmatic Interation

However, the map camera can also be controlled by calling methods on a controller, and its state read by getting values from an exposed camera.

{% hint style="warning" %}
Changing the state of `MapOptions.initial*` will not update the map camera. It may only be updated through a `MapController`.
{% endhint %}

For more information, see:

{% content-ref url="controller.md" %}
[controller.md](controller.md)
{% endcontent-ref %}
