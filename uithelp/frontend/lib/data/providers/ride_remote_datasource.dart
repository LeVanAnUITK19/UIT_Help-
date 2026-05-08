import '../../core/constants/api_constants.dart';
import '../../core/constants/dio_client.dart';

class RideRemoteDatasource {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> getRides({
    String? cursor,
    String? type,
    String? fromId,
    String? toId,
    String? status,
  }) async {
    final params = <String, dynamic>{};
    if (cursor != null) params['cursor'] = cursor;
    if (type != null) params['type'] = type;
    if (fromId != null) params['fromId'] = fromId;
    if (toId != null) params['toId'] = toId;
    if (status != null) params['status'] = status;

    final res = await _dio.get(Api.getRides, queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRide(Map<String, dynamic> body) async {
    final res = await _dio.post(Api.createRide, data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRideById(String id) async {
    final res = await _dio.get(Api.getRideById(id));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRide(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.put(Api.updateRide(id), data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteRide(String id) async {
    await _dio.delete(Api.deleteRide(id));
  }

  Future<Map<String, dynamic>> requestJoinRide(
      String id, String? message) async {
    final res = await _dio.post(
      Api.requestJoinRide(id),
      data: {'message': message ?? ''},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRideRequests(String id) async {
    final res = await _dio.get(Api.getRideRequests(id));
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> acceptRideRequest(String requestId) async {
    final res = await _dio.patch(Api.acceptRideRequest(requestId));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectRideRequest(String requestId) async {
    final res = await _dio.patch(Api.rejectRideRequest(requestId));
    return res.data as Map<String, dynamic>;
  }

  Future<void> cancelRideRequest(String requestId) async {
    await _dio.delete(Api.cancelRideRequest(requestId));
  }

  Future<void> leaveRide(String id) async {
    await _dio.delete(Api.leaveRide(id));
  }

  Future<List<dynamic>> getMatchedRides(String id) async {
    final res = await _dio.get(Api.getMatchedRides(id));
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMyRides({String? cursor}) async {
    final params = <String, dynamic>{};
    if (cursor != null) params['cursor'] = cursor;
    final res = await _dio.get(Api.getMyRides, queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJoinedRides({String? cursor}) async {
    final params = <String, dynamic>{};
    if (cursor != null) params['cursor'] = cursor;
    final res = await _dio.get(Api.getJoinedRides, queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyRideRequests() async {
    final res = await _dio.get(Api.getMyRideRequests);
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> completeRide(String id) async {
    final res = await _dio.patch(Api.completeRide(id));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelRide(String id) async {
    final res = await _dio.patch(Api.cancelRide(id));
    return res.data as Map<String, dynamic>;
  }
}
