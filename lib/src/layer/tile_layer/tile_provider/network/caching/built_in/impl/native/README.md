# `BuiltInMapCachingProvider` storage spec

The `BuiltInMapCachingProvider`, referred to as just 'built-in caching', is implemented using the filesystem for storage on native platforms.

Cached tiles & their metadata are stored as individual keyed files. An additional file is used to improve the efficiency of tracking and reducing the cache size, called the 'size monitor'.

## Tiles

Tiles are stored in files, where the filename is the output of the supplied `cacheKeyGenerator` given the tile's URL. This defaults to a v5 UUID. Files have no extension.

Also stored alongside tiles is metadata used to perform caching, namely:

* `staleAt`: The calculated time at which the tile becomes 'stale'
* (optionally) `lastModified`: The time at which the tile was last modified on the server, based on the HTTP header
* (optionally) `etag`: A unique string identifier for the current version of that tile, using the 'etag' HTTP header

The file format is as follows:

1. The header containing the tile metadata
2. The tile image bytes (as responded by the server), no longer than 4,294,967,295 bytes

The format of the header is as follows:

1. 8-byte signed integer (Int64): the `staleAt` timestamp, represented in milliseconds since the Unix epoch in the UTC timezone
2. 8-byte signed integer (Int64)  
   * Where provided, the `lastModified` timestamp, represented in milliseconds since the Unix epoch in the UTC timezone, which must not be 0
   * Where not provided, the integer '0'
3. 2-byte unsigned integer (Uint16)  
   * Where provided, the length of the ASCII encoded `etag` in bytes
   * Where not provided, the integer '0'
4. Variable number of bytes
   * Where provided, the ASCII encoded `etag` (where each character is 7 bits but stored as 1 byte) with no greater than 65535 bytes
   * Where not provided, no bytes
5. 4-byte unsigned integer (Uint32): the length of the tile image bytes

## Size monitor

Contains an 8-byte unsigned integer (Uint64), representing the size of all tiles (including metadata) stored in the cache in bytes.

This size monitor should stay in sync with the actual size of the cache - as calculating the cache size using I/O operations is expensive and slow. Therefore, if it might go out of sync with reality for any reason (such as a detected read failure, indicating a corrupted tile likely of a different length to what is accounted for in the size monitor), then it must be disabled. Since it is only used on startup, it is recalculated using the expensive method on the next startup.

Whilst it is being calculated (which should happen on the first initialisation of the cache, or when required as above), writes must be delayed. Reads can still occur.

Named 'sizeMonitor.bin'.
