---
id: getting-started
sidebar_position: 1
---

# Getting Started

> #### UNOFFICIAL DOCUMENTATION AHEAD
>
> This documentation is not official and has not been verified or influenced by maintainers of `flutter_map`. For all documentation, use the official README at https://github.com/fleaflet/flutter_map.

`flutter_map` is a mapping package for Flutter, based off 'leaflet.js'. Simple and easy to learn, yet completely customizable and configurable, it's the best choice for Flutter if Google Maps isn't your target map.

[![Pub](https://img.shields.io/pub/v/flutter_map.svg)](https://pub.dev/packages/flutter_map) [![likes](https://badges.bar/flutter_map/likes)](https://pub.dev/packages/flutter_map/score) [![pub points](https://badges.bar/flutter_map/pub%20points)](https://pub.dev/packages/flutter_map/score)
[![CI](https://github.com/fleaflet/flutter_map/workflows/Tests/badge.svg?)](https://github.com/fleaflet/flutter_map/actions?query=branch%3Amaster) [![GitHub stars](https://img.shields.io/github/stars/fleaflet/flutter_map.svg?label=Stars)](https://GitHub.com/fleaflet/flutter_map/stargazers/) [![GitHub issues](https://img.shields.io/github/issues/fleaflet/flutter_map.svg?label=Issues)](https://GitHub.com/fleaflet/flutter_map/issues/) [![GitHub PRs](https://img.shields.io/github/issues-pr/fleaflet/flutter_map.svg?label=Pull%20Requests)](https://GitHub.com/fleaflet/flutter_map/pulls/)

### Getting Started

Installing this package is easy, and uses the normal installation method:

```shell
   > flutter pub add flutter_map
```

If you urgently need the most recent version of this package that hasn't been published to pub.dev yet, use this code snippet instead in your 'pubspec.yaml' (please note that this method is not recommended):

```yaml
flutter_map:
    git:
        url: https://github.com/fleaflet/flutter_map.git
```

On Android, you'll also need to configure your app to access the Internet. Add the following line to the manifest file located in '/android/app/src/main/AndroidManifest.xml':

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

After installing the package, import it into the necessary files in your project:

```dart
import 'package:flutter_map/flutter_map.dart';
```

### Support or Contact

Having trouble with `flutter_map`? Visit [StackOverflow](https://stackoverflow.com/search?q=flutter_map) or the [GitHub Issue Tracker](https://github.com/fleaflet/flutter_map/issues), and ask away! The community will try to get back to you as soon as possible.