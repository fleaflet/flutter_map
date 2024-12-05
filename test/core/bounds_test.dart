import 'dart:math';

import 'package:flutter_map/src/misc/bounds.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/core.dart';

void main() {
  group('Bounds', () {
    test(
        'should create bounds with minimum point equal to minimum argument '
        'if maximum argument point is positioned higher', () {
      final bounds = IntegerBounds(const Point(1, 2), const Point(3, 4));

      expect(bounds.min.x, equals(1.0));
      expect(bounds.min.y, equals(2.0));
    });

    test(
        'should create bounds with minimum point equal to maximum argument '
        'if maximum argument point is positioned lower', () {
      final bounds = IntegerBounds(const Point(3, 4), const Point(1, 2));

      expect(bounds.min.x, equals(1.0));
      expect(bounds.min.y, equals(2.0));
    });

    test(
        'should create bounds with maximum point equal to minimum argument '
        'if maximum argument point is positioned lower', () {
      final bounds = IntegerBounds(const Point(1, 2), const Point(0, 0));

      expect(bounds.max.x, equals(1.0));
      expect(bounds.max.y, equals(2.0));
    });

    test(
        'should create bounds with maximum point equal to maximum argument '
        'if maximum argument point is positioned higher', () {
      final bounds = IntegerBounds(const Point(0, 0), const Point(1, 2));

      expect(bounds.max.x, equals(1.0));
      expect(bounds.max.y, equals(2.0));
    });

    test('should get center of bounds as a point with x position', () {
      expect(
          IntegerBounds(Point(5, randomInt()), Point(4, randomInt())).center.dx,
          equals(4.5));
    });

    test('should get center of bounds as a point with y position', () {
      expect(
          IntegerBounds(Point(randomInt(), 3), Point(randomInt(), 4)).center.dy,
          equals(3.5));
    });

    test(
        'should create bounds with size represented as point with position '
        'x based on distance between top left and bottom right corners', () {
      final size = IntegerBounds(
        Point(1, randomInt()),
        Point(3, randomInt()),
      ).size;

      // avoid float precision problems
      expect(size.x, equals(2));
    });

    test(
        'should create bounds with size represented as point with position '
        'y based on distance between top left and bottom right corners', () {
      final size = IntegerBounds(
        Point(randomInt(), 2),
        Point(randomInt(), 5),
      ).size;

      // avoid float precision problems
      expect(size.y, equals(3));
    });

    group('corners', () {
      test(
          'should create bounds with bottom left corner\'s x position '
          'using minimum point x position', () {
        expect(
            IntegerBounds(Point(2, randomInt()), Point(1, randomInt()))
                .bottomLeft
                .x,
            equals(1));
      });

      test(
          'should create bounds with bottom left corner\'s y position '
          'using maximum point y position', () {
        expect(
            IntegerBounds(Point(randomInt(), 1), Point(randomInt(), 5))
                .bottomLeft
                .y,
            equals(5));
      });

      test(
          'should create bounds with top right corner\'s x position '
          'using maximum point x position', () {
        expect(
            IntegerBounds(Point(1, randomInt()), Point(8, randomInt()))
                .topRight
                .x,
            equals(8));
      });

      test(
          'should create bounds with top right corner\'s y position '
          'using minimum point y position', () {
        expect(
            IntegerBounds(Point(randomInt(), 10), Point(randomInt(), 100))
                .topRight
                .y,
            equals(10));
      });

      test(
          'should create bounds with top left corner\'s x position '
          'using minimum point x position', () {
        expect(
            IntegerBounds(Point(1, randomInt()), Point(2, randomInt()))
                .topLeft
                .x,
            equals(1));
      });

      test(
          'should create bounds with top left corner\'s y position '
          'using minimum point y position', () {
        expect(
            IntegerBounds(Point(randomInt(), 4), Point(randomInt(), 3))
                .topLeft
                .y,
            equals(3));
      });

      test(
          'should create bounds with bottom right corner\'s x position '
          'using maximum point x position', () {
        expect(
            IntegerBounds(Point(5, randomInt()), Point(4, randomInt()))
                .bottomRight
                .x,
            equals(5));
      });

      test(
          'should create bounds with bottom right corner\'s y position '
          'using maximum point y position', () {
        expect(
            IntegerBounds(Point(randomInt(), 101), Point(randomInt(), 102))
                .bottomRight
                .y,
            equals(102));
      });
    });

    test('should be convertable to string', () {
      expect(IntegerBounds(const Point(1, 2), const Point(3, 4)).toString(),
          equals('Bounds(Point(1, 2), Point(3, 4))'));
    });

    group('extend', () {
      test('should create new bounds with updated minimum x position', () {
        final bounds =
            IntegerBounds(Point(-10, randomInt()), Point(11, randomInt()));
        final extendedBounds = bounds.extend(Point(-13, randomInt()));

        expect(extendedBounds.min.x, -13);
      });

      test('should create new bounds with updated minimum y position', () {
        final bounds =
            IntegerBounds(Point(randomInt(), 3), Point(randomInt(), 101));
        final extendedBounds = bounds.extend(Point(randomInt(), 2));

        expect(extendedBounds.min.y, equals(2));
      });

      test('should create new bounds with updated maximum x position', () {
        final bounds =
            IntegerBounds(Point(4, randomInt()), Point(16, randomInt()));
        final extendedBounds = bounds.extend(Point(19, randomInt()));

        expect(extendedBounds.max.x, equals(19));
      });

      test('should create new bounds with updated maximum y position', () {
        final bounds =
            IntegerBounds(Point(randomInt(), 4), Point(randomInt(), 34));
        final extendedBounds = bounds.extend(Point(randomInt(), 38));

        expect(extendedBounds.max.y, equals(38));
      });

      test('should create new bounds and keep existing minimum x position', () {
        final bounds =
            IntegerBounds(Point(-10, randomInt()), Point(11, randomInt()));
        final extendedBounds = bounds.extend(Point(-7, randomInt()));

        expect(extendedBounds.min.x, equals(bounds.min.x));
      });

      test('should create new bounds and keep existing minimum y position', () {
        final bounds =
            IntegerBounds(Point(randomInt(), 3), Point(randomInt(), 13));
        final extendedBounds = bounds.extend(Point(randomInt(), 4));

        expect(extendedBounds.min.y, equals(bounds.min.y));
      });

      test('should create new bounds and keep existing maximum x position', () {
        final bounds =
            IntegerBounds(Point(-15, randomInt()), Point(26, randomInt()));
        final extendedBounds = bounds.extend(Point(26, randomInt()));

        expect(extendedBounds.max.x, equals(bounds.max.x));
      });

      test('should create new bounds and keep existing maximum y position', () {
        final bounds =
            IntegerBounds(Point(randomInt(), 0), Point(randomInt(), 16));
        final extendedBounds = bounds.extend(Point(randomInt(), 15));

        expect(extendedBounds.max.y, equals(bounds.max.y));
      });
    });

    group('contains', () {
      test('should contain given point within the bounds', () {
        expect(
            IntegerBounds(const Point(0, 50), const Point(50, 0))
                .contains(const Point(25, 25)),
            isTrue);
      });

      test('should NOT contain given point within the bounds', () {
        expect(
            IntegerBounds(const Point(0, 50), const Point(50, 0))
                .contains(const Point(51, 51)),
            isFalse);
      });
    });
  });
}
