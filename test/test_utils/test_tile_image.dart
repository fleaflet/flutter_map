import 'dart:convert';

import 'package:flutter/painting.dart';

// Base 64 encoded 256x256 white tile.
const _whiteTile =
    'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEAAQMAAABmvDolAAAAAXNSR0IB2cksfwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAANQTFRF////p8QbyAAAAB9JREFUeJztwQENAAAAwqD3T20ON6AAAAAAAAAAAL4NIQAAAfFnIe4AAAAASUVORK5CYII=';
final testWhiteTileBytes = base64Decode(_whiteTile);
final testWhiteTileImage = MemoryImage(testWhiteTileBytes);
