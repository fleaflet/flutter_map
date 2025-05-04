part of 'manager.dart';

/// Isolate worker which maintains its own registry and sequences writes to
/// the persistent registry
///
/// We cannot use [IOSink] from [File.openWrite], since we need to overwrite the
/// entire file on every write. [RandomAccessFile] allows this, and may also be
/// faster (especially for sync operations). However, it does not sequence
/// writes as [IOSink] does: attempting multiple writes at the same time throws
/// errors. If we use sync operations on every incoming update, this shouldn't
/// be an issue - instead, we use a debouncer (at 50ms, which is small enough
/// that the user should not usually terminate the isolate very close to loading
/// tiles, but also small enough to group adjacent tile loads), so manual
/// sequencing and locking is required.
///
/// See documentation on [MapTileCachingManager] for more info.
Future<void> _persistentRegistryWorkerIsolate(
  ({
    SendPort port,
    String persistentRegistryFilePath,
    Map<String, CachedTileInformation> initialRegistry,
  }) input,
) async {
  final registry = input.initialRegistry;
  final writer = File(input.persistentRegistryFilePath)
      .openSync(mode: FileMode.writeOnlyAppend);

  var writeLocker = Completer<void>()..complete();
  var alreadyWaitingToWrite = false;
  Future<void> write() async {
    if (alreadyWaitingToWrite) return;
    alreadyWaitingToWrite = true;
    await writeLocker.future;
    writeLocker = Completer();
    alreadyWaitingToWrite = false;

    final encoded = jsonEncode(registry);
    writer
      ..setPositionSync(0)
      ..writeStringSync(encoded)
      ..truncateSync(writer.positionSync())
      ..flushSync();

    writeLocker.complete();
  }

  Timer createWriteDebouncer() =>
      Timer(const Duration(milliseconds: 50), write);
  Timer? writeDebouncer;

  final receivePort = ReceivePort();
  input.port.send(receivePort.sendPort);

  await for (final val in receivePort) {
    final (:uuid, :tileInfo) =
        val as ({String uuid, CachedTileInformation? tileInfo});

    if (tileInfo == null) {
      registry.remove(uuid);
    } else {
      registry[uuid] = tileInfo;
    }

    writeDebouncer?.cancel();
    writeDebouncer = createWriteDebouncer();
  }
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

/// Remove tile files from the cache directory, 'first'-modified and largest
/// first, until the total size is below the set limit
///
/// Returns removed tile UUIDs.
///
/// This does not alter any registries in memory.
Future<List<String>> _limitCacheSizeWorker(
  ({
    String cacheDirectoryPath,
    String persistentRegistryFileName,
    int sizeLimit
  }) input,
) async {
  final cacheDirectory = Directory(input.cacheDirectoryPath);

  final currentCacheSize = await cacheDirectory
      .list()
      .fold(0, (sum, file) => sum + file.statSync().size);
  if (currentCacheSize <= input.sizeLimit) return [];

  final mapping =
      SplayTreeMap<DateTime, List<({File file, String uuid, int size})>>();
  bool foundManager = false;
  await for (final file in cacheDirectory.list()) {
    if (file is! File) continue;
    if (!foundManager &&
        p.basename(file.absolute.path) == input.persistentRegistryFileName) {
      foundManager = true;
      continue;
    }

    final FileStat stat;
    try {
      stat = file.statSync();
    } on FileSystemException {
      return [];
    }

    (mapping[stat.modified] ??= []) // `stat.accessed` is unreliable
        .add((file: file, uuid: p.basename(file.path), size: stat.size));
  }

  // Delete largest oldest files first
  int collectedSize = 0;
  final collectedUuids = <String>[];
  outer:
  for (final MapEntry(key: _, value: files) in mapping.entries) {
    files.sort((a, b) => b.size.compareTo(a.size));
    for (final (:file, :uuid, :size) in files) {
      collectedUuids.add(uuid);
      collectedSize += size;
      file.deleteSync();
      if (currentCacheSize - collectedSize <= input.sizeLimit) break outer;
    }
  }

  return collectedUuids;
}
