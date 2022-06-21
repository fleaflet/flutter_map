# Additional Setup

## All Platforms

It is recommended to also [install 'latlong2'](https://pub.dev/packages/latlong2/install) to provide the `LatLng` object used throughout.

## Android

On Android, additional setup may be required. To access the Internet to reach tile servers, ensure your app is configured to use the INTERNET permission. Check (if necessary add) the following lines in the manifest file located at/android/app/src/main/AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

You may also need to do this in any other applicable manifests, such as the debug one, if not already in there.
