import 'package:dio/dio.dart';
import '../providers/locket_remote_datasource.dart';
import '../models/locket_model.dart';
import '../../core/errors/failures.dart';

typedef LocketResult<T> = ({T? data, Failure? failure});

class LocketRepository {
  final LocketRemoteDatasource _remote;
  LocketRepository(this._remote);

  Future<LocketResult<({List<LocketModel> lockets, String? nextCursor})>>
      getLockets({String? cursor}) async {
    try {
      final raw = await _remote.getLockets(cursor: cursor);
      final lockets =
          (raw['lockets'] as List).map((e) => LocketModel.fromJson(e)).toList();
      return (
        data: (lockets: lockets, nextCursor: raw['nextCursor'] as String?),
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

  Future<LocketResult<({List<LocketModel> lockets, String? nextCursor})>>
      getMyLockets({String? cursor}) async {
    try {
      final raw = await _remote.getMyLockets(cursor: cursor);
      final lockets =
          (raw['lockets'] as List).map((e) => LocketModel.fromJson(e)).toList();
      return (
        data: (lockets: lockets, nextCursor: raw['nextCursor'] as String?),
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

  Future<LocketResult<LocketModel>> createLocket(FormData formData) async {
    try {
      final raw = await _remote.createLocket(formData);
      return (data: LocketModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<LocketResult<void>> deleteLocket(String id) async {
    try {
      await _remote.deleteLocket(id);
      return (data: null, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<LocketResult<void>> reactLocket(String id, String type) async {
    try {
      await _remote.reactLocket(id, type);
      return (data: null, failure: null);
    } on DioException catch (e) {
      return (
        data: null,
        failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server')
      );
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<LocketResult<List<LocketReactionModel>>> getReactions(String id) async {
    try {
      final raw = await _remote.getLocketReactions(id);
      final list = raw.map((e) => LocketReactionModel.fromJson(e)).toList();
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

  Future<LocketResult<List<LocketCommentModel>>> getComments(String id) async {
    try {
      final raw = await _remote.getLocketComments(id);
      final list = raw.map((e) => LocketCommentModel.fromJson(e)).toList();
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

  Future<LocketResult<void>> addComment(String id, String content) async {
    try {
      await _remote.commentLocket(id, content);
      return (data: null, failure: null);
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
