// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/inherited_model.dart';
import 'package:latlong2/latlong.dart';

/// Callback to notify when the map emits a [MapEvent].
typedef MapEventCallback = void Function(MapEvent);

/// Callback to notify when the map registers a confirmed short tap gesture.
typedef TapCallback = void Function(TapPosition tapPosition, LatLng point);

/// Callback to notify when the map emits long-press gesture
typedef LongPressCallback = void Function(
  TapPosition tapPosition,
  LatLng point,
);

/// Callback to notify when the map registers a pointer down event.
typedef PointerDownCallback = void Function(
  PointerDownEvent event,
  LatLng point,
);

/// Callback to notify when the map registers a pointer up event.
typedef PointerUpCallback = void Function(PointerUpEvent event, LatLng point);

/// Callback to notify when the map registers a pointer cancel event.
typedef PointerCancelCallback = void Function(
  PointerCancelEvent event,
  LatLng point,
);

/// Callback to notify when the map registers a pointer hover event.
typedef PointerHoverCallback = void Function(
  PointerHoverEvent event,
  LatLng point,
);

/// Callback that gets called when the viewport of the map changes.
///
/// {@macro map_position.has_gesture}
typedef PositionCallback = void Function(MapCamera camera, bool hasGesture);

/// All options for the [FlutterMap] widget.
@immutable
class MapOptions {
  /// The Coordinate Reference System, defaults to [Epsg3857].
  final Crs crs;

  /// The center when the map is first loaded. If [initialCameraFit] is defined
  /// this has no effect.
  final LatLng initialCenter;

  /// The zoom when the map is first loaded. If [initialCameraFit] is defined
  /// this has no effect.
  final double initialZoom;

  /// The rotation when the map is first loaded.
  final double initialRotation;

  /// Defines the visible bounds when the map is first loaded. Takes precedence
  /// over [initialCenter]/[initialZoom].
  final CameraFit? initialCameraFit;

  /// The minimum (smallest) zoom level of every layer. Each layer can specify
  /// additional zoom level restrictions.
  final double? minZoom;

  /// The maximum (highest) zoom level of every layer. Each layer can specify
  /// additional zoom level restrictions.
  final double? maxZoom;

  /// The background color of the [FlutterMap] widget, defaults to a
  /// yellow grey-ish color.
  final Color backgroundColor;

  /// Callback that fires when the map gets tapped or clicked with the
  /// primary mouse button. This is normally the left mouse button. This
  /// callback does not fire if the gesture is recognized as a double click.
  final TapCallback? onTap;

  /// Callback that fires when the map gets tapped or clicked with the
  /// secondary mouse button. This is normally the right mouse button.
  final TapCallback? onSecondaryTap;

  /// Callback that fires when the primary pointer has remained in contact with the
  /// screen at the same location for a long period of time.
  final LongPressCallback? onLongPress;

  /// A pointer that might cause a tap has contacted the screen at a
  /// particular location.
  final PointerDownCallback? onPointerDown;

  /// A pointer that triggers a tap has stopped contacting the screen at a
  /// particular location.
  final PointerUpCallback? onPointerUp;

  /// This callback fires when the pointer that previously triggered the
  /// onTapDown won’t end up causing a tap.
  final PointerCancelCallback? onPointerCancel;

  /// Called when a pointer that has not triggered an onPointerDown
  /// changes position.
  /// This is only fired for pointers which report their location when not
  /// down (e.g. mouse pointers, but not most touch pointers)
  final PointerHoverCallback? onPointerHover;

  /// This callback fires when the [MapCamera] data has changed. This gets
  /// called if the zoom level, or map center changes.
  final PositionCallback? onPositionChanged;

  /// This callback fires on every map event that gets emitted. Check the type
  /// of [MapEvent] to distinguish between the different event types.
  final MapEventCallback? onMapEvent;

  /// Define limits for viewing the map.
  final CameraConstraint cameraConstraint;

  /// OnMapReady is called after the map runs it's initState.
  /// At that point the map has assigned its state to the controller
  /// Only use this if your map isn't built immediately (like inside FutureBuilder)
  /// and you need to access the controller as soon as the map is built.
  /// Otherwise you can use WidgetsBinding.instance.addPostFrameCallback
  /// In initState to controll the map before the next frame.
  final VoidCallback? onMapReady;

  /// Flag to enable the built in keep alive functionality
  ///
  /// If the map is within a complex layout, such as a [ListView] or [PageView],
  /// the map will reset to it's inital position after it appears back into view.
  /// To ensure this doesn't happen, enable this flag to prevent the [FlutterMap]
  /// widget from rebuilding.
  final bool keepAlive;

