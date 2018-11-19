import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';

typedef MarkerMovedCallback(Marker marker, LatLng point);

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  final bool editable;
  final MarkerMovedCallback onMoved;
  MarkerLayerOptions({
    this.markers = const [],
    this.editable = false,
    this.onMoved,
    rebuild
  }) : super(rebuild: rebuild);
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
            children: _buildMarkerWidgets(context),
          ),
        );
      },
    );
  }

  List<Widget> _buildMarkerWidgets(BuildContext context) {
    var list = markerOpts.markers
        .map((marker) => markerOpts.editable ?
          EditableMarkerWidget(marker, map, markerOpts) :
          _buildMarkerWidget(context, marker)
        ).toList();
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
  final MarkerLayerOptions options;

  EditableMarkerWidget(this.marker, this.map, this.options);

  @override
  EditableMarkerWidgetState createState() => EditableMarkerWidgetState();

}

class EditableMarkerWidgetState extends State<EditableMarkerWidget> {

  LatLng _point;
  Offset _offset;

  // Borrowed gesture recognized lifetime
  // management from [Draggable] source code, see
  // https://github.com/flutter/flutter/.../widgets/drag_target.dart#L316
  int _activeCount = 0;
  PanGestureRecognizer _immediateRecognizer;

  @override
  void initState() {
    super.initState();

    _point = widget.marker.point;

    _immediateRecognizer = PanGestureRecognizer()
      ..onStart = (DragStartDetails details) {
        HapticFeedback.selectionClick();
        setState(() {
          _activeCount++;
          _offset = _translate(widget.map.latlngToOffset(_point), true);
        });
      }
      ..onUpdate = (DragUpdateDetails details) {
        setState(() {
          _offset = _offset + details.delta;
          _point = widget.map.offsetToLatLng(
              _translate(_offset, false)
          );
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
          widget.options.onMoved(
              widget.marker, _point
          );
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

  Offset _translate(Offset position, bool toLocal) {
    double dx = widget.marker._anchor.left - widget.marker.width;
    double dy = widget.marker._anchor.top - widget.marker.height;
    return position.translate(
      toLocal ? dx : -dx,
      toLocal ? dy : -dy,
    );
  }

  @override
  Widget build(BuildContext context) {

    final bool canDrag = _activeCount < 1;

    Offset offset = _translate(widget.map.latlngToOffset(_point), true);

    return Positioned(
      width: widget.marker.width,
      height: widget.marker.height,
      left: offset.dx,
      top: offset.dy,
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