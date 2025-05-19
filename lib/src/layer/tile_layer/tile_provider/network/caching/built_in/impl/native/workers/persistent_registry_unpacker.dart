import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network/caching/built_in/impl/native/flatbufs/registry.g.dart';
import 'package:meta/meta.dart';

/// Unpack the FlatBuffer registry into a mapping of tile UUIDs to their
/// [CachedMapTileMetadata]s
///
/// If the FlatBuffer file is invalid or the file cannot be read, this returns
/// null.
@internal
HashMap<String, CachedMapTileMetadata>? persistentRegistryUnpackerWorker(
  String persistentRegistryFilePath,
) {
  final Uint8List bin;
  try {
    bin = File(persistentRegistryFilePath).readAsBytesSync();
  } on FileSystemException {
    return null;
  }

  try {
    final tileMetadataMap = TileMetadataMap(bin);
    if (tileMetadataMap.entries == null) return null;

    return HashMap.fromIterable(
      tileMetadataMap.entries!,
      key: (e) => (e as TileMetadataEntry).id!,
      value: (e) {
        final metadata = (e as TileMetadataEntry).metadata!;
        return CachedMapTileMetadata(
          lastModifiedLocally:
              DateTime.fromMillisecondsSinceEpoch(metadata.lastModifiedLocally),
          staleAt: DateTime.fromMillisecondsSinceEpoch(metadata.staleAt),
          lastModified: metadata.lastModified == 0
              ? null
              : DateTime.fromMillisecondsSinceEpoch(metadata.lastModified),
          etag: metadata.etag,
        );
      },
    );
  } catch (_) {
    return null;
  }
}
