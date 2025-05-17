import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:meta/meta.dart';

/// Decode the JSON within the persistent registry into a mapping of tile
/// UUIDs to their [CachedMapTileMetadata]s
///
/// If the JSON is invalid or the file cannot be read, this returns null.
@internal
HashMap<String, CachedMapTileMetadata>? persistentRegistryParserWorker(
  String persistentRegistryFilePath,
) {
  final String json;
  try {
    json = File(persistentRegistryFilePath).readAsStringSync();
  } on FileSystemException {
    return null;
  }

  final Map<String, dynamic> parsed;
  try {
    parsed = jsonDecode(json) as Map<String, dynamic>;
  } on FormatException {
    return null;
  }

  return HashMap.from(
    parsed.map(
      (key, value) => MapEntry(
        key,
        CachedMapTileMetadata.fromJson(value as Map<String, dynamic>),
      ),
    ),
  );
}
