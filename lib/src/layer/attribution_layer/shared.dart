import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:meta/meta.dart';

part 'rich/animation.dart';
part 'rich/source.dart';
part 'rich/widget.dart';
part 'simple.dart';

/// Layer widget intended to attribute a source
///
/// Implemented by [RichAttributionWidget] & [SimpleAttributionWidget].
///
/// Has no effect other than as a label to group the provided layers together
/// for the [FlutterMap.simple] constructor.
@immutable
sealed class AttributionWidget extends Widget {
  const AttributionWidget._();
}
