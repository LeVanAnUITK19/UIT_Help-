import 'package:dio/dio.dart';
import '../providers/ride_remote_datasource.dart';
import '../models/ride_model.dart';
import '../../core/errors/failures.dart';

typedef RideResult<T> = ({T? data, Failure? failure});

class RideRepository {
  final RideRemoteDatasource _remote;
  RideRepository(this._remote);

  Future<RideResult<({List<RideModel> rides, String? nextCursor})>> getRides({
    String? cursor,
    String? type,
    String? fromId,
    String? toId,
    String? status,
  }) async {
    try {
      final raw = await _remote.getRides(
        cursor: cursor,
        type: type,
        fromId: fromId,
        toId: toId,
        status: status,
      );
      final rides = (raw['rides'] as List)
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        data: (rides: rides, nextCursor: raw['nextCursor'] as String?),
        failure: null
      );
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<RideModel>> createRide(Map<String, dynamic> body) async {
    try {
      final raw = await _remote.createRide(body);
      return (data: RideModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<RideModel>> getRideById(String id) async {
    try {
      final raw = await _remote.getRideById(id);
      return (data: RideModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<RideModel>> updateRide(
      String id, Map<String, dynamic> body) async {
    try {
      final raw = await _remote.updateRide(id, body);
      return (data: RideModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<bool>> deleteRide(String id) async {
    try {
      await _remote.deleteRide(id);
      return (data: true, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<RideRequestModel>> requestJoinRide(
      String id, String? message) async {
    try {
      final raw = await _remote.requestJoinRide(id, message);
      return (data: RideRequestModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<List<RideRequestModel>>> getRideRequests(String id) async {
    try {
      final raw = await _remote.getRideRequests(id);
      final list = raw
          .map((e) => RideRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (data: list, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<bool>> acceptRideRequest(String requestId) async {
    try {
      await _remote.acceptRideRequest(requestId);
      return (data: true, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<bool>> rejectRideRequest(String requestId) async {
    try {
      await _remote.rejectRideRequest(requestId);
      return (data: true, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<bool>> cancelRideRequest(String requestId) async {
    try {
      await _remote.cancelRideRequest(requestId);
      return (data: true, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<bool>> leaveRide(String id) async {
    try {
      await _remote.leaveRide(id);
      return (data: true, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<List<RideModel>>> getMatchedRides(String id) async {
    try {
      final raw = await _remote.getMatchedRides(id);
      final list = raw
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (data: list, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<({List<RideModel> rides, String? nextCursor})>>
      getMyRides({String? cursor}) async {
    try {
      final raw = await _remote.getMyRides(cursor: cursor);
      final rides = (raw['rides'] as List)
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        data: (rides: rides, nextCursor: raw['nextCursor'] as String?),
        failure: null
      );
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<({List<RideModel> rides, String? nextCursor})>>
      getJoinedRides({String? cursor}) async {
    try {
      final raw = await _remote.getJoinedRides(cursor: cursor);
      final rides = (raw['rides'] as List)
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        data: (rides: rides, nextCursor: raw['nextCursor'] as String?),
        failure: null
      );
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<List<RideRequestModel>>> getMyRideRequests() async {
    try {
      final raw = await _remote.getMyRideRequests();
      final list = raw
          .map((e) => RideRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (data: list, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<bool>> completeRide(String id) async {
    try {
      await _remote.completeRide(id);
      return (data: true, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<RideResult<bool>> cancelRide(String id) async {
    try {
      await _remote.cancelRide(id);
      return (data: true, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }
}
