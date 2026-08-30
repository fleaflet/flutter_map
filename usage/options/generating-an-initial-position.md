---
tags:
  - tag: guided
    primary: true
---

# Generating An Initial Position

How to pick an initial position for the map? It has a large impact on user experience, and can be the difference between seamless usage and friction every time your app starts - so it's important to get right.

Consider what purpose the map serves, as the user will have different expectations depending on the purpose.

<details>

<summary>Static map?</summary>

This guide deals primarily with interactive maps. If you have a static map which needs to be positioned based on information from an external source, see [#initial-positioning](./#initial-positioning "mention"). To make the map non-interactive, an `IgnorePointer` widget can wrap the map, and the [`InteractionOptions`](interaction-options.md) can be set to disable all other interactions that might sneak through.

</details>

If your map is interactive, minimizing the amount of effort needed to focus on the area of interest is important. Showing the map quickly and without interruption is also important, and so the generation should be quick and invisible.

{% hint style="warning" %}
Thinking about using the device's location APIs? Remember:

* It is often against app store rules, and bad practise anyway, to request location permissions without the user first requesting the functionality
* Users can deny access to location permissions at any time
* Getting a location fix can take a while, and is battery-intensive
* A faulty permission flow can cause extremely bad experiences and distrust
{% endhint %}

This guide has been created to show examples of 3 good practise methods, which work together to create a good user experience. Examples are given to help build this into your project throughout.

#### Remembering the last position

To create functionality where the map opens to where the user last left it:

* Register an event handler (see [#reacting-to-map-events](../programmatic-interaction.md#reacting-to-map-events "mention") for more information)
* Use a persistence solution like [shared\_preferences](https://pub.dev/packages/shared_preferences) to store the new position when necessary
* Asynchronously load the persisted data into memory before loading the map, ideally a long time before (such as a splash screen), then retrieve it from memory when building the map - falling back to a different solution or fixed values if unavailable

The easiest and most performant way to store the new position when necessary is to store it only when a move gesture finishes, as shown in the example below. Alternatively, `MapOptions.onPositionChanged` could be used with a debounce mechanism.

```dart
// This example assumes `sharedPrefs` was loaded into memory asynchronously already.
// For the best user experience, this should be invisible, and so built into the
// initial app load/splash screen rather than a dedicated loader for the map screen,
// since it is usually fairly quick to load small amounts of persisted data.

MapOptions(
    initialCenter: LatLng(
        sharedPrefs.getDouble('map.lastLocation.lat') ?? 0,
        sharedPrefs.getDouble('map.lastLocation.lng') ?? 0,
    ),
    initialZoom: sharedPrefs.getDouble('map.lastLocation.zoom') ?? 1,
    onMapEvent: (evt) {
        // Currently, all the move end events must be checked individually
        if (evt is MapEventMoveEnd ||
            evt is MapEventFlingAnimationEnd ||
            evt is MapEventFlingAnimationNotStarted) {
            sharedPrefs
              ..setDouble('map.lastLocation.lat', evt.camera.center.latitude)
              ..setDouble('map.lastLocation.lng', evt.camera.center.longitude)
              ..setDouble('map.lastLocation.zoom', evt.camera.zoom);
        }
    },
),
```

#### Approximating the user's location without permissions

To provide a better UX, particularly on the first app load when the stored last location (as described above) is most likely to be missing, fallback to another approximation rather than a fixed value (as shown in the example above). We must use a source that is provided by almost all devices and is invisible to users - such as locale information.

{% hint style="info" %}
If you have the user pick their country of interest in the onboarding, you could also use that as the source instead.
{% endhint %}

Because it is used to provide localisation, it is not restricted by the system. It is only very approximate - it reveals a country, and can be incorrect if the user's locale set does not match their true locale - but it is better than a fixed fallback.

Flutter exposes the user's locale and country code through the `PlatformDispatcher`. The country code (if available) can be retrieved using the following code:

{% code title="approximate_country_bbox.dart" expandable="true" %}
```dart
Future<LatLngBounds?> approximateCountryBbox() async {
    if (WidgetsBinding.instance.platformDispatcher.locale.countryCode
            case final countryCode?) {
        // ...
    }
    
    // If no country code is available, we must fallback to a fixed value
    return null;
}
```
{% endcode %}

Then, the country code needs to be converted into a bounding box of the country. This can be done quickly and offline by shipping a tiny data file as an asset with the app.&#x20;

At the time of writing, such a file is already compiled from [Natural Earth](http://www.naturalearthdata.com/) and available as a public domain JSON file:

{% hint style="warning" %}
There is no guarantee that this file is accurate.
{% endhint %}

{% embed url="https://github.com/sandstrom/country-bounding-boxes/blob/master/bounding-boxes.json" %}

Once included as an asset, the following can be inserted into the block from above to generate a `LatLngBounds`:

{% code title="approximate_country_bbox.dart" %}
```dart
final countryBboxs = jsonDecode(
  // This requires the method to be in a `StatefulWidget`, or accept a `BuildContext`
  // as an argument
  await DefaultAssetBundle.of(context).loadString('assets/data/country_bboxs.json'),
) as Map;

if (countryBboxs[countryCode.toUpperCase()] case final country?) {
  // The dataset values are in the format `[FriendlyCountryName, [λ1, φ1, λ2, φ2]]`
  final bboxValues = ((country as List)[1] as List).cast<double>();
  return LatLngBounds(
    LatLng(bboxValues[1], bboxValues[0]),
    LatLng(bboxValues[3], bboxValues[2]),
  );
}

// If the dataset does not contain the country code, fallback
return null;
```
{% endcode %}

Because the loading of the data file is asynchronous, this either needs to be run invisibly (such as during a splash screen), or a loader is required (such as a `FutureBuilder`) - but because the file is so small, this will usually be very quick.

This can then be integrated as a fallback to the 'last known position' method, if the persisted values are unavailable or `null`.

#### Using location APIs

In some cases, such as for navigation apps, the most useful and most accurate initial position will be the user's physical location.&#x20;

When using this method, a marker can also be shown on the map at the user's location to give some additional feedback and clarity.

As discussed above, these APIs are not guaranteed to be useable, can be unreliable, and are likely to be slow. Therefore, it is good practise to position the map using another method quickly, then use this method in the background.

If it is clear to the user that their location is loading - such as a loading indicator on a button, or a greyed out marker at the user's last known location - and the loading can be interrupted - for example with any manual gesture on the map - then this is a good UX pattern. Although, an automated map move after loading can be jarring, so it may be beneficial to require the user to press a button before using the location to position the map (unless it is expected, such as an explicit navigation flow).

Because of the complexity of this method, it is not described here.

A community maintained plugin, [flutter\_map\_location\_marker](https://github.com/tlserver/flutter_map_location_marker), provides a prebuilt marker and map movement logic. Even/especially when using this plugin, take care with permission handling logic, using a package like [permission\_handler](https://pub.dev/packages/permission_handler) is recommended. UX can suffer greatly if permission request flows are buggy.

