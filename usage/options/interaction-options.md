# Interaction Options

The `InteractionOptions` object passed to `MapOptions.interactiveOptions` configures the gestures that the user can use to interact with the map. For example, disable rotation or configure cursor/keyboard rotation.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/InteractionOptions-class.html" %}

## Flags

`flags` is a [bitfield](https://en.wikipedia.org/wiki/Bit_field) that enables and disables the vast majority of gestures. Although technically the type is of `int`, it is usually set with a combination of `InteractiveFlag`s.

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/InteractiveFlag-class.html" %}

{% hint style="warning" %}
Note that some gestures must be configured by other means, either instead of using flags, or in addition to.
{% endhint %}

By default, `all` gestures are enabled, but a non-interactive map can be created using `none` (and other options in addition).

{% hint style="info" %}
The recommended way to create an entirely non-interactive map is to wrap the `FlutterMap` widget in an `IgnorePointer` widget.
{% endhint %}

Otherwise, to set flags, there's two methods:

* Add flags, with the bitwise 'OR' (`|`) operator in-between\
  For example, `InteractiveFlag.drag | InteractiveFlag.rotate`
* Remove flags from `all`, using the `&` and `~` operators in-between\
  For example, `InteractiveFlag.all & ~InteractiveFlag.rotate`

## Cursor/Keyboard Rotation

Cursor/keyboard rotation is designed for desktop platforms, and allows the cursor to be used to set the rotation of the map whilst a (customizable) keyboard key (by default, any of the 'Control' keys) is held down.

The `CursorKeyboardRotationOptions` object passed to the property with the corresponding name configures this behaviour. The `CursorKeyboardRotationOptions.disabled()` constructor can be used to disable cursor/keyboard rotation.

There's many customization options, see the API docs for more information:

{% embed url="https://pub.dev/documentation/flutter_map/latest/flutter_map/CursorKeyboardRotationOptions-class.html" %}

## Keyboard Gestures

Keyboard gestures can be configured through `KeyboardOptions`. By default, the map can be panned via the arrow keys. Additionally, panning using the WASD keys can be enabled, as well as rotation with Q & E, and zooming with R & F. All keys are physical and based on the QWERTY keyboard, so on other keyboards, the positions will be the same, not necessary the characters.

Leaping occurs when the trigger key is pressed momentarily instead of being held down. This can also be customized.

## "Win" Gestures

{% hint style="warning" %}
This is advanced behaviour that affects how gestures 'win' in the gesture arena, and does not usually need changing.
{% endhint %}
