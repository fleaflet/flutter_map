import 'package:flutter_map/src/core/bounds.dart';
import 'package:flutter_map/src/core/point.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/core.dart';

void main() {
  group('Bounds', () {
    test(
        'should create bounds with minimum point equal to minimum argument '
        'if maximum argument point is positioned higher', () {
      final bounds = Bounds(CustomPoint(1.0, 2.0), CustomPoint(3.0, 4.0));

      expect(bounds.min.x, equals(1.0));
      expect(bounds.min.y, equals(2.0));
    });

    test(
        'should create bounds with minimum point equal to maximum argument '
        'if maximum argument point is positioned lower', () {
      final bounds = Bounds(CustomPoint(3.0, 4.0), CustomPoint(1.0, 2.0));

      expect(bounds.min.x, equals(1.0));
      expect(bounds.min.y, equals(2.0));
    });

    test(
        'should create bounds with maximum point equal to minimum argument '
        'if maximum argument point is positioned lower', () {
      final bounds = Bounds(CustomPoint(1.0, 2.0), CustomPoint(0.01, 0.02));

      expect(bounds.max.x, equals(1.0));
      expect(bounds.max.y, equals(2.0));
    });

    test(
        'should create bounds with maximum point equal to maximum argument '
        'if maximum argument point is positioned higher', () {
      final bounds = Bounds(CustomPoint(0.01, 0.02), CustomPoint(1.0, 2.0));

      expect(bounds.max.x, equals(1.0));
      expect(bounds.max.y, equals(2.0));
    });

    test('should get center of bounds as a point with x position', () {
      expect(
          Bounds(CustomPoint(5.5, randomDouble()),
                  CustomPoint(3.3, randomDouble()))
              .center
              .x,
          equals(4.4));
    });

    test('should get center of bounds as a point with y position', () {
      expect(
          Bounds(CustomPoint(randomDouble(), 3.2),
                  CustomPoint(randomDouble(), 6.6))
              .center
              .y,
          equals(4.9));
    });

    test(
        'should create bounds with size represented as point with position'
        'x based on distance between top left and bottom right conrners', () {
      final size = Bounds(
        CustomPoint(1.1, randomDouble()),
        CustomPoint(3.3, randomDouble()),
      ).size;

      // avoid float precision problems
      expect(size.x.toStringAsPrecision(2), equals('2.2'));
    });

    test(
        'should create bounds with size represented as point with position'
        'y based on distance between top left and bottom right conrners', () {
      final size = Bounds(
        CustomPoint(randomDouble(), 2.2),
        CustomPoint(randomDouble(), 5.5),
      ).size;

      // avoid float precision problems
      expect(size.y.toStringAsPrecision(2), equals('3.3'));
    });

    group('corners', () {
      test(
          'should create bounds with bottom left corner\'s x position '
          'using minimum point x position', () {
        expect(
            Bounds(CustomPoint(2.2, randomDouble()),
                    CustomPoint(1.1, randomDouble()))
                .bottomLeft
                .x,
            equals(1.1));
      });

      test(
          'should create bounds with bottom left corner\'s y position '
          'using maximum point y position', () {
        expect(
            Bounds(CustomPoint(randomDouble(), 1.0),
                    CustomPoint(randomDouble(), 5.5))
                .bottomLeft
                .y,
            equals(5.5));
      });

      test(
          'should create bounds with top right corner\'s x position '
          'using maximum point x position', () {
        expect(
            Bounds(CustomPoint(1.0, randomDouble()),
                    CustomPoint(8.8, randomDouble()))
                .topRight
                .x,
            equals(8.8));
      });

      test(
          'should create bounds with top right corner\'s y position '
          'using minimum point y position', () {
        expect(
            Bounds(CustomPoint(randomDouble(), 9.9),
                    CustomPoint(randomDouble(), 100.0))
                .topRight
                .y,
            equals(9.9));
      });

      test(
          'should create bounds with top left corner\'s x position '
          'using minimum point x position', () {
        expect(
            Bounds(CustomPoint(1.1, randomDouble()),
                    CustomPoint(2.2, randomDouble()))
                .topLeft
                .x,
            equals(1.1));
      });

      test(
          'should create bounds with top left corner\'s y position '
          'using minimum point y position', () {
        expect(
            Bounds(CustomPoint(randomDouble(), 4.4),
                    CustomPoint(randomDouble(), 3.3))
                .topLeft
                .y,
            equals(3.3));
      });

      test(
          'should create bounds with bottom right corner\'s x position '
          'using maximum point x position', () {
        expect(
            Bounds(CustomPoint(5.5, randomDouble()),
                    CustomPoint(4.4, randomDouble()))
                .bottomRight
                .x,
            equals(5.5));
      });

      test(
          'should create bounds with bottom right corner\'s y position '
          'using maximum point y position', () {
        expect(
            Bounds(CustomPoint(randomDouble(), 101.3),
                    CustomPoint(randomDouble(), 101.4))
                .bottomRight
                .y,
            equals(101.4));
      });
    });

    test('should be convertable to string', () {
      expect(Bounds(CustomPoint(1.1, 2.2), CustomPoint(3.3, 4.4)).toString(),
          equals('Bounds(CustomPoint (1.1, 2.2), CustomPoint (3.3, 4.4))'));
    });

    group('extend', () {
      test('should create new bounds with updated minimum x position', () {
        final bounds = Bounds(CustomPoint(-10.1, randomDouble()),
            CustomPoint(11.1, randomDouble()));
        final extendedBounds =
            bounds.extend(CustomPoint(-13.3, randomDouble()));

        expect(extendedBounds.min.x, -13.3);
      });

      test('should create new bounds with updated minimum y position', () {
        final bounds = Bounds(CustomPoint(randomDouble(), 3.5),
            CustomPoint(randomDouble(), 101.3));
        final extendedBounds = bounds.extend(CustomPoint(randomDouble(), 2.1));

        expect(extendedBounds.min.y, equals(2.1));
      });

      test('should create new bounds with updated maximum x position', () {
        final bounds = Bounds(CustomPoint(4.5, randomDouble()),
            CustomPoint(16.3, randomDouble()));
        final extendedBounds = bounds.extend(CustomPoint(18.9, randomDouble()));

        expect(extendedBounds.max.x, equals(18.9));
      });

      test('should create new bounds with updated maximum y position', () {
        final bounds = Bounds(CustomPoint(randomDouble(), 3.5),
            CustomPoint(randomDouble(), 34.3));
        final extendedBounds = bounds.extend(CustomPoint(randomDouble(), 38.3));

        expect(extendedBounds.max.y, equals(38.3));
      });

      test('should create new bounds and keep existing minimum x position', () {
        final bounds = Bounds(CustomPoint(-10.1, randomDouble()),
            CustomPoint(11.1, randomDouble()));
        final extendedBounds = bounds.extend(CustomPoint(-7.7, randomDouble()));

        expect(extendedBounds.min.x, equals(bounds.min.x));
      });

      test('should create new bounds and keep existing minimum y position', () {
        final bounds = Bounds(CustomPoint(randomDouble(), 3.3),
            CustomPoint(randomDouble(), 12.7));
        final extendedBounds = bounds.extend(CustomPoint(randomDouble(), 4.4));

        expect(extendedBounds.min.y, equals(bounds.min.y));
      });

      test('should create new bounds and keep existing maximum x position', () {
        final bounds = Bounds(CustomPoint(-15.5, randomDouble()),
            CustomPoint(25.8, randomDouble()));
        final extendedBounds = bounds.extend(CustomPoint(25.7, randomDouble()));

        expect(extendedBounds.max.x, equals(bounds.max.x));
      });

      test('should create new bounds and keep existing maximum y position', () {
        final bounds = Bounds(CustomPoint(randomDouble(), 0.0),
            CustomPoint(randomDouble(), 15.5));
        final extendedBounds = bounds.extend(CustomPoint(randomDouble(), 15.4));

        expect(extendedBounds.max.y, equals(bounds.max.y));
      });
    });

    group('contains', () {
      test(
          'should contain compared bounds if they are completely within '
          'the bounds', () {
        final bounds =
            Bounds(CustomPoint(101.1, 88.1), CustomPoint(133.1, 60.3));

        expect(
            bounds.containsBounds(
                Bounds(CustomPoint(110.1, 77.3), CustomPoint(128.3, 65.5))),
            isTrue);
      });

      test(
          'should NOT contain compared bounds if they are NOT completely '
          'within the bounds', () {
        final bounds =
            Bounds(CustomPoint(101.1, 88.1), CustomPoint(133.1, 60.3));

        expect(
            bounds.containsBounds(
                Bounds(CustomPoint(110.1, 77.3), CustomPoint(133.2, 65.5))),
            isFalse);
      });

      test(
          'should contain compared bounds partially if at least one edge '
          'overlaps within the bounds', () {
        final bounds =
            Bounds(CustomPoint(101.1, 88.1), CustomPoint(133.1, 60.3));

        expect(
            bounds.containsPartialBounds(
                Bounds(CustomPoint(200.22, 60.2), CustomPoint(133.1, 60.3))),
            isTrue);
      });

      test(
          'should NOT contain compared bounds partially if not a single edge '
          'overlaps within the bounds', () {
        final bounds =
            Bounds(CustomPoint(101.1, 88.1), CustomPoint(133.1, 60.3));

        expect(
            bounds.containsPartialBounds(
                Bounds(CustomPoint(200.22, 60.2), CustomPoint(133.2, 60.3))),
            isFalse);
      });

      test('should contain given point within the bounds', () {
        expect(
            Bounds(CustomPoint(0.0, 50.0), CustomPoint(50.0, 0.0))
                .contains(CustomPoint(25.0, 25.0)),
            isTrue);
      });

      test('should NOT contain given point within the bounds', () {
        expect(
            Bounds(CustomPoint(0.0, 50.0), CustomPoint(50.0, 0.0))
                .contains(CustomPoint(50.1, 50.1)),
            isFalse);
      });
    });
  });
}
