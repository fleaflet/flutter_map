# Installation

{% hint style="success" %}
All users should also [install 'latlong2'](https://pub.dev/packages/latlong2/install) to work with coordinates in 'flutter\_map'.

In the event that the `LatLng` object provided by that library conflicts with another, for example the one provided by Google Maps, you may need to [use the 'as' suffix](https://dart.dev/guides/packages#importing-libraries-from-packages).
{% endhint %}

## From [pub.dev](https://pub.dev/packages/flutter\_map)

Just import the package as you would normally, from the command line:

<pre class="language-bash"><code class="lang-bash"><strong>flutter pub add flutter_map
</strong>flutter pub add latlong2
</code></pre>

## From [github.com](https://github.com/fleaflet/flutter\_map)

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
            # ref: main 
```
{% endcode %}

## Import

After installing the package, import it into the necessary files in your project:

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart'; // Only import if required functionality is not exposed by default
```

{% hint style="warning" %}
Before continuing with usage, make sure you comply with the appropriate rules and ToS for your server. Some have stricter rules than others. This package or the creator(s) are not responsible for any violations you make using this package.
{% endhint %}
