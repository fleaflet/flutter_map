part of 'marker_layer.dart';

/// A container for a [child] widget located at a geographic coordinate [point]
///
/// Some properties defaults will absorb the values from the parent
/// [MarkerLayer], if the reflected properties are defined there.
/// [alignment] may be computed using [computePixelAlignment].
@immutable
class Marker {
  /// Provide an optional [Key] for the [Marker].
  /// This key will get passed through to the created marker widget.
  final Key? key;

  /// Coordinates of the marker.
  ///
  /// This will be the center of the marker, assuming that [alignment] is
  /// [Alignment.center] (default).
  final LatLng point;

  /// Widget tree of the marker, sized by [width] & [height].
  ///
  /// The [Marker] itself is not a widget.
  final Widget child;

  /// Width dimension of child, in pixels (unless [useDimensionsInMeters] is
  /// set).
  final double width;

  /// Height dimension of child, in pixels (unless [useDimensionsInMeters] is
  /// set).
  final double height;

  /// Whether to treat [width] and [height] as meters, with optional pixel size
  /// constraints.
  ///
  /// If `null` (as default), [width] and [height] are specified in pixels.
  ///
  /// If set to [BoxConstraints], [width] and [height] are specified in meters.
  /// These [BoxConstraints] are in pixels, and constrain the screen size of the
  /// child.
  ///
  /// Set an empty [BoxConstraints] to display the child in meters without
  /// constraints (true size):
  ///
  /// ```dart
  ///   useDimensionsInMeters: const BoxConstraints(),
  /// ```
  ///
  /// Any constraints set must have finite minimum dimensions.
  ///
  /// When using meters, the child can use [SizedBox.expand] to expand itself to
  /// the available size. [LayoutBuilder] can be used to obtain the calculated
  /// screen size, if necessary.
  ///
  /// Note that this is an approximation. To be accurate, the marker child would
  /// need to be warped. This will require a custom implementation.
  final BoxConstraints? useDimensionsInMeters;

  /// Alignment of the marker relative to the normal center at [point].
  ///
  /// For example, [Alignment.topCenter] will mean the entire marker widget is
  /// located above the [point].
  ///
  /// The center of rotation (anchor) will be opposite this.
  ///
  /// Defaults to [Alignment.center] if also unset by [MarkerLayer].
  final Alignment? alignment;

  /// Whether to counter rotate this marker to the map's rotation, to keep a
  /// fixed orientation.
  ///
  /// When `true`, this marker will always appear upright and vertical from the
  /// user's perspective. Defaults to `false` if also unset by [MarkerLayer].
  ///
  /// Note that this is not used to apply a custom rotation in degrees to the
  /// marker. Use a widget inside [child] to perform this.
  final bool? rotate;

  /// Creates a container for a [child] widget located at a geographic coordinate
  /// [point]
  ///
  /// Some properties defaults will absorb the values from the parent
  /// [MarkerLayer], if the reflected properties are defined there.
  const Marker({
    this.key,
    required this.point,
    required this.child,
    this.width = 30,
    this.height = 30,
    this.useDimensionsInMeters,
    this.alignment,
    this.rotate,
  });

  /// Returns the alignment of a [width]x[height] rectangle by [left]x[top]
  /// pixels.
  static Alignment computePixelAlignment({
    required final double width,
    required final double height,
    required final double left,
    required final double top,
  }) =>
      Alignment(
        1.0 - 2 * left / width,
        1.0 - 2 * top / height,
      );
}
