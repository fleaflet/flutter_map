import 'dart:math' as math;

class CustomPoint<T extends num> extends math.Point<T> {
  const CustomPoint(num x, num y) : super(x, y);

  CustomPoint<T> operator /(num /*T|int*/ factor) {
    return new CustomPoint<T>(x / factor, y / factor);
  }

  CustomPoint<T> ceil() {
    return new CustomPoint(x.ceil(), y.ceil());
  }

  CustomPoint<T> floor() {
    return new CustomPoint<T>(x.floor(), y.floor());
  }

  CustomPoint<T> unscaleBy(CustomPoint<T> point) {
    return new CustomPoint<T>(x / point.x, y / point.y);
  }

  CustomPoint<T> operator +(math.Point<T> other) {
    return new CustomPoint<T>(x + other.x, y + other.y);
  }

  CustomPoint<T> operator -(math.Point<T> other) {
    return new CustomPoint<T>(x - other.x, y - other.y);
  }

  CustomPoint<T> operator *(num /*T|int*/ factor) {
    return new CustomPoint<T>((x * factor), (y * factor));
  }

  CustomPoint scaleBy(CustomPoint point) {
    return new CustomPoint(this.x * point.x, this.y * point.y);
  }

  CustomPoint round() {
    var x = this.x is double ? this.x.round() : this.x;
    var y = this.y is double ? this.y.round() : this.y;
    return new CustomPoint(x, y);
  }

  CustomPoint multiplyBy(num n) {
      return new CustomPoint(this.x * n, this.y * n);
  }

  String toString() => "CustomPoint ($x, $y)";
}
