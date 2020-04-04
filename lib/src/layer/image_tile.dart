import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:transparent_image/transparent_image.dart';

typedef DownloadListener = void Function(Coords downloadedCoords);

class ImageTile extends StatefulWidget {

  final TileLayerOptions options;
  final Coords coords;
  final Size size;
  final DownloadListener listener;

  const ImageTile({Key key, this.options, this.coords, this.size, this.listener}) : super(key: key);

  @override
  _ImageTileState createState() => _ImageTileState();
}

class _ImageTileState extends State<ImageTile> {

  bool _isDownloaded = false;
  ImageInfo _imageInfo;
  ImageProvider _provider;
  ImageStream _stream;

  @override
  void initState() {
    super.initState();
    _provider = widget.options.tileProvider.getImage(widget.coords, widget.options);
    _stream = _provider.resolve(ImageConfiguration(size: widget.size));
    _stream.addListener(ImageStreamListener(_updateImage));
  }

  @override
  void dispose() {
    _stream.removeListener(ImageStreamListener(_updateImage));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: _isDownloaded
          ? ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: RawImage(
          image: _imageInfo?.image,
          fit: BoxFit.fill,
        ),
      )
          : Image(image: MemoryImage(kTransparentImage)),
    );
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    widget.listener(widget.coords);
    setState(() {
      _isDownloaded = true;
      _imageInfo = imageInfo;
    });
  }
}
