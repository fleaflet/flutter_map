# Late Initialization Errors

{% hint style="success" %}
This class of errors appears significantly less after v2.1.0, due to the reworking of the `MapController` lifecycle.

If you are experiencing these errors, please consider updating to this version.
{% endhint %}

This class of errors is usually caused by misconfiguring `MapController`s, or using them in complex layouts.&#x20;

Should you have this error repeatedly, follow the below steps:

1. Define and assign the controller like in the example on the Controller page
2. Use `MapController.onReady` inside a `FutureBuilder` wrapped around the map widget (this should fix most issues with the map controller)
