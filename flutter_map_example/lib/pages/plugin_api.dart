import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_example/widgets/drawer.dart';
import 'package:latlong/latlong.dart';

class PluginPage extends StatelessWidget {
  static const String route = "plugins";

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Plugins")),
      drawer: buildDrawer(context, PluginPage.route),
      body: new Padding(
        padding: new EdgeInsets.all(8.0),
        child: new Column(
          children: [
            new Flexible(
              child: new FlutterMap(
                options: new MapOptions(
                  center: new LatLng(51.5, -0.09),
                  zoom: 5.0,
                  plugins: [
                    new MyCustomPlugin(),
                  ],
                ),
                layers: [
                  new TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  new MyCustomPluginOptions(text: "I'm a plugin!"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyCustomPluginOptions extends LayerOptions {
  final String text;
  MyCustomPluginOptions({this.text = ""});
}

class MyCustomPlugin implements MapPlugin {
  @override
  Widget createLayer(LayerOptions options, MapState mapState) {
    if (options is MyCustomPluginOptions) {
      var style = new TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24.0,
        color: Colors.red,
      );
      return new Text(
        options.text,
        style: style,
      );
    }
    throw ("Unknown options type for MyCustom"
        "plugin: $options");
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MyCustomPluginOptions;
  }
}
