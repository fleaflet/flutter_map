import 'package:meta/meta.dart';

@immutable
class MoveAndRotateResult {
  final bool moveSuccess;
  final bool rotateSuccess;

  const MoveAndRotateResult(this.moveSuccess, this.rotateSuccess);
}
