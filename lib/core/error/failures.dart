abstract class Failure {
  final String message;
  const Failure(this.message);
}

class HiveFailure extends Failure {
  const HiveFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}