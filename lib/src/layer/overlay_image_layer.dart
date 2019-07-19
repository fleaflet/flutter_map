import 'dart:async';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' as img;
import 'package:flutter/services.dart' as img;
import 'package:flutter/widgets.dart' as img;
import 'package:flutter/painting.dart' as img;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';

class OverlayImageLayerOptions extends LayerOptions {
  final List<OverlayImage> overlayImages;
  OverlayImageLayerOptions({this.overlayImages = const [], rebuild})
      : super(rebuild: rebuild);
}

class OverlayImage {
  final img.ImageProvider imageProvider;
  final double opacity;
  final LatLngBounds bounds;
  final List<Offset> offsets = [];
  ui.Image image;

  OverlayImage({
    this.bounds,
    this.imageProvider,
    this.opacity = 1.0,
  });
}

Future<ui.Image> _loadImage(img.ImageProvider imageProvider) async {
  var stream = imageProvider.resolve(img.ImageConfiguration.empty);
  var completer = Completer<ui.Image>();
  img.ImageStreamListener listener;
  listener =
      img.ImageStreamListener((img.ImageInfo frame, bool synchronousCall) {
    var image = frame.image;
    completer.complete(image);
    stream.removeListener(listener);
  });

  stream.addListener(listener);
  return completer.future;
}

class OverlayImageLayer extends img.StatefulWidget {
  final OverlayImageLayerOptions overlayImageOpts;
  final MapState map;
  final Stream<Null> stream;

  OverlayImageLayer(this.overlayImageOpts, this.map, this.stream);

  @override
  _OverlayImageLayerState createState() => _OverlayImageLayerState();
}

class _OverlayImageLayerState extends img.State<OverlayImageLayer> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<int>(
      stream: widget.stream, // a Stream<int> or null
      builder: (BuildContext context, _) {
        var overlayImages = <Widget>[];

        for (var overlayImageOpt in widget.overlayImageOpts.overlayImages) {
          overlayImageOpt.offsets.clear();
          var pos1 = widget.map.project(overlayImageOpt.bounds.northWest);
          pos1 = pos1.multiplyBy(widget.map.getZoomScale(widget.map.zoom, widget.map.zoom)) -
              widget.map.getPixelOrigin();
          var pos2 = widget.map.project(overlayImageOpt.bounds.southEast);
          pos2 = pos2.multiplyBy(widget.map.getZoomScale(widget.map.zoom, widget.map.zoom)) -
              widget.map.getPixelOrigin();

          overlayImageOpt.offsets
              .add(Offset(pos1.x.toDouble(), pos1.y.toDouble()));
          overlayImageOpt.offsets
              .add(Offset(pos2.x.toDouble(), pos2.y.toDouble()));
          _loadImage(overlayImageOpt.imageProvider).then((image) { 
            setState(() {
              overlayImageOpt.image = image;
            });
          });
          overlayImages.add(
            overlayImageOpt.image == null ? img.Container() : CustomPaint(
              painter: OverlayImagePainter(overlayImageOpt),
              size: size,
            ),
          );
        }

        return Container(
          child: Stack(
            children: overlayImages,
          ),
        );
      },
    );
  }
}

class OverlayImagePainter extends CustomPainter {
  final OverlayImage overlayImageOpt;
  BoxFit boxfit = BoxFit.fitWidth;
  OverlayImagePainter(this.overlayImageOpt);
  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    canvas.clipRect(rect);
    var paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, overlayImageOpt.opacity);

    var imageSize = Size(overlayImageOpt.image.width.toDouble(),
        overlayImageOpt.image.height.toDouble());
    var inputSubrect = Offset.zero & imageSize;

    canvas.drawImageRect(
        overlayImageOpt.image,
        inputSubrect,
        Rect.fromPoints(overlayImageOpt.offsets[0], overlayImageOpt.offsets[1]),
        paint);
  }

  @override
  bool shouldRepaint(OverlayImagePainter other) => false;
}
