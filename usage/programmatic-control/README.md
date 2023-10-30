# Programmatic Control

There's two ways to interact with the map - that is to control it, as well as receive data from it - and it's current viewport, aka. 'camera'.

## via User Gestures

The first way is through user interaction, where they perform gestures (such as drags/pans), and the map reacts automatically to those gestures to change the camera view of the map.

These are usually restricted by [options](../options/ "mention"). It is possible to disable all input, either by disabling all gestures, or by wrapping the map with something like `IgnorePointer`.

## via Programmatic Means

When using programmatic means, there's two methods to most things, dependent on whether the context is within a `FlutterMap` (ie. usually a layer) or not.

If within `FlutterMap`'s context, the methods usually cause automatic rebuilding. As well as the pages below, also see [#2.-hooking-into-inherited-state](../../plugins/making-a-plugin/creating-new-layers.md#2.-hooking-into-inherited-state "mention").

{% content-ref url="controller.md" %}
[controller.md](controller.md)
{% endcontent-ref %}

{% content-ref url="get-camera.md" %}
[get-camera.md](get-camera.md)
{% endcontent-ref %}

{% content-ref url="listen-to-events.md" %}
[listen-to-events.md](listen-to-events.md)
{% endcontent-ref %}
