import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/editable_point.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';

typedef void MarkerMovedCallback(Marker marker, LatLng point);

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  final bool editable;
  final MarkerMovedCallback onMoved;
  MarkerLayerOptions(
      {this.markers = const [], this.editable = false, this.onMoved, rebuild})
      : super(rebuild: rebuild);
}

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorAlign alignOpt)
      : left = _leftOffset(width, alignOpt),
        top = _topOffset(width, alignOpt);

  static double _leftOffset(double width, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.left:
        return 0.0;
      case AnchorAlign.right:
        return width;
      case AnchorAlign.top:
      case AnchorAlign.bottom:
      case AnchorAlign.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.top:
        return 0.0;
      case AnchorAlign.bottom:
        return height;
      case AnchorAlign.left:
      case AnchorAlign.right:
      case AnchorAlign.center:
      default:
        return height / 2;
    }
  }

  factory Anchor._forPos(AnchorPos pos, double width, double height) {
    if (pos == null) return Anchor._(width, height, null);
    if (pos.value is AnchorAlign) return Anchor._(width, height, pos.value);
    if (pos.value is Anchor) return pos.value;
    throw Exception('Unsupported AnchorPos value type: ${pos.runtimeType}.');
  }
}

class AnchorPos<T> {
  AnchorPos._(this.value);
  T value;
  static AnchorPos exactly(Anchor anchor) => AnchorPos._(anchor);
  static AnchorPos align(AnchorAlign alignOpt) => AnchorPos._(alignOpt);
}

enum AnchorAlign {
  left,
  right,
  top,
  bottom,
  center,
}

class Marker {
  final LatLng point;
  final WidgetBuilder builder;
  final double width;
  final double height;
  final Anchor anchor;

  Marker({
    this.point,
    this.builder,
    this.width = 30.0,
    this.height = 30.0,
    AnchorPos anchorPos,
  }) : this.anchor = Anchor._forPos(anchorPos, width, height);


  Marker from(LatLng point) {
    return Marker(
      point: point,
      builder: builder,
      width: width,
      height: height,
      anchorPos: AnchorPos.exactly(anchor),
    );
  }

}

class MarkerLayer extends StatelessWidget {
  final MarkerLayerOptions markerOpts;
  final MapState map;
  final Stream<Null> stream;

  final List<LatLng> points = [];

  MarkerLayer(this.markerOpts, this.map, this.stream);

  Widget build(BuildContext context) {
    return new StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        return new Container(
          child: new Stack(
            children: _buildMarkerWidgets(context),
          ),
        );
      },
    );
  }

  List<Widget> _buildMarkerWidgets(BuildContext context) {

    points.addAll(markerOpts.markers.map((marker) => marker.point).toList());

    int i = 0;
    return markerOpts.markers
        .map((marker) => markerOpts.editable
            ? EditableMarkerWidget(i++, points, map, markerOpts)
            : _buildMarkerWidget(context, marker))
        .toList();
  }

  Widget _buildMarkerWidget(BuildContext context, Marker marker) {
    Offset offset = map.latlngToOffset(marker.point).translate(
        marker.anchor.left - marker.width, marker.anchor.top - marker.height);

    return new Positioned(
      width: marker.width,
      height: marker.height,
      left: offset.dx,
      top: offset.dy,
      child: marker.builder(context),
    );
  }
}

class EditableMarkerWidget extends EditablePointWidget {
  final MapState map;
  final int index;
  final List<LatLng> points;
  final MarkerLayerOptions options;

  EditableMarkerWidget(this.index, this.points, this.map, this.options) :
    super(
      map: map,
        size: Size(options.markers[index].width, options.markers[index].height),
        builder: options.markers[index].builder,
        translate: (Offset position, bool toLocal) {
          double dx = options.markers[index].anchor.left - options.markers[index].width;
          double dy = options.markers[index].anchor.top - options.markers[index].height;
          return position.translate(
            toLocal ? dx : -dx,
            toLocal ? dy : -dy,
          );
        },
        index: index,
        points: points,
        onDragUpdate: (int index, LatLng point) {
          points[index] = point;
          options.markers[index] = options.markers[index].from(point);
          options.onMoved(options.markers[index], point);
        }
    );


}

