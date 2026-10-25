import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// See [CursorKeyboardRotationOptions.isKeyTrigger]
typedef IsKeyCursorRotationTrigger = bool Function(LogicalKeyboardKey key);

/// The behaviour of the cursor/keyboard rotation function in terms of the angle
/// that the map is rotated to
///
/// Does not disable cursor/keyboard rotation, or adjust its triggers: see
/// [CursorKeyboardRotationOptions.isKeyTrigger].
///
/// Also see [CursorKeyboardRotationOptions.setNorthOnClick].
enum CursorRotationBehaviour {
  /// Set the North of the map to the angle at which the user drags their cursor
  setNorth,

  /// Offset the current rotation of the map to the angle at which the user drags
  /// their cursor
  offset,
}

/// Options to configure cursor/keyboard rotation
///
/// {@template cursorkeyboard_explanation}
/// Cursor/keyboard rotation is designed for desktop platforms, and allows the
/// cursor to be used to set the rotation of the map whilst a keyboard key is
/// held down (as triggered by [isKeyTrigger]).
/// {@endtemplate}
///
/// While [MapOptions.maxPitch] is above 0 and the interactive flags contain
/// [InteractiveFlag.pitch], cursor/keyboard rotation behaves as in MapLibre
/// GL JS: vertical cursor movement changes the pitch by 0.5° per logical
/// pixel, and horizontal movement rotates the map about its center. When the
/// cursor is more than 100 logical pixels above or below the center, the map
/// rotates by the angle through which the movement turns the cursor about the
/// center; otherwise it rotates by 0.8° per logical pixel. [behaviour] and
/// [setNorthOnClick] have no effect in that case.
///
/// On the web on macOS, Ctrl-click opens the browser's context menu, and the
/// map receives no cursor movement while the menu is open. In a web
/// application that sets [MapOptions.maxPitch] above 0, disable the browser's
/// context menu with `BrowserContextMenu.disableContextMenu()`.
@immutable
class CursorKeyboardRotationOptions {
  /// Whether to trigger cursor/keyboard rotation dependent on the currently
  /// pressed [LogicalKeyboardKey]
  ///
  /// By default, rotation is triggered if any key in [defaultTriggerKeys] is
  /// held (any of the "Control" keys).
  ///
  /// Fix to returning `false`, or use the
  /// [CursorKeyboardRotationOptions.disabled] constructor to disable
  /// cursor/keyboard rotation.
  final IsKeyCursorRotationTrigger? isKeyTrigger;

  /// The behaviour of the cursor/keyboard rotation function in terms of the
  /// angle that the map is rotated to
  ///
  /// Does not disable cursor/keyboard rotation, or adjust its triggers: see
  /// [isKeyTrigger].
  ///
  /// Defaults to [CursorRotationBehaviour.offset].
  final CursorRotationBehaviour behaviour;

  /// Whether to set the North of the map to the clicked angle, when the user
  /// clicks their mouse without dragging (a `onPointerDown` event
  /// followed by `onPointerUp` without a change in rotation)
  final bool setNorthOnClick;

  /// Default trigger keys used in the default [isKeyTrigger]
  static final defaultTriggerKeys = {
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
  };

  /// Create options to configure cursor/keyboard rotation
  ///
  /// {@macro cursorkeyboard_explanation}
  ///
  /// To disable cursor/keyboard rotation, fix [isKeyTrigger] to return `false`,
  /// or use the [CursorKeyboardRotationOptions.disabled] constructor instead.
  ///
  /// This constructor defaults to setting [isKeyTrigger] to triggering if any
  /// key in [defaultTriggerKeys] is held (any of the "Control" keys).
  const CursorKeyboardRotationOptions({
    this.isKeyTrigger,
    this.behaviour = CursorRotationBehaviour.offset,
    this.setNorthOnClick = true,
  });

  /// Create options to disable cursor/keyboard rotation
  ///
  /// {@macro cursorkeyboard_explanation}
  CursorKeyboardRotationOptions.disabled() : this(isKeyTrigger: (_) => false);
}
