# Installation

## From [pub.dev](https://pub.dev/packages/flutter\_map)

This is the recommended method of installing this package as it ensures you only receive stable versions, and you can be sure pub.dev is reliable. It also keeps the size of your pubspec.yaml small.

Just import the package as you would normally, from the command line:

```shell
flutter pub add flutter_map
```

{% hint style="success" %}
This should automatically import the latest version of the package and create an entry for it in your pubspec.yaml. Otherwise follow the old method and add the latest version of the 'flutter\_map' dependency to the pubspec.yaml manually.
{% endhint %}

## From [github.com](https://github.com/fleaflet/flutter\_map)

If you urgently need the latest version, a specific branch, or a specific fork, you can use this method.

{% hint style="warning" %}
Commits available from Git (GitHub) may not be stable. Only use this method if you have no other choice.
{% endhint %}

Add the following lines to your pubspec.yaml file, as a root object:

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
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:flutter_map/plugin_api.dart'; // Only import if required functionality is not exposed by default
```

{% hint style="success" %}
This package should now be mostly setup! Make sure you follow through with the appropriate [Additional Setup](broken-reference) instructions for your platform.

Before continuing with usage, make sure you comply with the appropriate rules and ToS for your server. Some have stricter rules than others. This package or the creator(s) are not responsible for any violations you make using this package.
{% endhint %}
