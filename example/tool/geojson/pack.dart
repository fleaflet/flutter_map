import 'dart:io';
import 'dart:typed_data';

import 'package:geojson_vi/geojson_vi.dart';

Future<void> main(List<String> arguments) async {
  const inputPath = 'example/tool/geojson/138k-polygon-points.geojson.noformat';
  const outputPath = 'example/assets/polygon-stress-test-data.bin';

  const scaleFactor = 8388608;
  const bytesPerNum = 4;

  final inputFile = File(inputPath);
  final outputFile = File(outputPath);

  final inputJson = inputFile.readAsStringSync();
  outputFile.createSync(recursive: true);
  outputFile.writeAsBytes([]); // empty file

  final geojson = GeoJSONFeatureCollection.fromJSON(inputJson);

  for (final polygon in geojson.features) {
    final points =
        (polygon!.geometry! as GeoJSONMultiPolygon).coordinates[0][0];

    final numOfBytes = points.length * 2 * bytesPerNum;
    final bytes = ByteData(numOfBytes + 4);

    bytes.setUint32(0, numOfBytes);

    int i = 0;
    for (final point in points) {
      bytes.setInt32(i += bytesPerNum, (point[1] * scaleFactor).toInt()); // lat
      bytes.setInt32(i += bytesPerNum, (point[0] * scaleFactor).toInt()); // lng
    }

    outputFile.writeAsBytesSync(
      bytes.buffer.asUint8List(),
      mode: FileMode.writeOnlyAppend,
    );
  }
}