  /// **DEPRECATED**
  ///
  /// If necessary, manually wrap layers with `TransulcentPointer` widgets.
  ///
  /// This parameter will be removed as proper hit detection has now been
  /// incorporated into both `PolygonLayer` & `PolylineLayer`, which reduces the
  /// need for this workaround, and because it caused issues in some cases. More
  /// information about hit detection & interactivity rules can be found in the
  /// online documentation.
  ///
  /// The default of this parameter is now `false` and will use the rules above;
  /// the option is retained so as not to break APIs.
  ///
  /// This feature was deprecated (and the default changed) after v7.
  ///
  /// ---
  ///
  /// Whether to apply pointer translucency to all layers automatically
  ///
  /// This will mean that each layer can handle all the gestures that enter the
  /// map themselves. Without this, only the top layer may handle gestures.
  ///
  /// Note that layers that are visually obscured behind another layer will
  /// receive events, if this is enabled.
  ///
  /// Technically, layers become invisible to the parent `Stack` when hit
  /// testing (and thus `Stack` will keep bubbling gestures down all layers), but
  /// will still allow their subtree to receive pointer events.
  ///
  /// If this is `false` (defaults to `false`), then [TranslucentPointer] may be
  /// manually applied to individual layers.
  @Deprecated(
    'If necessary, manually wrap layers with `TransulcentPointer` widgets. '
    'This parameter will be removed as proper hit detection has now been incorporated into both `PolygonLayer` & `PolylineLayer`, which reduces the need for this workaround, and because it caused issues in some cases. More information about hit detection & interactivity rules can be found in the online documentation. '
    'The default of this parameter is now `false` and will use the rules above - the option is retained so as not to break APIs. '
    'This feature was deprecated (and the default changed) after v7.',
  )
  final bool applyPointerTranslucencyToLayers;

  /// Gesture and input options for the map widget.
  final InteractionOptions interactionOptions;

  /// Create the map options for [FlutterMap].
  const MapOptions({
    this.crs = const Epsg3857(),
    this.initialCenter = const LatLng(50.5, 30.51),
    this.initialZoom = 13.0,
    this.initialRotation = 0.0,
    this.initialCameraFit,
    this.cameraConstraint = const CameraConstraint.unconstrained(),
    this.interactionOptions = const InteractionOptions(),
    this.minZoom,
    this.maxZoom,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerCancel,
    this.onPointerHover,
    this.onPositionChanged,
    this.onMapEvent,
    this.onMapReady,
    this.keepAlive = false,
    @Deprecated(
      'If necessary, manually wrap layers with `TransulcentPointer` widgets. '
      'This parameter will be removed as proper hit detection has now been incorporated into both `PolygonLayer` & `PolylineLayer`, which reduces the need for this workaround, and because it caused issues in some cases. More information about hit detection & interactivity rules can be found in the online documentation. '
      'The default of this parameter is now `false` and will use the rules above - the option is retained so as not to break APIs. '
      'This feature was deprecated (and the default changed) after v7.',
    )
    this.applyPointerTranslucencyToLayers = false,
  });

  /// The options of the closest [FlutterMap] ancestor. If this is called from a
  /// context with no [FlutterMap] ancestor, null is returned.
  static MapOptions? maybeOf(BuildContext context) =>
      MapInheritedModel.maybeOptionsOf(context);

  /// The options of the closest [FlutterMap] ancestor. If this is called from a
  /// context with no [FlutterMap] ancestor a [StateError] will be thrown.
  static MapOptions of(BuildContext context) =>
      maybeOf(context) ??
      (throw StateError(
          '`MapOptions.of()` should not be called outside a `FlutterMap` and its descendants'));

  @override
  bool operator ==(Object other) =>
      other is MapOptions &&
      crs == other.crs &&
      initialCenter == other.initialCenter &&
      initialZoom == other.initialZoom &&
      initialRotation == other.initialRotation &&
      initialCameraFit == other.initialCameraFit &&
      minZoom == other.minZoom &&
      maxZoom == other.maxZoom &&
      backgroundColor == other.backgroundColor &&
      onTap == other.onTap &&
      onSecondaryTap == other.onSecondaryTap &&
      onLongPress == other.onLongPress &&
      onPointerDown == other.onPointerDown &&
      onPointerUp == other.onPointerUp &&
      onPointerCancel == other.onPointerCancel &&
      onPointerHover == other.onPointerHover &&
      onPositionChanged == other.onPositionChanged &&
      onMapEvent == other.onMapEvent &&
      cameraConstraint == other.cameraConstraint &&
      onMapReady == other.onMapReady &&
      keepAlive == other.keepAlive &&
      interactionOptions == other.interactionOptions &&
      backgroundColor == other.backgroundColor &&
      applyPointerTranslucencyToLayers ==
          other.applyPointerTranslucencyToLayers;

  @override
  int get hashCode => Object.hashAll([
        crs,
        initialCenter,
        initialZoom,
        initialRotation,
        initialCameraFit,
        minZoom,
        maxZoom,
        backgroundColor,
        onTap,
        onSecondaryTap,
        onLongPress,
        onPointerDown,
        onPointerUp,
        onPointerCancel,
        onPointerHover,
        onPositionChanged,
        onMapEvent,
        cameraConstraint,
        onMapReady,
        keepAlive,
        interactionOptions,
        backgroundColor,
        applyPointerTranslucencyToLayers,
      ]);
}
