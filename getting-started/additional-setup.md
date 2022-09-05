# Additional Setup

## All Platforms

It is recommended to also [install 'latlong2'](https://pub.dev/packages/latlong2/install) to expose the `LatLng` object used extensively throughout.

This can then be imported like this in any required files:

```dart
import 'package:latlong2/latlong.dart';
```

{% hint style="info" %}
In the event that the `LatLng` object provided by this library conflicts with another, for example the one provided by Google Maps, you may need to [use the 'as' suffix](https://dart.dev/guides/packages#importing-libraries-from-packages).
{% endhint %}

Additionally, other plugins (see [list.md](../plugins/list.md "mention")) might require other setup and/or permissions.

## Android

On Android, additional setup may be required. To access the Internet to reach tile servers, ensure your app is configured to use the INTERNET permission. Check (and if necessary add) the following lines in the manifest file located at '/android/app/src/main/AndroidManifest.xml':

{% code title="AndroidManifest.xml" %}
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
{% endcode %}

You may also need to do this in any other applicable manifests, such as the profile one, if not already in there.
