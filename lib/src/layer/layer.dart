/// Common type between all LayerOptions.
///
/// All LayerOptions have access to a stream that notifies when the map needs
/// rebuilding.
class LayerOptions {
  Stream<Null> rebuild;
  LayerOptions({this.rebuild});
}
