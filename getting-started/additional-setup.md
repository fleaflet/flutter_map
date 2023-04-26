# Additional Setup

## Web

{% hint style="warning" %}
Always compile to web using the CanvasKit renderer instead of the HTML renderer, even on mobile devices.

Failure to do so leads to severely impacted performance. Additionally, some features may be broken - for example, tile fading doesn't work when rendering in HTML.

For more information about web renderers, see [https://docs.flutter.dev/platform-integration/web/renderers](https://docs.flutter.dev/platform-integration/web/renderers).
{% endhint %}

## Android

flutter\_map needs to access the Internet to load tiles, in most cases. On Android, apps must include the INTERNET permission in their manifest. Add the following line to all manifests.

{% code title="AndroidManifest.xml" %}
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
{% endcode %}
