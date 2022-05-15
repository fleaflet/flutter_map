import 'dart:convert';
import 'dart:math';

bool randomBool() => Random().nextBool();

int randomInt([int max = 1000, bool zero = true]) =>
    min(Random().nextInt(max) + (zero ? 0 : 1), max);

double randomDouble([double max = 1000.0, bool zero = true]) =>
    min(Random().nextDouble() * max + (zero ? 0 : 1), max);

DateTime randomDateTime() =>
    DateTime.fromMillisecondsSinceEpoch(randomInt(100000));

String randomString([int max = 20]) {
  final random = Random();
  return base64Encode(
      List<int>.generate(max, (i) => random.nextInt(i + 1)).toList());
}
