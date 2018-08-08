import 'dart:math' as math;

class Point<T extends num> extends math.Point<T> {
  const Point(num x, num y) : super(x, y);

  Point<T> operator /(num /*T|int*/ factor) {
    return new Point<T>(x / factor, y / factor);
  }

  Point<T> ceil() {
    return new Point(x.ceil(), y.ceil());
  }

  Point<T> floor() {
    return new Point<T>(x.floor(), y.floor());
  }

  Point<T> unscaleBy(Point<T> point) {
    return new Point<T>(x / point.x, y / point.y);
  }

  Point<T> operator +(math.Point<T> other) {
    return new Point<T>(x + other.x, y + other.y);
  }

  Point<T> operator -(math.Point<T> other) {
    return new Point<T>(x - other.x, y - other.y);
  }

  Point<T> operator *(num /*T|int*/ factor) {
    return new Point<T>((x * factor), (y * factor));
  }

  Point scaleBy(Point point) {
    return new Point(this.x * point.x, this.y * point.y);
  }

  Point round() {
    var x = this.x is double ? this.x.round() : this.x;
    var y = this.y is double ? this.y.round() : this.y;
    return new Point(x, y);
  }

  Point multiplyBy(num n) {
      return new Point(this.x * n, this.y * n);
  }

  String toString() => "Point ($x, $y)";
}
