# Installation

## Install

{% hint style="success" %}
All users should also [install 'latlong2'](https://pub.dev/packages/latlong2/install) to work with coordinates in 'flutter\_map'.

In the event that the `LatLng` object provided by that library conflicts with another, for example the one provided by Google Maps, you may need to [use the 'as' suffix](https://dart.dev/guides/packages#importing-libraries-from-packages).
{% endhint %}

### From [pub.dev](https://pub.dev/packages/flutter\_map)

Just import the package as you would normally, from the command line:

<pre class="language-bash"><code class="lang-bash"><strong>flutter pub add flutter_map
</strong>flutter pub add latlong2
</code></pre>

### From [github.com](https://github.com/fleaflet/flutter\_map)

{% hint style="warning" %}
Commits available from Git (GitHub) may not be stable. Only use this method if you have no other choice.
{% endhint %}

If you urgently need the latest version, a specific branch, or a specific fork, you can use this method.

First, use [#from-pub.dev](installation.md#from-pub.dev "mention"), then add the following lines to your pubspec.yaml file, as a root object:

{% code title="pubspec.yaml" %}
```yaml
dependency_overrides:
    flutter_map:
        git:
            url: https://github.com/fleaflet/flutter_map.git
            # ref: main (custom branch/commit)
```
{% endcode %}

## Additional Setup

### Web

{% hint style="warning" %}
Always force usage of the CanvasKit renderer instead of the HTML renderer, even on mobile devices.

Failure to do so leads to severely impacted performance and some broken features.

For more information about web renderers, see [https://docs.flutter.dev/platform-integration/web/renderers](https://docs.flutter.dev/platform-integration/web/renderers).
{% endhint %}

### Android

flutter\_map needs to access the Internet to load tiles, in most cases. On Android, apps must include the INTERNET permission in their manifest. Add the following line to all manifests:

{% code title="AndroidManifest.xml" %}
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
{% endcode %}

### MacOS

flutter\_map needs to access the Internet to load tiles, in most cases. On MacOS, apps must include a dedicated entitlement. Add the following lines to 'macos/Runner/DebugProfile.entitlements' and 'macos/Runner/Release.entitlements**':**

{% code title="*.entitlements" %}
```xml
<key>com.apple.security.network.client</key>
<true/>
```
{% endcode %}

## Import

After installing the package, import it into the necessary files in your project:

<pre class="language-dart"><code class="lang-dart"><strong>import 'package:flutter_map/flutter_map.dart';
</strong>import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart'; // Only import if required functionality is not exposed by default
</code></pre>

{% hint style="warning" %}
Before continuing with usage, make sure you comply with the appropriate rules and ToS for your server. Some have stricter rules than others. This package or the creator(s) are not responsible for any violations you make using this package.
{% endhint %}
