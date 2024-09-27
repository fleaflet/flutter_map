/// # flutter_map
///
/// A versatile mapping package for Flutter. Simple and easy to learn, yet
/// completely customizable and configurable, it's the best choice for mapping in
/// your Flutter app.
///
/// ---
///
/// * Documentation: <https://docs.fleaflet.dev/>
/// * API Reference: <https://pub.dev/documentation/flutter_map/latest/>
///
/// ---
///
/// * github.com: <https://github.com/fleaflet/flutter_map>
/// * pub.dev: <https://pub.dev/packages/flutter_map>
/// * discord.gg: <https://discord.gg/BwpEsjqMAH>
library;

export 'package:flutter_map/src/geo/crs.dart' hide CrsWithStaticTransformation;
export 'package:flutter_map/src/geo/latlng_bounds.dart';
export 'package:flutter_map/src/gestures/interactive_flag.dart';
export 'package:flutter_map/src/gestures/latlng_tween.dart';
export 'package:flutter_map/src/gestures/map_events.dart';
export 'package:flutter_map/src/gestures/multi_finger_gesture.dart';
export 'package:flutter_map/src/gestures/positioned_tap_detector_2.dart';
export 'package:flutter_map/src/layer/attribution_layer/rich/animation.dart';
export 'package:flutter_map/src/layer/attribution_layer/rich/source.dart';
export 'package:flutter_map/src/layer/attribution_layer/rich/widget.dart';
export 'package:flutter_map/src/layer/attribution_layer/simple.dart';
export 'package:flutter_map/src/layer/circle_layer/circle_layer.dart';
export 'package:flutter_map/src/layer/marker_layer/marker_layer.dart';
export 'package:flutter_map/src/layer/overlay_image_layer/overlay_image_layer.dart';
export 'package:flutter_map/src/layer/polygon_layer/polygon_layer.dart';
export 'package:flutter_map/src/layer/polyline_layer/polyline_layer.dart';
export 'package:flutter_map/src/layer/scalebar/scalebar.dart';
export 'package:flutter_map/src/layer/shared/layer_interactivity/layer_hit_notifier.dart';
export 'package:flutter_map/src/layer/shared/layer_interactivity/layer_hit_result.dart';
export 'package:flutter_map/src/layer/shared/line_patterns/stroke_pattern.dart';
export 'package:flutter_map/src/layer/shared/mobile_layer_transformer.dart';
export 'package:flutter_map/src/layer/shared/translucent_pointer.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_builder.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_display.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_image.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_provider/asset_tile_provider.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_provider/file_providers/tile_provider_stub.dart'
    if (dart.library.io) 'package:flutter_map/src/layer/tile_layer/tile_provider/file_providers/tile_provider_io.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_provider/network_tile_provider.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_update_event.dart';
export 'package:flutter_map/src/layer/tile_layer/tile_update_transformer.dart';
export 'package:flutter_map/src/map/camera/camera.dart';
export 'package:flutter_map/src/map/camera/camera_constraint.dart';
export 'package:flutter_map/src/map/camera/camera_fit.dart';
export 'package:flutter_map/src/map/controller/map_controller.dart';
export 'package:flutter_map/src/map/controller/map_controller_impl.dart';
export 'package:flutter_map/src/map/options/cursor_keyboard_rotation.dart';
export 'package:flutter_map/src/map/options/interaction.dart';
export 'package:flutter_map/src/map/options/options.dart';
export 'package:flutter_map/src/map/widget.dart';
export 'package:flutter_map/src/misc/bounds.dart';
export 'package:flutter_map/src/misc/extensions.dart';
