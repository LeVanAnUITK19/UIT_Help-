abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Không có kết nối mạng');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Phiên đăng nhập hết hạn');
}

class CacheFailure extends Failure {
  const CacheFailure() : super('Lỗi lưu trữ cục bộ');
}
