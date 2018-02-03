import 'package:fleaflet/src/core/util.dart';
import 'package:test/test.dart';

void main() {
  group('template', () {
    test('replaces', () {
      var inp = "Hello, {a}, {b}";
      var outp = template(inp, {"a": "there", "b": "world!"});
      expect(outp,equals("Hello, there, world!"));
    });
  });
}
