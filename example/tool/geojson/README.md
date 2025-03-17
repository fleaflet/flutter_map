# Packed GeoJSON for the stress test

The polygon stress test relies on 138 thousand vertices to create a difficult
workload. The 138k vertices form a real-life usecase, provided as a testing
sample to the flutter_map team by a company in GeoJSON, to benchmark
performance improvements.

However, the original GeoJSON (found in this directory) has a few issues which
make it less suitable for direct use.

Therefore, the raw geometry points (from each multi-polygon contained within
the root feature collection) are packed into a custom binary format.

The purpose of the binary format is to:

* Provide size efficiency  
  The binary file is over 6x smaller, only just over 1MB. This reduces the
  assets size. Compression is out of scope. The format may lose very small
  amounts of precision on coordinate components - this is so small
  geographically, it is entirely insignificant, and allows for efficient
  integer packing.

* Provide unpacking efficiency  
  The format is simple to pack and very simple to unpack. This is more
  important than size efficiency, and therefore, compression (such as an
  adapted form of RLE, which may be very effective on the data) is not
  implemented.

* Exclude unnecessary information  
  We are only interested in the raw geometry, regardless of name or CRS. This
  also helps minimize the file size.

* Remove runtime usage of 3rd party GeoJSON parsers  
  These often go without maintainence. Additonally, these can depend on FM
  itself, or have transitive dependencies on other packages FM or the example
  uses. This simplifies FM releases, avoiding needing to override dependencies.

Packing is done by the algortithm in 'pack.dart'. It's easy to follow. Every
decimal coordinate component is scaled to be stored as an integer in 4 bytes.
This is possible because any precision losses are so geographically
insignificant at this level, and the range of values is -180 to 180. A value
for each polygon that needs to be represented is stored before the string of
integers representing its coordiantes, which indicates the number of bytes
representing that polygon.

The format, packer, and unpacker are tailored to this particular form of data.
Although the general idea will work for any GeoJSON, the packer only handles
the given input GeoJSON format/contents.

Additionally, the unpacker especially does not make any effort towards
efficient memory consumption: it is non-streaming. This is not a large problem
given the small size of the file.
