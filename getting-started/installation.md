# Installation

## Install

{% hint style="info" %}
In the event that the `LatLng` object, provided by 'package:[latlong2](https://pub.dev/packages/latlong2)' via flutter\_map, conflicts with another, for example the one provided by Google Maps, you may need to [use the 'as' suffix](https://dart.dev/guides/packages#importing-libraries-from-packages).
{% endhint %}

### From [pub.dev](https://pub.dev/packages/flutter_map)

Just import the package as you would normally, from the command line:

<pre class="language-bash"><code class="lang-bash">flutter pub add flutter_map latlong2
flutter pub add <a data-footnote-ref href="#user-content-fn-1">flutter_map_cancellable_tile_provider</a> # OPTIONAL
</code></pre>

### From [github.com](https://github.com/fleaflet/flutter_map)

{% hint style="warning" %}
Unreleased commits from Git (GitHub) may not be stable.
{% endhint %}

If you urgently need the latest version, a specific branch, or a specific fork, you can use this method.

First, use [#from-pub.dev](installation.md#from-pub.dev "mention"), then add the following lines to your pubspec.yaml file, as a root object:

{% code title="pubspec.yaml" %}
```yaml
dependency_overrides:
    flutter_map:
        git:
            url: https://github.com/fleaflet/flutter_map.git
            # ref: master (or commit hash, branch, or tag)
```
{% endcode %}

## Additional Setup

### Web

#### Wasm/Renderer

{% hint style="success" %}
We support Wasm! [Build your app as normal](https://docs.flutter.dev/platform-integration/web/wasm) and benefit from potentially improved performance when the browser can handle Wasm.
{% endhint %}

#### CORS

On the web platform, [CORS ](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing)restrictions designed to protect resources on websites and control where they can be loaded from. Some tile servers may not be intended for external consumption, or may be incorrectly configured, which could prevent tiles from loading. If tiles load correctly on platforms other than the web, then this is likely the cause.

See the [Flutter documentation](https://docs.flutter.dev/platform-integration/web/web-images#cross-origin-resource-sharing-cors) for more details. We load images using a standard `Image` widget.

### Android

flutter\_map needs to access the Internet to load tiles, in most cases. On Android, apps must include the INTERNET permission in their manifest. Add the following line to all manifests:

{% code title="AndroidManifest.xml" %}
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
{% endcode %}

### MacOS

flutter\_map needs to access the Internet to load tiles, in most cases. On MacOS, apps must include a dedicated entitlement. Add the following lines to 'macos/Runner/DebugProfile.entitlements' and 'macos/Runner/Release.entitlement&#x73;**':**

{% code title="*.entitlements" %}
```xml
<key>com.apple.security.network.client</key>
<true/>
```
{% endcode %}

## Import

After installing the package, import it into the necessary files in your project:

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
```

{% hint style="warning" %}
You must comply with the appropriate restrictions and terms of service set by your tile server. Failure to do so may lead to any punishment, at the tile server's discretion.

This library and/or the creator(s) are not responsible for any violations you make using this package.

_The OpenStreetMap Tile Server (as used in this documentation) ToS can be_ [_found here_](https://operations.osmfoundation.org/policies/tiles)_. Other servers may have different terms._
{% endhint %}

[^1]: [#cancellablenetworktileprovider](../layers/tile-layer/tile-providers.md#cancellablenetworktileprovider "mention")
