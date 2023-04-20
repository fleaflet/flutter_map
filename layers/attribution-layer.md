# Attribution Layer

Before publishing your app to users, you should credit any sources you use, according to their Terms of Service.

There are two built in methods to provide attribution, `RichAttributionWidget` and `SimpleAttributionWidget`, but you can also build your own using a simple `Align` widget. All of these should be inserted into the map's `nonRotatedChildren`.

{% hint style="danger" %}
You must comply to your tile server's ToS. Failure to do so may result in you being banned from their services.

The OpenStreetMap Tile Server (as used above) can be [found here](https://operations.osmfoundation.org/policies/tiles). Other servers may have different terms.

This package is not responsible for your misuse of another tile server.
{% endhint %}

{% hint style="success" %}
Please consider crediting flutter\_map. It helps us to gain more awareness, which helps make this project better for everyone!
{% endhint %}

## `RichAttributionWidget`

An animated, interactive attribution layer that supports both logos/images (displayed permanently) and text (displayed in a popup controlled by an icon button adjacent to the logos).

It is heavily customizable (in both animation and contents), and designed to easily meet the needs of most ToSs out of the box.

<div>

<figure><img src="../.gitbook/assets/ClosedRichAttribution.png" alt="An icon and a button displayed over a map, in the bottom right corner"><figcaption><p>Closed <code>RichAttributionWidget</code></p></figcaption></figure>

 

<figure><img src="../.gitbook/assets/OpenedRichAttribution.png" alt="A white box with attribution text displayed over a map"><figcaption><p>Opened <code>RichAttributionWidget</code>, as in the example app</p></figcaption></figure>

</div>

```dart
nonRotatedChildren: [
  RichAttributionWidget(
    animationConfig: const ScaleRAWA(), // Or `FadeRAWA` as is default
    attributions: [
      TextSourceAttribution(
        'OpenStreetMap contributors',
        onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
      ),
    ],
  ),
],
```

For more information about configuration and all the many options this supports, see the in-code API documentation.

## `SimpleAttributionWidget`

We also provide a more 'classic' styled box, similar to those found on many web maps. These are less customizable, but might be preferred over `RichAttributionWidget` for maps with limited interactivity.

<figure><img src="../.gitbook/assets/SimpleAttribution.png" alt=""><figcaption><p><code>SimpleAttributionWidget</code>, as in the example app</p></figcaption></figure>

```dart
nonRotatedChildren: [
  SimpleAttributionWidget(
    source: Text('OpenStreetMap contributors'),
  ),
],
```
