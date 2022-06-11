import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

class AnimatedTile extends StatefulWidget {
  final Tile tile;
  final ImageProvider? errorImage;
  final TileBuilder? tileBuilder;

  const AnimatedTile({
    Key? key,
    required this.tile,
    this.errorImage,
    required this.tileBuilder,
  }) : super(key: key);

  @override
  State<AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<AnimatedTile> {
  bool listenerAttached = false;

  @override
  Widget build(BuildContext context) {
    final tileWidget = (widget.tile.loadError && widget.errorImage != null)
        ? Image(
            image: widget.errorImage!,
            fit: BoxFit.fill,
          )
        : RawImage(
            image: widget.tile.imageInfo?.image,
            fit: BoxFit.fill,
            opacity: widget.tile.animationController);

    return widget.tileBuilder == null
        ? tileWidget
        : widget.tileBuilder!(context, tileWidget, widget.tile);
  }

  @override
  void initState() {
    super.initState();

    if (null != widget.tile.animationController) {
      widget.tile.animationController!.addListener(_handleChange);
      listenerAttached = true;
    }
  }

  @override
  void dispose() {
    if (listenerAttached) {
      widget.tile.animationController?.removeListener(_handleChange);
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listenerAttached && null != widget.tile.animationController) {
      widget.tile.animationController!.addListener(_handleChange);
      listenerAttached = true;
    }
  }

  void _handleChange() {
    if (mounted) {
      setState(() {});
    }
  }
}
