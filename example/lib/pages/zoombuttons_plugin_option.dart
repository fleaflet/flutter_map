import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class ZoomButtonsPluginOption {
  final int minZoom;
  final int maxZoom;
  final bool mini;
  final double padding;
  final Alignment alignment;

  ZoomButtonsPluginOption(
      {this.minZoom = 1,
      this.maxZoom = 18,
      this.mini = true,
      this.padding = 2.0,
      this.alignment = Alignment.topRight});
}

class ZoomButtonsPlugin extends StatelessWidget {
  final ZoomButtonsPluginOption zoomButtonsOpts;
  final FitBoundsOptions options =
      const FitBoundsOptions(padding: EdgeInsets.all(12.0));

  ZoomButtonsPlugin({@required this.zoomButtonsOpts});

  @override
  Widget build(BuildContext context) {
    var map = MapStateInheritedWidget.of(context).mapState;

    return Align(
      alignment: zoomButtonsOpts.alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
                left: zoomButtonsOpts.padding,
                top: zoomButtonsOpts.padding,
                right: zoomButtonsOpts.padding),
            child: FloatingActionButton(
              heroTag: 'zoomInButton',
              mini: zoomButtonsOpts.mini,
              onPressed: () {
                var bounds = map.getBounds();
                var centerZoom = map.getBoundsCenterZoom(bounds, options);
                var zoom = centerZoom.zoom + 1;
                if (zoom < zoomButtonsOpts.minZoom) {
                  zoom = zoomButtonsOpts.minZoom as double;
                } else {
                  map.move(centerZoom.center, zoom);
                  map.rebuild();
                }
              },
              child: Icon(Icons.zoom_in),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(zoomButtonsOpts.padding),
            child: FloatingActionButton(
              heroTag: 'zoomOutButton',
              mini: zoomButtonsOpts.mini,
              onPressed: () {
                var bounds = map.getBounds();
                var centerZoom = map.getBoundsCenterZoom(bounds, options);
                var zoom = centerZoom.zoom - 1;
                if (zoom > zoomButtonsOpts.maxZoom) {
                  zoom = zoomButtonsOpts.maxZoom as double;
                } else {
                  map.move(centerZoom.center, zoom);
                  map.rebuild();
                }
              },
              child: Icon(Icons.zoom_out),
            ),
          ),
        ],
      ),
    );
  }
}
