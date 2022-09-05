# Map Controller Issues

{% hint style="success" %}
These issues appear significantly less after v2.1.0, due to the reworking of the `MapController` lifecycle.

If you are experiencing these errors, please consider updating to this version or later.
{% endhint %}

This class of errors is usually caused by mis-configuring `MapController`s (see [controller.md](../usage/controller.md "mention")), or using them in complex layouts.&#x20;

If you're having these issues - which can manifest as `LateInitializationError`s and/or `BadState` errors - there are a few things you can try to help out:

* Fully read the [controller.md](../usage/controller.md "mention") page, and choose the right implementation/usage for your situation.
* In complex layouts, such as with `PageView`s or `ListView`s, use the [#keep-alive-keepalive](../usage/options/recommended-options.md#keep-alive-keepalive "mention") property.
* If sharing the map controller, for example through `Provider`, make sure that the shared controller is initialised and destroyed/uninitialised at the same time as the `FlutterMap`.
