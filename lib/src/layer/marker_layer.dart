import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  MarkerLayerOptions({this.markers = const [], rebuild})
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
}

class MarkerLayer extends StatelessWidget {
  final MarkerLayerOptions markerOpts;
  final MapState map;
  final Stream<Null> stream;

  MarkerLayer(this.markerOpts, this.map, this.stream);

  Widget build(BuildContext context) {
    return new StreamBuilder<int>(
      stream: stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        return new Container(
          child: new Stack(
            children: _buildMarkers(context),
          ),
        );
      },
    );
  }

  List<Widget> _buildMarkers(BuildContext context) {
    var list = markerOpts.markers
        .where((marker) => map.bounds.contains(marker.point))
//        .map((marker) => _buildMarkerWidget(context, marker))
        .map((marker) => EditableMarkerWidget(map, marker))
        .toList();
    return list;
  }

  Widget _buildMarkerWidget(BuildContext context, Marker marker) {

    Offset offset = map.latlngToOffset(marker.point).translate(
        marker._anchor.left - marker.width,
        marker._anchor.top - marker.height
    );

    return new Positioned(
      width: marker.width,
      height: marker.height,
      left: offset.dx,
      top: offset.dy,
      child: marker.builder(context),
    );
  }

}



class EditableMarkerWidget extends StatefulWidget {
  final MapState map;
  final Marker marker;

  EditableMarkerWidget(this.map, this.marker);

  @override
  EditableMarkerWidgetState createState() => EditableMarkerWidgetState();

}

class EditableMarkerWidgetState extends State<EditableMarkerWidget> {

  Point _origin;
  Offset _position = Offset.zero;

  // Borrowed gesture recognized lifetime
  // management from [Draggable] source code, see
  // https://github.com/flutter/flutter/.../widgets/drag_target.dart#L316
  PanGestureRecognizer _immediateRecognizer;
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _origin = widget.map.getPixelOrigin();
    _position = _translate(
        widget.map.latlngToOffset(widget.marker.point)
    );
    _immediateRecognizer = PanGestureRecognizer()
      ..onStart = (DragStartDetails details) {
        HapticFeedback.selectionClick();
        setState(() {
          _activeCount++;
        });
      }
      ..onUpdate = (DragUpdateDetails details) {
        setState(() {
          _position = _position + details.delta;
        });
      }
      ..onCancel = () {
        setState(() {
          _activeCount--;
        });
      }
      ..onEnd = (DragEndDetails details) {
        setState(() {
          _activeCount--;
        });
      };

  }


  @override
  void dispose() {
    super.dispose();
    _disposeRecognizerIfInactive();
  }

  void _disposeRecognizerIfInactive() {
    if (_activeCount > 0)
      return;
    _immediateRecognizer.dispose();
    _immediateRecognizer = null;
  }

  Offset _translate(Offset position) {
    return position.translate(
      widget.marker._anchor.left - widget.marker.width,
      widget.marker._anchor.top - widget.marker.height
    );
  }

  @override
  Widget build(BuildContext context) {

    Point point = widget.map.getPixelOrigin();

    if(!(_origin == point)) {
      _position = _position.translate(
          (_origin.x - point.x).toDouble(),
          (_origin.y - point.y).toDouble()
      );
      _origin = point;
    }

    final bool canDrag = _activeCount < 1;

    return Positioned(
      width: widget.marker.width,
      height: widget.marker.height,
      left: _position.dx,
      top: _position.dy,
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          if(canDrag) {
            _immediateRecognizer.addPointer(event);
          }
        },
        child: widget.marker.builder(context),
      ),
    );
  }
}