part of 'manager.dart';

/// Isolate worker which maintains its own registry and sequences writes to
/// the persistent registry
///
/// See documentation on [TileCachingManager] for more info.
Future<void> _persistentRegistryWorkerIsolate(
  ({
    SendPort port,
    String persistentRegistryFilePath,
    Map<String, CachedTileInformation> initialRegistry,
  }) input,
) async {
  final registry = input.initialRegistry;

  final writer =
      File(input.persistentRegistryFilePath).openSync(mode: FileMode.writeOnly);

  final receivePort = ReceivePort();
  final incomingRegistryUpdates = StreamIterator(
    receivePort.map((val) {
      final (:uuid, :tileInfo) =
          val as ({String uuid, CachedTileInformation? tileInfo});

      if (tileInfo == null) {
        registry.remove(uuid);
        return null;
      }
      registry[uuid] = tileInfo;
      return null;
    }),
  );

  input.port.send(receivePort.sendPort);

  while (await incomingRegistryUpdates.moveNext()) {
    final encoded = jsonEncode(registry);
    writer.setPositionSync(0);
    writer.writeStringSync(encoded);
    writer.flushSync();
  }

  writer.closeSync();
}

/// Decode the JSON within the persistent registry into a mapping of tile
/// UUIDs to their [CachedTileInformation]s
///
/// Should be used within an isolate/[compute]r.
///
/// If the JSON is invalid or the file cannot be read, this returns null.
HashMap<String, CachedTileInformation>? _parsePersistentRegistryWorker(
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
        CachedTileInformation.fromJson(value as Map<String, dynamic>),
      ),
    ),
  );
}
